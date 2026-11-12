import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { promisify } from "node:util";

// The helper module has no host imports, so node loads the exact runtime file.
const source = await readFile(new URL("../home/herdr-app/mods/dotfiles-outputs/outputs.js", import.meta.url), "utf8");
const outputs = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`);
const sh = promisify(execFile);

const claudeUse = (ts, id, name, input) => JSON.stringify({ parentUuid: "p", isSidechain: false, type: "assistant", timestamp: ts,
  message: { role: "assistant", content: [{ type: "tool_use", id, name, input }] } });
const claudeResult = (ts, id, content, extra = {}) => JSON.stringify({ parentUuid: "p", isSidechain: false, promptId: "q", type: "user", timestamp: ts,
  message: { role: "user", content: [{ type: "tool_result", tool_use_id: id, content, ...extra }] } });
const piCall = (ts, name, args) => JSON.stringify({ type: "message", id: "m", parentId: null, timestamp: ts,
  message: { role: "assistant", content: [{ type: "toolCall", id: "c", name, arguments: args }] } });

test("sessionOf reads the hook labels and infers the agent from the transcript path", () => {
  assert.equal(outputs.sessionOf(null), null);
  assert.equal(outputs.sessionOf({ labels: { "agent.kind": "claude" } }), null);
  assert.deepEqual(outputs.sessionOf({ labels: { "agent.kind": "pi", "agent.transcript": "/h/.pi/agent/sessions/x/a.jsonl", "agent.session": "s1" } }),
    { kind: "pi", transcript: "/h/.pi/agent/sessions/x/a.jsonl", session: "s1" });
  assert.equal(outputs.sessionOf({ labels: { "agent.transcript": "/h/.claude/projects/x/a.jsonl" } }).kind, "claude");
  assert.equal(outputs.sessionOf({ labels: { "agent.transcript": "/h/.pi/agent/sessions/x/a.jsonl", "agent.kind": "other" } }).kind, "pi");
  assert.equal(outputs.sessionOf({ labels: { "agent.transcript": "/h/elsewhere/a.jsonl" } }), null);
});

test("claude rows: one per path with the latest action and a touch count, artifacts from publish results", () => {
  const text = [
    claudeUse("2026-11-04T10:00:00Z", "t1", "Write", { file_path: "/repo/a.md", content: "x" }),
    claudeResult("2026-11-04T10:00:01Z", "t1", "ok"),
    claudeUse("2026-11-04T10:01:00Z", "t2", "Edit", { file_path: "/repo/a.md", old_string: "x", new_string: "y" }),
    claudeUse("2026-11-04T10:02:00Z", "t3", "NotebookEdit", { notebook_path: "/repo/n.ipynb" }),
    claudeUse("2026-11-04T10:03:00Z", "t4", "Artifact", { file_path: "/tmp/page.html", title: "Plan" }),
    claudeResult("2026-11-04T10:03:05Z", "t4", "Published: https://claude.ai/artifact/AbC123 (private)"),
    claudeUse("2026-11-04T10:04:00Z", "t5", "Artifact", { action: "quickstart", intent: "other" }),
    claudeResult("2026-11-04T10:04:01Z", "t5", "see https://claude.ai/artifact/NotThis"),
    claudeUse("2026-11-04T10:05:00Z", "t6", "Artifact", { file_path: "/tmp/page.html" }),
    claudeResult("2026-11-04T10:05:01Z", "t6", [{ type: "text", text: "Error" }], { is_error: true }),
    claudeUse("2026-11-04T10:06:00Z", "t7", "Bash", { command: "echo" }),
    "not json",
    "",
  ].join("\n");
  const rows = outputs.parseOutputs(text, "claude", "/repo");
  assert.deepEqual(rows.map((r) => [r.kind, r.path ?? r.url, r.action, r.count]), [
    ["artifact", "/tmp/page.html", "published", 1],
    ["file", "/repo/n.ipynb", "edited", 1],
    ["file", "/repo/a.md", "edited", 2],
  ]);
  assert.equal(rows[0].url, "https://claude.ai/artifact/AbC123");
  assert.equal(outputs.nameOf(rows[0]), "Plan");
  assert.equal(outputs.placeOf(rows[0]), "claude.ai/artifact/AbC123");
  assert.equal(outputs.nameOf(rows[2]), "a.md");
  assert.equal(outputs.placeOf(rows[2], "/repo"), ".");
  assert.equal(outputs.placeOf(rows[1], "/other"), "/repo");
});

test("pi rows resolve relative paths against the session line, else the given cwd", () => {
  const withSession = [
    JSON.stringify({ type: "session", version: 3, id: "s", cwd: "/work/repo" }),
    piCall("2026-11-04T10:00:00Z", "write", { path: "docs/a.md", content: "x" }),
    piCall("2026-11-04T10:01:00Z", "edit", { path: "/abs/b.md", edits: [] }),
    piCall("2026-11-04T10:02:00Z", "read", { path: "docs/a.md" }),
    JSON.stringify({ type: "message", id: "r", message: { role: "toolResult", toolName: "write", content: [] } }),
  ].join("\n");
  assert.deepEqual(outputs.parseOutputs(withSession, "pi", "/ignored").map((r) => [r.path, r.action]),
    [["/abs/b.md", "edited"], ["/work/repo/docs/a.md", "wrote"]]);
  assert.deepEqual(outputs.parseOutputs(piCall("2026-11-04T10:00:00Z", "write", { path: "a.md" }), "pi", "/cwd/").map((r) => r.path), ["/cwd/a.md"]);
  assert.deepEqual(outputs.parseOutputs(piCall("2026-11-04T10:00:00Z", "write", { path: "a.md" }), "pi", null).map((r) => r.path), ["a.md"]);
  assert.equal(outputs.placeOf({ kind: "file", path: "a.md" }, null), "/");
});

test("the filter keeps exactly the lines the parser reads and drops request blobs and snapshots", async () => {
  const dir = await mkdtemp(join(tmpdir(), "outputs-"));
  const claude = join(dir, "claude.jsonl"), pi = join(dir, "pi.jsonl");
  const keepUse = claudeUse("2026-11-04T10:00:00Z", "t1", "Write", { file_path: "/repo/a.md" });
  const keepArtifact = claudeResult("2026-11-04T10:00:01Z", "t1", "https://claude.ai/artifact/AbC123");
  await writeFile(claude, [
    JSON.stringify({ type: "api-request-blob", sessionId: "s", body: '"name":"Write" https://claude.ai/artifact/Blob' }),
    JSON.stringify({ parentUuid: "p", isSidechain: false, attachment: { type: "prompt_snapshot", systemPrompt: ['"name":"Edit" https://claude.ai/artifact/Snap'] } }),
    keepUse, claudeUse("2026-11-04T10:00:02Z", "t2", "Bash", { command: "ls" }), keepArtifact, "",
  ].join("\n"));
  const r = await sh("sh", ["-c", outputs.filterScript("claude"), "outputs", claude]);
  assert.deepEqual(r.stdout.trim().split("\n"), [keepUse, keepArtifact]);
  const session = JSON.stringify({ type: "session", version: 3, id: "s", cwd: "/w" });
  const keepCall = piCall("2026-11-04T10:00:00Z", "write", { path: "a.md" });
  await writeFile(pi, [session, JSON.stringify({ type: "message", message: { role: "system", content: 'use "name":"write" tools' } }),
    keepCall, piCall("2026-11-04T10:00:01Z", "read", { path: "a.md" }), ""].join("\n"));
  const p = await sh("sh", ["-c", outputs.filterScript("pi"), "outputs", pi]);
  assert.deepEqual(p.stdout.trim().split("\n"), [session, keepCall]);
  await assert.rejects(sh("sh", ["-c", outputs.filterScript("pi"), "outputs", join(dir, "missing.jsonl")]));
});

test("age is compact", () => {
  const now = Date.parse("2026-11-04T12:00:00Z");
  assert.equal(outputs.age(0, now), "");
  assert.equal(outputs.age(now - 5000, now), "5s");
  assert.equal(outputs.age(now - 150000, now), "3m");
  assert.equal(outputs.age(now - 7200000, now), "2h");
  assert.equal(outputs.age(now - 3 * 86400000, now), "3d");
});

// Render the actual panel class with the native builders and host imports replaced.
import vm from "node:vm";
const main = await readFile(new URL("../home/herdr-app/mods/dotfiles-outputs/main.js", import.meta.url), "utf8");

function element() {
  const node = { children: [], events: {} };
  const builder = new Proxy(node, {
    get(target, key) {
      if (key === "id") return (id) => { target.id = id; return builder; };
      if (key === "child") return (child) => { target.children.push(child); return builder; };
      if (key === "children") return (children) => { target.children.push(...children); return builder; };
      if (key === "when") return (condition, fn) => (condition ? fn(builder) : builder);
      if (key.startsWith("on_")) return (...args) => { target.events[key] = args.at(-1); return builder; };
      if (key === "data") return target;
      return () => builder;
    },
  });
  return builder;
}
const texts = (b) => (b && b.data ? b.data.children.flatMap(texts) : typeof b === "string" ? [b] : []);
const byId = (b, id, out = []) => { if (b && b.data) { if (b.data.id === id) out.push(b); b.data.children.forEach((c) => byId(c, id, out)); } return out; };

function panel({ terminal = "t1", labels = null, stdout = "", code = 0, stderr = "", root = "/repo", ignored = [] } = {}) {
  const execs = [], reads = [], editors = [], opened = [];
  const git = (args) => {
    if (args[0] === "rev-parse") return root ? { code: 0, stdout: root + "\n", stderr: "" } : { code: 128, stdout: "", stderr: "fatal: not a git repository" };
    if (args.includes("check-ignore")) { const hits = args.slice(args.indexOf("--") + 1).filter((p) => ignored.includes(p)); return { code: hits.length ? 0 : 1, stdout: hits.map((p) => p + "\0").join(""), stderr: "" }; }
    throw new Error(`unexpected git ${args.join(" ")}`);
  };
  const record = terminal && labels ? { address: terminal, cwd: "/repo", labels } : terminal ? { address: terminal, cwd: "/repo", labels: {} } : null;
  const sandbox = {
    console, View: class {}, div: element, svg: element, v_flex: element, h_flex: element,
    Editor: { new: (state) => element().child(`<editor ${state.value}>`) },
    EditorState: { new: (options) => { editors.push(options); return { value: options.value, release() {} }; } },
    spaces: () => [{ id: "s1", active: true, folder: "/repo", machine: null }],
    panes: () => (terminal ? [{ pane: "p1", terminal, cwd: "/repo" }] : []),
    focused: () => ({ space: "s1", tab: "tb1", pane: terminal ? "p1" : null, terminal, cwd: "/repo" }),
    terminals: () => (record ? [record] : []),
    exec: (...args) => { execs.push(args); return Promise.resolve(args[0] === "git" ? git(args[1]) : args[0] === "xdg-open" ? { code: 0, stdout: "", stderr: "" } : { code, stdout, stderr }); },
    readTextFile: (path, options) => { reads.push([path, options]); return Promise.resolve(path.endsWith("gone") ? null : `content of ${path}`); },
    theme: () => new Proxy({}, { get: (_t, k) => k }), settings: () => ({ font_family: "mono" }), window: () => ({ platform: "linux" }),
    ...outputs,
  };
  vm.createContext(sandbox);
  vm.runInContext(main.replace(/^import .*;$/gm, "").replace("export default class Outputs", "class Outputs") + "\nglobalThis.Mod = Outputs;", sandbox);
  const mod = new sandbox.Mod();
  const spawned = [];
  const cx = { spawn: (fn) => spawned.push(fn(cx)), notify() {}, timer: { every() {} }, stop_propagation() {}, open_url: (url) => opened.push(url) };
  mod.init({}, cx);
  const settle = async () => { while (spawned.length) await spawned.shift(); };
  return { mod, cx, execs, reads, editors, opened, settle, render: () => mod.render(cx), shell: () => execs.filter((e) => e[0] === "sh") };
}

test("render: empty states for no terminal and for a terminal without session labels", async () => {
  const none = panel({ terminal: null });
  await none.settle();
  assert.ok(texts(none.render()).includes("No terminal focused"));
  assert.equal(none.execs.length, 0);
  const plain = panel();
  await plain.settle();
  assert.ok(texts(plain.render()).some((s) => s.startsWith("No agent session recorded")));
  assert.equal(plain.execs.length, 0);
});

test("render: rows from the labelled transcript, file preview on click, artifact opens its url", async () => {
  const labels = { "agent.kind": "claude", "agent.transcript": "/h/.claude/projects/x/s.jsonl", "agent.session": "s" };
  const stdout = [
    claudeUse("2026-11-04T10:00:00Z", "t1", "Write", { file_path: "/repo/docs/a.md", content: "x" }),
    claudeUse("2026-11-04T10:01:00Z", "t2", "Artifact", { file_path: "/tmp/page.html", title: "Plan" }),
    claudeResult("2026-11-04T10:01:05Z", "t2", "Published https://claude.ai/artifact/AbC123"),
  ].join("\n");
  const p = panel({ labels, stdout, ignored: ["/repo/docs/a.md"] });
  await p.settle();
  // Sandbox values have their own prototypes; compare them as serialized data.
  assert.equal(JSON.stringify(p.shell()), JSON.stringify([["sh", ["-c", outputs.filterScript("claude"), "outputs", "/h/.claude/projects/x/s.jsonl"], { on: null }]]));
  const tree = p.render(), seen = texts(tree);
  assert.ok(seen.includes("Claude Code · 2"), seen.join("|"));
  assert.ok(seen.includes("Plan") && seen.includes("claude.ai/artifact/AbC123") && seen.includes("published"));
  assert.ok(seen.includes("a.md") && seen.includes("docs") && seen.includes("wrote"), "the git-ignored file stays");
  assert.ok(!seen.some((s) => s.startsWith("Nothing")));
  byId(tree, "output-/repo/docs/a.md")[0].data.events.on_click({}, p.cx);
  await p.settle();
  assert.equal(JSON.stringify(p.reads), JSON.stringify([["/repo/docs/a.md", { on: null }]]));
  assert.equal(p.editors.at(-1).value, "content of /repo/docs/a.md");
  assert.ok(texts(p.render()).includes("<editor content of /repo/docs/a.md>"));
  byId(p.render(), "outputs-back")[0].data.events.on_click({}, p.cx);
  byId(p.render(), "output-https://claude.ai/artifact/AbC123")[0].data.events.on_click({}, p.cx);
  assert.equal(JSON.stringify(p.opened), JSON.stringify(["https://claude.ai/artifact/AbC123"]));
  assert.equal(p.reads.length, 1);
});

test("render: a failing transcript read shows the error, an empty one says so", async () => {
  const labels = { "agent.kind": "pi", "agent.transcript": "/h/.pi/agent/sessions/x/s.jsonl" };
  const failed = panel({ labels, code: 2, stderr: "grep: /h/.pi/agent/sessions/x/s.jsonl: No such file or directory\n" });
  await failed.settle();
  assert.ok(texts(failed.render()).some((s) => s.includes("No such file or directory")));
  const empty = panel({ labels });
  await empty.settle();
  const seen = texts(empty.render());
  assert.ok(seen.includes("Nothing drawn, published, or written yet") && seen.includes("Pi"));
});


const claudeText = (ts, text) => JSON.stringify({ parentUuid: "p", isSidechain: false, type: "assistant", timestamp: ts,
  message: { role: "assistant", content: [{ type: "text", text }] } });
const piText = (ts, text) => JSON.stringify({ type: "message", id: "m", parentId: null, timestamp: ts, message: { role: "assistant", content: [{ type: "text", text }] } });
const FLOW = "flowchart LR\n  A[Start] --> B{Ok?}\n  B -->|yes| C[Done]";

test("diagrams: fenced blocks in replies and written files, whole diagram files, images, and the mermaid.live link", () => {
  assert.deepEqual(outputs.diagramsIn("intro\n```mermaid\n" + FLOW + "\n```\n```js\nnot one\n```\n``` dot title\ndigraph G { a -> b }\n```\n```mermaid\n   \n```"),
    [{ lang: "mermaid", code: FLOW }, { lang: "graphviz", code: "digraph G { a -> b }" }]);
  assert.deepEqual(outputs.diagramsOfFile("/x/arch.mmd", FLOW + "\n\n"), [{ lang: "mermaid", code: FLOW }]);
  assert.deepEqual(outputs.diagramsOfFile("/x/empty.puml", "  "), []);
  assert.deepEqual(outputs.diagramsOfFile("/x/notes.md", "see\n```plantuml\n@startuml\nA -> B\n@enduml\n```"), [{ lang: "plantuml", code: "@startuml\nA -> B\n@enduml" }]);
  assert.deepEqual(outputs.diagramsOfFile("/x/code.ts", "const x = 1"), []);
  assert.equal(outputs.diagramTitle("%% comment\n\n  sequenceDiagram\n  A->>B: hi"), "sequenceDiagram");
  assert.equal(outputs.diagramTitle(""), "diagram");
  assert.equal(outputs.base64url("héllo ✓"), Buffer.from("héllo ✓").toString("base64url"));
  assert.equal(outputs.base64url(""), "");
  const url = outputs.mermaidUrl("graph TD; A-->B");
  assert.ok(url.startsWith("https://mermaid.live/edit#base64:"));
  const state = JSON.parse(Buffer.from(url.split("#base64:")[1], "base64url").toString());
  assert.deepEqual(state, { code: "graph TD; A-->B", mermaid: '{"theme":"dark"}', updateDiagram: true, rough: false });
  assert.equal(JSON.parse(Buffer.from(outputs.mermaidUrl("x", false).split("#base64:")[1], "base64url").toString()).mermaid, '{"theme":"default"}');
  assert.ok(outputs.IMAGE.test("/x/chart.PNG") && outputs.IMAGE.test("a.svg") && !outputs.IMAGE.test("a.svg.md"));
  assert.ok(outputs.insideOf("/repo/a", "/repo") && outputs.insideOf("/repo", "/repo/") && !outputs.insideOf("/repo2/a", "/repo") && !outputs.insideOf("/x", null));
});

test("diagram rows: one per distinct diagram across replies and files, images are their own kind", () => {
  const rows = outputs.parseOutputs([
    claudeText("2026-11-04T10:00:00Z", "Here:\n```mermaid\n" + FLOW + "\n```"),
    claudeUse("2026-11-04T10:01:00Z", "t1", "Write", { file_path: "/repo/docs/arch.md", content: "# Arch\n```mermaid\n" + FLOW + "\n```\n```d2\na -> b\n```" }),
    claudeUse("2026-11-04T10:02:00Z", "t2", "Write", { file_path: "/tmp/out/chart.png", content: "" }),
    claudeUse("2026-11-04T10:03:00Z", "t3", "Write", { file_path: "/tmp/out/flow.mmd", content: "graph TD\n  X --> Y" }),
  ].join("\n"), "claude");
  assert.deepEqual(rows.map((r) => [r.kind, r.kind === "diagram" ? `${r.lang}:${r.title}` : r.path, r.count, r.action]), [
    ["diagram", "mermaid:graph TD", 1, "drew"], ["file", "/tmp/out/flow.mmd", 1, "wrote"],
    ["image", "/tmp/out/chart.png", 1, "wrote"],
    ["diagram", "mermaid:flowchart LR", 2, "drew"], ["diagram", "d2:a -> b", 1, "drew"], ["file", "/repo/docs/arch.md", 1, "wrote"],
  ]);
  const flow = rows.find((r) => r.title === "flowchart LR");
  assert.equal(flow.path, "/repo/docs/arch.md", "drawn again in a file: that is its place");
  assert.equal(outputs.placeOf(flow, "/repo"), "mermaid · docs/arch.md");
  assert.equal(outputs.placeOf(rows[0], "/repo"), "mermaid · /tmp/out/flow.mmd");
  assert.equal(outputs.placeOf(rows[4], "/repo"), "d2 · docs/arch.md");
  assert.equal(outputs.placeOf({ kind: "diagram", lang: "d2", path: null }, "/repo"), "d2 · in a reply");
  assert.equal(outputs.nameOf(flow), "flowchart LR");
  const pi = outputs.parseOutputs([piText("2026-11-04T10:00:00Z", "```mermaid\n" + FLOW + "\n```"), piCall("2026-11-04T10:01:00Z", "write", { path: "d.puml", content: "@startuml\nA->B\n@enduml" })].join("\n"), "pi", "/repo");
  assert.deepEqual(pi.map((r) => [r.kind, r.kind === "diagram" ? r.lang : r.path]), [["diagram", "plantuml"], ["file", "/repo/d.puml"], ["diagram", "mermaid"]]);
});

test("the filter keeps reply lines with a diagram fence and still drops request blobs", async () => {
  const dir = await mkdtemp(join(tmpdir(), "outputs-"));
  const claude = join(dir, "c.jsonl");
  await writeFile(claude, [
    claudeText("2026-11-04T10:00:00Z", "```mermaid\ngraph TD\n```"),
    claudeText("2026-11-04T10:00:01Z", "plain reply"),
    JSON.stringify({ parentUuid: "p", type: "user", timestamp: "t", message: { role: "user", content: [{ type: "tool_result", tool_use_id: "x", content: "```mermaid\nread from a file\n```" }] } }),
    '{"type":"api-request-blob","message":{"content":[{"type":"text","text":"```mermaid\nblob\n```"}]}}',
  ].join("\n") + "\n");
  const c = await sh("sh", ["-c", outputs.filterScript("claude"), "outputs", claude]);
  const kept = c.stdout.trim().split("\n");
  assert.equal(kept.length, 1, c.stdout);
  assert.ok(kept[0].includes("graph TD"));
  assert.deepEqual(outputs.parseOutputs(c.stdout, "claude").map((r) => r.title), ["graph TD"]);
  const pi = join(dir, "p.jsonl");
  await writeFile(pi, [piText("2026-11-04T10:00:00Z", "```d2\na -> b\n```"), piText("2026-11-04T10:00:01Z", "no diagram"), JSON.stringify({ type: "message", message: { role: "toolResult", content: [{ type: "text", text: "```mermaid\nx\n```" }] } })].join("\n") + "\n");
  const p = await sh("sh", ["-c", outputs.filterScript("pi"), "outputs", pi]);
  assert.equal(p.stdout.trim().split("\n").length, 1);
  assert.deepEqual(outputs.parseOutputs(p.stdout, "pi").map((r) => r.lang), ["d2"]);
});

test("render: files Changes shows are hidden with a count, diagrams preview their source and render in mermaid.live, images open outside", async () => {
  const labels = { "agent.kind": "claude", "agent.transcript": "/h/.claude/projects/x/s.jsonl", "agent.session": "s" };
  const stdout = [
    claudeText("2026-11-04T10:00:00Z", "```mermaid\n" + FLOW + "\n```"),
    claudeUse("2026-11-04T10:01:00Z", "t1", "Write", { file_path: "/repo/src/a.ts", content: "x" }),
    claudeUse("2026-11-04T10:02:00Z", "t2", "Edit", { file_path: "/repo/build/out.js" }),
    claudeUse("2026-11-04T10:03:00Z", "t3", "Write", { file_path: "/tmp/scratch/chart.png", content: "" }),
    claudeUse("2026-11-04T10:04:00Z", "t4", "Write", { file_path: "/tmp/scratch/notes.md", content: "hi" }),
  ].join("\n");
  const p = panel({ labels, stdout, ignored: ["/repo/build/out.js"] });
  await p.settle();
  const gits = p.execs.filter((e) => e[0] === "git").map((e) => e[1]);
  assert.deepEqual(JSON.parse(JSON.stringify(gits)), [["rev-parse", "--show-toplevel"], ["-C", "/repo", "check-ignore", "-z", "--no-index", "--", "/repo/build/out.js", "/repo/src/a.ts"]]);
  let tree = p.render(), seen = texts(tree);
  assert.ok(seen.includes("Claude Code · 4"), seen.join("|"));
  assert.ok(!seen.includes("a.ts"), "a tracked file in the checkout is left to Changes");
  assert.ok(seen.includes("out.js") && seen.includes("chart.png") && seen.includes("notes.md") && seen.includes("flowchart LR") && seen.includes("drew"));
  assert.ok(seen.includes("1 changed file in the checkout: see Changes"));
  byId(tree, "output-/tmp/scratch/chart.png")[0].data.events.on_click({}, p.cx);
  await p.settle();
  assert.ok(p.execs.some((e) => e[0] === "xdg-open" && e[1][0] === "/tmp/scratch/chart.png"), "an image opens outside");
  assert.equal(p.reads.length, 0);
  const diagram = p.mod.rows.find((r) => r.kind === "diagram");
  byId(p.render(), `output-${p.mod.rowId(diagram)}`)[0].data.events.on_click({}, p.cx);
  await p.settle();
  tree = p.render(); seen = texts(tree);
  assert.equal(p.editors.at(-1).value, FLOW);
  assert.ok(seen.includes("mermaid · flowchart LR") && seen.includes("Render"));
  byId(tree, "outputs-render")[0].data.events.on_click({}, p.cx);
  assert.equal(p.opened.length, 1);
  assert.ok(p.opened[0].startsWith("https://mermaid.live/edit#base64:"));
  assert.equal(JSON.parse(Buffer.from(p.opened[0].split("#base64:")[1], "base64url").toString()).code, FLOW);
  // Outside a checkout every file stays.
  const loose = panel({ labels, stdout, root: null });
  await loose.settle();
  assert.ok(texts(loose.render()).includes("a.ts") && loose.mod.hidden === 0);
});
