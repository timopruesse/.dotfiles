import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { diffRows, displayColumns, diffPalette } from "../home/herdr-app/mods/dotfiles-changes/diff.js";

const main = await readFile(new URL("../home/herdr-app/mods/dotfiles-changes/main.js", import.meta.url), "utf8");
const keys = JSON.parse(await readFile(new URL("../home/herdr-app/keys.json", import.meta.url), "utf8"));
const tabsMain = await readFile(new URL("../home/herdr-app/mods/dotfiles-tabs/main.js", import.meta.url), "utf8");
const source = main.replace(/^import .*;$/gm, "").replace("export default class Changes", "class Changes");
const tabsSource = tabsMain.replace(/^import .*;$/gm, "").replace("export default class Tabs", "class Tabs");
const spans = (text, path) => diffRows([`+${text}`], path)[0].spans;
const colored = (text, path) => spans(text, path).filter(s => s.role !== "plain").map(s => [s.role, s.text]);

const dark = { background: "#21252b", foreground: "#abb2bf", ansi1: "#e06c75", ansi2: "#98c379", accent: "#61afef" };
const light = { background: "#fafafa", foreground: "#2f3037", ansi1: "#ee585d", ansi2: "#71b954", accent: "#6698ed" };

test("new hunks reset both line counters and metadata stays separate", () => {
  const rows = diffRows(["@@ -8,3 +12,3 @@ label", " const x = 0;", "-old;", "+new;", "\\ No newline at end of file", " context", "@@ -32 +40 @@", "-", "+"], "a.js");
  assert.deepEqual(rows.map(({ kind, number }) => [kind, number]), [
    ["@", undefined], [" ", 12], ["-", 9], ["+", 13], ["", undefined], [" ", 14], ["@", undefined], ["-", 32], ["+", 40],
  ]);
  assert.equal(rows[4].text, "\\ No newline at end of file");
  assert.equal(rows[4].spans, undefined);
  assert.deepEqual(rows.at(-1).spans, [{ text: "", role: "plain" }]);
});

test("paths select lexers and quoted strings win over comment delimiters", () => {
  assert.deepEqual(colored('const result: string = format("//\\\"x", 12); // comment', "dir/Service.TSX"), [
    ["keyword", "const"], ["type", "string"], ["function", "format"], ["string", '"//\\\"x"'], ["number", "12"], ["comment", "// comment"],
  ]);
  assert.deepEqual(colored("return 'inside # here' # actual comment", "dir/a.py"), [
    ["keyword", "return"], ["string", "'inside # here'"], ["comment", "# actual comment"],
  ]);
  assert.deepEqual(colored("local f = use(1) -- 2", "dir/a.lua"), [
    ["keyword", "local"], ["function", "use"], ["number", "1"], ["comment", "-- 2"],
  ]);
  assert.deepEqual(colored("export item=foo#bar # actual comment", "dir/.zshrc"), [
    ["keyword", "export"], ["comment", "# actual comment"],
  ]);
  assert.deepEqual(colored('"url": "http://localhost"', "config.json"), [["key", '"url"'], ["string", '"http://localhost"']]);
  assert.deepEqual(colored("max-items: 15 # default", "config.yaml"), [["key", "max-items"], ["number", "15"], ["comment", "# default"]]);
  assert.deepEqual(colored("name = 'herdr'", "config.toml"), [["key", "name"], ["string", "'herdr'"]]);
  assert.deepEqual(colored("_const _1 string const", "a.js"), [["keyword", "const"]]);
  assert.deepEqual(spans("return 12 # note  ", "README.md"), [{ text: "return 12 # note  ", role: "plain" }]);
});

test("spans reconstruct each entire display line and dense lines fall back to one span", () => {
  const text = '\t東\tconst café = "🌱";  ';
  const [row] = diffRows([`+${text}`], "a.js");
  assert.equal(row.text, '    東  const café = "🌱";  ');
  assert.equal(row.spans.map(s => s.text).join(""), row.text);
  assert.equal(displayColumns(row.text), 28);
  const dense = 'const x = "y"; '.repeat(150);
  assert.deepEqual(spans(dense, "a.js"), [{ text: dense, role: "plain" }]);
});

function luminance(hex) {
  const linear = hex.slice(1).match(/../g).map(value => parseInt(value, 16) / 255)
    .map(c => c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
  return linear.reduce((sum, value, i) => sum + value * [0.2126, 0.7152, 0.0722][i], 0);
}

test("the diff palette keeps text readable in both appearances", () => {
  for (const theme of [dark, light]) {
    const palette = diffPalette(theme);
    assert.notEqual(palette["+"].bg, palette["-"].bg);
    assert.notEqual(palette["+"].bg, palette[" "].bg);
    for (const { bg, tokens, gutter, marker, hunk } of Object.values(palette)) {
      assert.notEqual(tokens.keyword, tokens.string);
      for (const color of [...Object.values(tokens), gutter, marker, hunk]) {
        const [a, b] = [luminance(bg), luminance(color)].sort((x, y) => y - x);
        assert.ok((a + 0.05) / (b + 0.05) >= 4.5, `${color} on ${bg}`);
      }
    }
  }
});

function element() {
  const node = { children: [] };
  const builder = new Proxy(node, { get(target, key) {
    if (key === "child") return child => { target.children.push(child); return builder; };
    if (key === "children") return children => { target.children.push(...children); return builder; };
    if (key === "when") return (condition, apply) => condition ? apply(builder) : builder;
    if (key === "inspect") return target;
    return value => { target[key] = value ?? true; return builder; };
  } });
  return builder;
}

function viewFixture(overrides = {}) {
  const Changes = vm.runInNewContext(`${source}\nChanges`, {
    View: class {}, div: element, h_flex: element, diffRows, displayColumns, diffPalette, ...overrides,
  });
  return new Changes();
}

test("native row adapter preserves a fixed gutter, explicit marker, and unshrunk inline runs", () => {
  const view = viewFixture();
  const palette = diffPalette(dark);
  view.setLines(["@@ -44 +44 @@ title", "-const old = 1;", "+\tconst next = 2;", " context"], "a.js");
  const frame = view.rows.map(row => view.diffRow(row, palette, 11).inspect);
  assert.equal(frame[0].border_l, 1);
  assert.deepEqual(frame[0].children, ["@@ -44 +44 @@ title"]);
  for (const [i, mark] of [[1, "-"], [2, "+"], [3, ""]]) {
    const [number, marker, code] = frame[i].children.map(e => e.inspect);
    assert.equal(number.children[0], String(view.rows[i].number));
    assert.equal(number.w, view.gutter(11));
    assert.equal(marker.children[0], mark);
    assert.equal(code.whitespace_nowrap, true);
    const runs = code.children.map(span => span.inspect);
    assert.equal(runs.every(span => span.flex_none === true), true);
    assert.equal(runs.map(span => span.children[0]).join(""), view.rows[i].text);
  }
  const keyword = frame[2].children[2].inspect.children.map(node => node.inspect).find(node => node.children[0] === "const");
  assert.equal(keyword.text_color, palette["+"].tokens.keyword);
});

test("tracked previews pass their filename to the lexer and retain shipped limits", async () => {
  const long = "//" + "x".repeat(4010);
  const text = ["header", "@@ -1 +1 @@", "-const x = 1;", `+${long}`, ...Array(1500).fill(" context")].join("\n");
  const view = viewFixture({ exec: async () => ({ code: 0, stdout: text }) });
  Object.assign(view, { root: "/repo", open: "a.js", files: [{ path: "a.js" }], hasHead: true, current: () => true });
  await view.load("a.js", {});
  assert.equal(view.rows.length, 1500);
  assert.equal(view.rows[1].spans[0].role, "keyword");
  assert.ok(view.rows[2].text.endsWith("… (line truncated)"));
  assert.equal(view.rows[2].text.slice(0, -"… (line truncated)".length).length, 3999);
});

async function changesFixture({ status = " M a.js\0", valid = true } = {}) {
  const world = { cwd: "/worktree/src", runs: [], git: [] }, tasks = [];
  const cx = { focus_handle: () => ({}), notify() {}, timer: { every() {} }, spawn(fn) { tasks.push(fn(this)); } };
  const view = viewFixture({
    spaces: () => [{ active: true, folder: world.cwd }],
    panes: () => [{ pane: "p1", cwd: world.cwd, status: "working" }],
    focused: () => ({ pane: "p1" }),
    theme: () => dark, settings: () => ({ font_size: 11 }),
    v_flex: element, v_virtual_list: element, Scrollbar: { vertical: element },
    InputState: { new: () => ({ on() {}, set_value() {} }) }, Input: { new: element },
    watchFolder: () => new Promise(() => {}),
    run: name => { world.runs.push(name); },
    exec: async (name, args, opts) => {
      world.git.push([name, args, opts]);
      if (args.includes("--show-toplevel")) return { code: valid ? 0 : 1, stdout: opts.cwd.replace(/\/src$/, "") + "\n" };
      if (args.includes("--porcelain=v1")) return { code: 0, stdout: status };
      if (args.includes("--verify")) return { code: 0 };
      if (args.includes("diff")) return { code: 0, stdout: "" };
      assert.fail(`Unexpected git call: ${args.join(" ")}`);
    },
  });
  view.init({}, cx);
  await tasks[0];
  const button = () => view.render(cx).inspect.children[0].inspect.children.at(-1).inspect;
  return { world, button, refresh: () => { const i = tasks.length; view.refresh(cx); return tasks[i]; } };
}

const shortcut = keys["layout:dotfiles-main"]["ctrl-shift-d"];

test("the header click sends the same command as the shortcut without making a git call", async () => {
  const p = await changesFixture();
  const button = p.button(), gitCalls = p.world.git.length;
  assert.equal(button.id, "changes-nvim");
  assert.equal(button.children[0], "Edit in Neovim");
  button.on_click();
  assert.deepEqual(p.world.runs, [shortcut]);
  assert.equal(p.world.git.length, gitCalls);
});

test("an old header click cannot act on a different worktree", async () => {
  const p = await changesFixture();
  const oldButton = p.button();
  p.world.cwd = "/other-worktree/src";
  oldButton.on_click();
  await p.refresh();
  oldButton.on_click();
  assert.deepEqual(p.world.runs, []);
  p.button().on_click();
  assert.deepEqual(p.world.runs, [shortcut]);
});

test("the button is disabled for clean folders and non-repositories", async () => {
  for (const opts of [{ status: "" }, { valid: false }]) {
    const p = await changesFixture(opts);
    assert.equal(p.button().on_click, undefined);
  }
});

function tabsFixture({ machine = null, pane = "p1", hasHead = true, valid = true, beforeResult = async () => {} } = {}) {
  const world = { machine, pane, cwd: "/worktree/src", runs: [], git: [] };
  let deliver;
  const ctx = {
    View: class {}, localStorage: { getItem: () => null },
    spaces: () => [{ id: "s1", active: true, machine: world.machine, folder: "/worktree" }],
    panes: () => world.pane ? [{ pane: world.pane, cwd: world.cwd }] : [],
    focused: () => world.pane ? { pane: world.pane, tab: "tb1" } : null,
    nextCommand: () => new Promise(resolve => { deliver = resolve; }),
    notify: n => assert.fail(n.body),
    run: (name, args) => { world.runs.push([name, JSON.parse(JSON.stringify(args))]); },
    exec: async (name, args, opts) => {
      world.git.push([name, Array.from(args), opts.cwd, opts.on]);
      await beforeResult(args.at(-1));
      if (args.includes("--show-toplevel")) return { code: valid ? 0 : 1, stdout: "/worktree\n" };
      if (args.includes("--verify")) return { code: hasHead ? 0 : 1 };
      assert.fail(`Unexpected git call: ${args.join(" ")}`);
    },
  };
  const Tabs = vm.runInNewContext(`${tabsSource}\nTabs`, ctx);
  new Tabs().init({}, { spawn(fn) { fn(this); } });
  return { world, command: async name => { deliver(name); await new Promise(resolve => setImmediate(resolve)); } };
}

const launch = (place, diff = "DiffviewOpen HEAD") => ["terminal.open", { argv: ["nvim", "-c", diff], folder: "/worktree", place }];

test("the always-mounted tabs command resolves remote checkout and native placement without Changes", async () => {
  const [mod, command] = shortcut.split(".");
  assert.equal(mod, "dotfiles-tabs");
  for (const pane of ["p1", null]) {
    const p = tabsFixture({ machine: "remote", pane, hasHead: Boolean(pane) });
    await p.command("unknown");
    assert.deepEqual(p.world.git, []);
    await p.command(command);
    assert.deepEqual(p.world.git, [
      ["git", ["rev-parse", "--show-toplevel"], pane ? "/worktree/src" : "/worktree", "remote"],
      ["git", ["rev-parse", "--verify", "HEAD"], "/worktree", "remote"],
    ]);
    assert.deepEqual(p.world.runs, [pane ? launch("right") : launch("tab", "DiffviewOpen")]);
  }
});

test("the shortcut ignores non-repositories", async () => {
  const p = tabsFixture({ valid: false });
  await p.command("nvim");
  assert.equal(p.world.git.length, 1);
  assert.deepEqual(p.world.runs, []);
});

test("changing pane, cwd, or machine during either git probe cancels the launch", async () => {
  for (const [field, value] of [["pane", "p2"], ["cwd", "/other-worktree/src"], ["machine", "remote"]]) {
    for (const pauseAt of ["--show-toplevel", "HEAD"]) {
      let resume;
      const pause = new Promise(resolve => { resume = resolve; });
      const p = tabsFixture({ beforeResult: async arg => { if (arg === pauseAt) await pause; } });
      await p.command("nvim");
      assert.equal(p.world.git.at(-1)[1].at(-1), pauseAt);
      p.world[field] = value;
      resume();
      await new Promise(resolve => setImmediate(resolve));
      assert.equal(p.world.git.length, pauseAt === "HEAD" ? 2 : 1);
      assert.deepEqual(p.world.runs, []);
    }
  }
});
