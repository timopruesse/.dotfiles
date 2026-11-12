import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

// The helper module has no host imports, so node loads the exact runtime file.
const source = await readFile(new URL("../home/herdr-app/mods/dotfiles-prs/prs.js", import.meta.url), "utf8");
const prs = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`);

const pr = (number, extra = {}) => ({
  number, title: `PR ${number}`, author: { login: "someone" }, isDraft: false, reviewDecision: "",
  reviewRequests: [], headRefName: `branch-${number}`, baseRefName: "main", url: `https://x/${number}`,
  updatedAt: new Date(1700000000000 + number * 1000).toISOString(), statusCheckRollup: [], ...extra,
});

test("checks summarize runs and status contexts; failing names are listed", () => {
  const rollup = [
    { __typename: "CheckRun", name: "lint", status: "COMPLETED", conclusion: "SUCCESS" },
    { __typename: "CheckRun", name: "skip", status: "COMPLETED", conclusion: "SKIPPED" },
    { __typename: "CheckRun", name: "build", status: "IN_PROGRESS", conclusion: null },
    { __typename: "CheckRun", name: "test", status: "COMPLETED", conclusion: "FAILURE" },
    { __typename: "StatusContext", context: "ci/vercel", state: "ERROR" },
    { __typename: "StatusContext", context: "ci/ok", state: "SUCCESS" },
  ];
  const c = prs.summarizeChecks(rollup);
  assert.deepEqual([c.ok, c.failed, c.pending, c.state, c.failing], [3, 2, 1, "failed", ["test", "ci/vercel"]]);
  assert.equal(prs.summarizeChecks([{ __typename: "CheckRun", status: "QUEUED" }]).state, "pending");
  assert.equal(prs.summarizeChecks([]).state, "none");
  assert.equal(prs.summarizeChecks(undefined).state, "none");
});

test("rows flag review requests to the viewer or their teams, and sort the checkout's PR first", () => {
  const teams = new Set(["chewielabs/frontend"]);
  const list = [
    pr(1, { reviewRequests: [{ __typename: "Team", name: "Backend", slug: "chewielabs/backend" }] }),
    pr(2, { reviewRequests: [{ __typename: "User", login: "timo" }] }),
    pr(3, { author: { login: "timo" } }),
    pr(4, { reviewRequests: [{ __typename: "Team", name: "Frontend", slug: "chewielabs/frontend" }], isDraft: true }),
    pr(5),
  ];
  const rows = prs.rowsOf(list, "timo", teams);
  assert.deepEqual(rows.map((r) => [r.number, r.requested, r.mine, r.draft]), [
    [1, false, false, false], [2, true, false, false], [3, false, true, false], [4, true, false, true], [5, false, false, false],
  ]);
  assert.deepEqual(rows[1].requests, ["timo"]);
  assert.deepEqual(rows[0].requests, ["Backend"]);
  assert.deepEqual(prs.sortRows(rows, "branch-1").map((r) => r.number), [1, 4, 2, 3, 5]);
  assert.deepEqual(prs.sortRows(rows, null).map((r) => r.number), [4, 2, 3, 5, 1]);
  assert.deepEqual(rows.map((r) => r.number), [1, 2, 3, 4, 5], "sorting copies");
});

test("detail keeps only the viewer's pending review, orders open threads first, and strips bot markup", () => {
  const data = { data: { viewer: { login: "timo" }, repository: { pullRequest: {
    reviews: { nodes: [
      { id: "R1", databaseId: 11, body: "", author: { login: "other" }, comments: { nodes: [] } },
      { id: "R2", databaseId: 22, body: "**draft** summary", author: { login: "timo" }, comments: { nodes: [
        { path: "a.ts", line: null, originalLine: 7, body: "nit" }, { path: "b.ts", line: 3, body: "rename" } ] } },
    ] },
    reviewThreads: { nodes: [
      { id: "T1", isResolved: true, isOutdated: true, path: "a.ts", line: 4, comments: { totalCount: 3, nodes: [{ author: { login: "bot" }, body: "<!-- x -->\n<details><summary>hidden</summary>big</details>\n\n**Fix this.**" }, { author: { login: "timo" }, body: "done" }] } },
      { id: "T2", isResolved: false, isOutdated: false, path: "b.ts", line: null, originalLine: 9, comments: { totalCount: 1, nodes: [{ author: { login: "rev" }, body: "why?" }] } },
    ] },
    latestReviews: { nodes: [{ author: { login: "rev" }, state: "CHANGES_REQUESTED", submittedAt: "2026-11-03T12:00:00Z" }] },
  } } } };
  const d = prs.detailOf(data);
  assert.equal(d.viewer, "timo");
  assert.deepEqual(d.pending, { id: "R2", databaseId: 22, body: "**draft** summary", comments: [{ id: null, path: "a.ts", line: 7, side: "RIGHT", body: "nit" }, { id: null, path: "b.ts", line: 3, side: "RIGHT", body: "rename" }] });
  assert.deepEqual(d.threads.map((t) => [t.id, t.resolved, t.line, t.author, t.count, t.last]), [["T2", false, 9, "rev", 1, "rev"], ["T1", true, 4, "bot", 3, "timo"]]);
  assert.equal(prs.plain(d.threads[1].body), "Fix this.");
  assert.deepEqual(d.reviews.map((r) => [r.author, r.state, r.at > 0]), [["rev", "CHANGES_REQUESTED", true]]);
  assert.deepEqual(prs.detailOf({ data: { repository: { pullRequest: null } } }), { id: null, headOid: null, pending: null, threads: [], reviews: [], viewer: null });
  assert.equal(prs.plain("x".repeat(300), 20).length, 20);
});

test("review actions submit the pending review through its events endpoint, else gh pr review", () => {
  const pending = { id: "R2", databaseId: 22 };
  assert.deepEqual(prs.reviewArgs("approve", { repo: "o/r", number: 5, pending, body: " lgtm " }),
    ["api", "-X", "POST", "repos/o/r/pulls/5/reviews/22/events", "-f", "event=APPROVE", "-f", "body=lgtm"]);
  assert.deepEqual(prs.reviewArgs("request_changes", { repo: "o/r", number: 5, pending, body: "" }),
    ["api", "-X", "POST", "repos/o/r/pulls/5/reviews/22/events", "-f", "event=REQUEST_CHANGES"]);
  assert.deepEqual(prs.reviewArgs("discard", { repo: "o/r", number: 5, pending }), ["api", "-X", "DELETE", "repos/o/r/pulls/5/reviews/22"]);
  assert.deepEqual(prs.reviewArgs("approve", { repo: "o/r", number: 5, pending: null, body: "" }), ["pr", "review", "5", "--approve"]);
  assert.deepEqual(prs.reviewArgs("comment", { repo: "o/r", number: 5, pending: null, body: "hi" }), ["pr", "review", "5", "--comment", "--body", "hi"]);
  assert.throws(() => prs.reviewArgs("comment", { repo: "o/r", number: 5, pending: null, body: " " }), /needs a message/);
  assert.throws(() => prs.reviewArgs("discard", { repo: "o/r", number: 5, pending: null }), /No pending review/);
  assert.throws(() => prs.reviewArgs("merge", { repo: "o/r", number: 5 }), /Unknown review action/);
});

test("rows carry merge state and merge is guarded to the shown head", () => {
  const rows = prs.rowsOf([pr(1, { headRefOid: "abc123", mergeable: "CONFLICTING", mergeStateStatus: "DIRTY" }), pr(2, { headRefOid: "def456", mergeable: "MERGEABLE", mergeStateStatus: "CLEAN" })], "timo");
  assert.deepEqual(rows.map((r) => [r.headOid, r.conflicts, r.mergeState]), [["abc123", true, "DIRTY"], ["def456", false, "CLEAN"]]);
  assert.deepEqual(prs.MERGE_METHODS, ["squash", "merge", "rebase"]);
  assert.deepEqual(prs.mergeArgs("squash", { number: 2, headOid: "def456" }), ["pr", "merge", "2", "--squash", "--match-head-commit", "def456"]);
  assert.deepEqual(prs.mergeArgs("rebase", { number: 2, headOid: "def456" }).slice(3, 4), ["--rebase"]);
  assert.throws(() => prs.mergeArgs("fast-forward", { number: 2, headOid: "def456" }), /Unknown merge method/);
  assert.throws(() => prs.mergeArgs("merge", { number: 2, headOid: "" }), /No head commit/);
});

test("hiding resolved threads keeps open ones and the selected thread", () => {
  const threads = [{ id: "T1", resolved: false }, { id: "T2", resolved: true }, { id: "T3", resolved: true }];
  assert.equal(prs.visibleThreads(threads, false), threads);
  assert.deepEqual(prs.visibleThreads(threads, true).map((t) => t.id), ["T1"]);
  assert.deepEqual(prs.visibleThreads(threads, true, "T3").map((t) => t.id), ["T1", "T3"]);
  assert.deepEqual(prs.visibleThreads(threads, true, "T1").map((t) => t.id), ["T1"]);
  assert.deepEqual(prs.visibleThreads([], true), []);
});

test("thread actions build resolve, unresolve, and reply mutations", () => {
  assert.deepEqual(prs.threadArgs("resolve", { id: "T1" }).slice(0, 3), ["api", "graphql", "-f"]);
  assert.match(prs.threadArgs("resolve", { id: "T1" })[3], /resolveReviewThread\(input:\{threadId:\$id\}\)/);
  assert.match(prs.threadArgs("unresolve", { id: "T1" })[3], /unresolveReviewThread/);
  assert.deepEqual(prs.threadArgs("resolve", { id: "T1" }).slice(-2), ["-f", "id=T1"]);
  const reply = prs.threadArgs("reply", { id: "T1", body: " fixed in abc " });
  assert.match(reply[3], /addPullRequestReviewThreadReply/);
  assert.deepEqual(reply.slice(-4), ["-f", "id=T1", "-f", "body=fixed in abc"]);
  assert.throws(() => prs.threadArgs("reply", { id: "T1", body: "" }), /needs a message/);
  assert.throws(() => prs.threadArgs("lock", { id: "T1" }), /Unknown thread action/);
});

test("age is short and never negative-looking", () => {
  const now = 1700000000000;
  assert.deepEqual([0, now, now - 5 * 60000, now - 3 * 3600000, now - 2 * 86400000, now - 70 * 86400000].map((t) => prs.age(t, now)),
    ["", "now", "5m", "3h", "2d", "2mo"]);
});

test("rows with an unsent review rank with review requests", () => {
  const rows = prs.rowsOf([pr(1), pr(2), pr(3, { author: { login: "timo" } })], "timo").map((r) => ({ ...r, pending: r.number === 1 }));
  assert.deepEqual(prs.sortRows(rows, null).map((r) => r.number), [1, 3, 2]);
  const pending = prs.pendingOf({ data: { repository: { pullRequests: { nodes: [{ number: 1, reviews: { totalCount: 1 } }, { number: 2, reviews: { totalCount: 0 } }] } } } });
  assert.deepEqual([...pending], [1]);
  assert.equal(prs.pendingOf({}).size, 0);
  assert.match(prs.PENDING_QUERY, /reviews\(states:PENDING,first:1,author:\$viewer\)/);
});

test("detail carries the PR id and head, draft comment ids and sides, and thread sides", () => {
  const data = { data: { viewer: { login: "timo" }, repository: { pullRequest: {
    id: "PR_1", headRefOid: "abc",
    reviews: { nodes: [{ id: "R2", databaseId: 22, body: "", author: { login: "timo" }, comments: { nodes: [{ id: "C1", path: "a.ts", line: 7, body: "nit" }] } }] },
    reviewThreads: { nodes: [{ id: "T1", isResolved: false, path: "a.ts", line: 4, diffSide: "RIGHT", comments: { totalCount: 1, nodes: [{ author: { login: "rev" }, body: "why" }] } }] },
    latestReviews: { nodes: [] },
  } } } };
  const d = prs.detailOf(data);
  assert.deepEqual([d.id, d.headOid], ["PR_1", "abc"]);
  assert.deepEqual(d.pending.comments, [{ id: "C1", path: "a.ts", line: 7, side: "RIGHT", body: "nit" }], "comments carry no side in GraphQL; drafts mark the new side");
  assert.equal(d.threads[0].side, "RIGHT");
  assert.match(prs.DETAIL_QUERY, /id headRefOid/);
  assert.match(prs.DETAIL_QUERY, /comments\(first:100\)\{nodes\{id path line originalLine body\}\}/);
  assert.doesNotMatch(prs.DETAIL_QUERY, /originalLine diffSide body/, "PullRequestReviewComment has no diffSide field");
  const marks = prs.markersOf(d, "a.ts");
  assert.deepEqual([...marks.drafts.keys()], ["RIGHT:7"]);
  assert.deepEqual([...marks.threads.keys()], ["RIGHT:4"]);
  assert.equal(prs.markersOf(d, "b.ts").drafts.size, 0);
  assert.equal(prs.markersOf(null, "a.ts").threads.size, 0);
});

const DIFF = [
  "diff --git a/src/a.ts b/src/a.ts", "index 1..2 100644", "--- a/src/a.ts", "+++ b/src/a.ts",
  "@@ -1,3 +1,4 @@", " keep", "-old\tline", "+new", "+more", " tail",
  "diff --git a/new.md b/new.md", "new file mode 100644", "index 0..3", "--- /dev/null", "+++ b/new.md",
  "@@ -0,0 +1,2 @@", "+# hi", "+",
  "diff --git a/gone.txt b/gone.txt", "deleted file mode 100644", "--- a/gone.txt", "+++ /dev/null", "@@ -1 +0,0 @@", "-bye",
  "diff --git a/img.png b/img.png", "index 1..2 100644", "Binary files a/img.png and b/img.png differ",
  "diff --git a/old.js b/moved.js", "similarity index 90%", "rename from old.js", "rename to moved.js", "index 1..2 100644", "--- a/old.js", "+++ b/moved.js", "@@ -2 +2 @@", "-x", "+y",
].join("\n") + "\n";

test("a PR diff splits per file with status, counts, and hunks from the first @@", () => {
  const files = prs.parseDiff(DIFF);
  assert.deepEqual(files.map((f) => [f.path, f.status, f.binary, f.add, f.del, f.lines.length]), [
    ["src/a.ts", "M", false, 2, 1, 6], ["new.md", "A", false, 2, 0, 3], ["gone.txt", "D", false, 0, 1, 2], ["img.png", "M", true, 0, 0, 0], ["moved.js", "R", false, 1, 1, 3],
  ]);
  assert.equal(files[4].oldPath, "old.js");
  assert.deepEqual(prs.parseDiff(""), []);
  assert.deepEqual(prs.parseDiff("garbage\nwithout header\n"), []);
});

test("diff rows number both sides and name the side GitHub comments on", () => {
  const rows = prs.diffRows(prs.parseDiff(DIFF)[0].lines);
  assert.deepEqual(rows.map((r) => [r.kind, r.side, r.number, r.text]), [
    ["@", undefined, undefined, "@@ -1,3 +1,4 @@"], [" ", "RIGHT", 1, "keep"], ["-", "LEFT", 2, "old line"], ["+", "RIGHT", 2, "new"], ["+", "RIGHT", 3, "more"], [" ", "RIGHT", 4, "tail"],
  ]);
  assert.deepEqual(prs.diffRows(["\\ No newline at end of file"])[0], { kind: "", text: "\\ No newline at end of file" });
  assert.deepEqual(prs.diffRows(undefined), []);
});

test("draft comments start a pending review or join it, and delete by id", () => {
  const add = prs.draftArgs("add", { prId: "PR_1", pending: null, headOid: "abc", path: "a.ts", line: 7, side: "LEFT", body: " nit " });
  assert.deepEqual(add.slice(0, 3), ["api", "graphql", "-f"]);
  assert.match(add[3], /addPullRequestReview\(input:\{pullRequestId:\$pr,commitOID:\$oid,threads:\[\{path:\$path,line:\$line,side:\$side,body:\$body\}\]\}\)/);
  assert.deepEqual(add.slice(4), ["-f", "pr=PR_1", "-f", "path=a.ts", "-F", "line=7", "-f", "side=LEFT", "-f", "body=nit", "-f", "oid=abc"]);
  const noHead = prs.draftArgs("add", { prId: "PR_1", pending: null, headOid: null, path: "a.ts", line: 7, side: "RIGHT", body: "x" });
  assert.doesNotMatch(noHead[3], /commitOID/);
  assert.ok(!noHead.includes("oid=abc"));
  const join = prs.draftArgs("add", { prId: "PR_1", pending: { id: "R2" }, path: "a.ts", line: 3, side: "bogus", body: "rename" });
  assert.match(join[3], /addPullRequestReviewThread\(input:\{pullRequestReviewId:\$review,path:\$path,line:\$line,side:\$side,body:\$body\}\)/);
  assert.deepEqual(join.slice(4), ["-f", "review=R2", "-f", "path=a.ts", "-F", "line=3", "-f", "side=RIGHT", "-f", "body=rename"]);
  const del = prs.draftArgs("delete", { commentId: "C1" });
  assert.match(del[3], /deletePullRequestReviewComment\(input:\{id:\$id\}\)/);
  assert.deepEqual(del.slice(-2), ["-f", "id=C1"]);
  assert.throws(() => prs.draftArgs("add", { prId: "PR_1", path: "a.ts", line: 7, body: " " }), /needs a message/);
  assert.throws(() => prs.draftArgs("add", { prId: "PR_1", path: "", line: 0, body: "x" }), /Pick a diff line/);
  assert.throws(() => prs.draftArgs("add", { prId: null, pending: null, path: "a.ts", line: 1, body: "x" }), /id is not loaded/);
  assert.throws(() => prs.draftArgs("delete", {}), /No draft comment/);
  assert.throws(() => prs.draftArgs("edit", {}), /Unknown draft action/);
});

test("the remote is found by its fetch URL, and nvim walks refs that touch no branch", () => {
  const remotes = "upstream\tgit@github.com:other/repo.git (fetch)\nupstream\tgit@github.com:other/repo.git (push)\nfork\thttps://github.com/Timo/Repo.git (fetch)\nfork\thttps://github.com/Timo/Repo.git (push)\n";
  assert.equal(prs.remoteFor(remotes, "timo/repo"), "fork");
  assert.equal(prs.remoteFor(remotes, "other/repo"), "upstream");
  assert.equal(prs.remoteFor(remotes, "nobody/else"), "origin");
  assert.equal(prs.remoteFor("", "timo/repo"), "origin");
  const refs = prs.reviewRefs("fork", { number: 12, base: "main" });
  assert.deepEqual(refs.fetch, ["fetch", "--no-tags", "--quiet", "fork", "+refs/pull/12/head:refs/herdr/pr/12", "+refs/heads/main:refs/herdr/base/12"]);
  assert.deepEqual(refs.nvim, ["nvim", "-c", "DiffviewOpen refs/herdr/base/12...refs/herdr/pr/12"]);
});

// Render the actual panel class with the native builders and host imports replaced:
// one record per repository, kept across pane, tab and space switches.
import vm from "node:vm";
const main = await readFile(new URL("../home/herdr-app/mods/dotfiles-prs/main.js", import.meta.url), "utf8");

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

const DETAIL = JSON.stringify({ data: { viewer: { login: "timo" }, repository: { pullRequest: { reviews: { nodes: [] }, reviewThreads: { nodes: [] }, latestReviews: { nodes: [] } } } } });
const REPOS = { "/repo-a": { name: "o/a", list: [pr(1), pr(2)] }, "/repo-b": { name: "o/b", list: [pr(7)] } };
const rootOf = (cwd) => Object.keys(REPOS).find((root) => cwd === root || cwd.startsWith(root + "/")) ?? null;

function panel(cwd = "/repo-a") {
  const world = { cwd, pane: "p1", branch: null };
  const execs = [];
  const calls = (...words) => execs.filter(([cmd, args]) => cmd === words[0] && words.slice(1).every((w, i) => args[i] === w)).length;
  const exec = (cmd, args, opts = {}) => {
    execs.push([cmd, args, opts]);
    const root = rootOf(opts.cwd ?? "");
    const ok = (stdout) => Promise.resolve({ code: 0, stdout, stderr: "" });
    if (cmd === "git" && args[0] === "rev-parse") return root ? ok(root + "\n") : Promise.resolve({ code: 128, stdout: "", stderr: "fatal: not a git repository" });
    if (args[0] === "repo") return ok(REPOS[root].name + "\n");
    if (args[0] === "pr" && args[1] === "list") return ok(JSON.stringify(REPOS[root].list));
    if (args[0] === "api" && args[1] === "user") return ok("timo\n");
    if (args[0] === "api" && args[1] === "user/teams") return ok("");
    if (args[0] === "api" && args[1] === "graphql") {
      const query = args[3];
      if (query.includes("pullRequests(states:OPEN")) return ok(world.pendingAnswer ?? JSON.stringify({ data: { repository: { pullRequests: { nodes: [] } } } }));
      if (query.includes("mutation(")) { world.mutations.push(args.slice(3)); return world.mutationAnswer ? world.mutationAnswer() : ok("{}"); }
      return ok(world.detailAnswer ?? DETAIL);
    }
    if (args[0] === "pr" && args[1] === "diff") return world.diffAnswer ? world.diffAnswer() : ok(DIFF);
    if (cmd === "git" && args[0] === "remote") return ok("origin\tgit@github.com:o/a.git (fetch)\norigin\tgit@github.com:o/a.git (push)\n");
    if (cmd === "git" && args[0] === "fetch") return ok("");
    if (cmd === "mkdir") { world.dirs.push(args.at(-1)); return ok(""); }
    throw new Error(`unexpected exec ${cmd} ${args.join(" ")}`);
  };
  world.mutations = []; world.runs = []; world.scrolls = []; world.commands = []; world.dirs = []; world.files = {}; world.watchers = [];
  const inputs = [];
  const sandbox = {
    console, View: class {}, div: element, svg: element, v_flex: element, h_flex: element,
    Textarea: { new: () => element() },
    TextareaState: { new: () => { const s = { v: "", on() {}, set_auto_grow() {}, value: () => s.v, set_value: (v) => { s.v = v; inputs.push(v); } }; return s; } },
    Scrollbar: { vertical: () => element() },
    VirtualListScrollHandle: { new: () => ({ scroll_to_item: (i, how) => world.scrolls.push([i, how]) }) },
    v_virtual_list: (_id, count, _size, _key, render) => element().children(render({ start: 0, end: count })),
    settings: () => ({ font_family: "mono" }),
    run: (name, args) => { world.runs.push([name, args]); return null; },
    nextCommand: () => new Promise((resolve) => { world.commands.push(resolve); }),
    home: () => "/home/t",
    readTextFile: (path) => Promise.resolve(world.files[path] ?? null),
    writeTextFile: (path, text, expected) => { if ((world.files[path] ?? null) !== expected) return Promise.reject(new Error("stale")); world.files[path] = text; return Promise.resolve(null); },
    watchFolder: (dir) => new Promise((resolve) => { world.watchers.push({ dir, resolve }); }),
    spaces: () => [{ id: "s1", active: true, folder: world.cwd, machine: null }],
    panes: () => [{ pane: world.pane, cwd: world.cwd, branch: world.branch }],
    focused: () => ({ space: "s1", tab: "tb1", pane: world.pane, terminal: "t1", cwd: world.cwd }),
    exec, theme: () => new Proxy({}, { get: (_t, k) => k }),
    ...prs,
  };
  vm.createContext(sandbox);
  vm.runInContext(main.replace(/^import .*;$/gm, "").replace("export default class PullRequests", "class PullRequests") + "\nglobalThis.Mod = PullRequests;", sandbox);
  const mod = new sandbox.Mod();
  const spawned = [];
  // The command loop (the spawn that asks nextCommand at once) never ends; settle skips it.
  const cx = { spawn: (fn) => { const waiting = world.commands.length, p = fn(cx); if (world.commands.length === waiting) spawned.push(p); }, notify() {}, timer: { every() {} }, sleep: (ms) => new Promise((r) => setTimeout(r, ms)), stop_propagation() {}, focus_handle: () => ({ focus() {} }) };
  mod.init({}, cx);
  const settle = async () => { while (spawned.length) await spawned.shift(); };
  const shown = () => texts(mod.render(cx));
  const go = (cwd, pane) => { world.cwd = cwd; world.pane = pane ?? world.pane; return shown(); };
  return { mod, cx, calls, inputs, settle, shown, go, world };
}

test("panel: another pane in the same checkout keeps the rows and the picked PR without listing again", async () => {
  const p = panel("/repo-a");
  await p.settle();
  let seen = p.shown();
  assert.ok(seen.includes("PR 1") && seen.includes("PR 2"));
  assert.equal(p.mod.state.open, 2, "newest open PR is picked first");
  p.mod.pick(1, p.cx);
  await p.settle();
  assert.equal(p.mod.state.open, 1);
  assert.equal(p.calls("gh", "pr", "list"), 1);
  seen = p.go("/repo-a/src", "p2");
  assert.ok(seen.includes("PR 1") && !seen.includes("Loading pull requests…"), "rows stay while the new folder resolves");
  await p.settle();
  seen = p.shown();
  assert.ok(seen.includes("PR 1") && seen.includes("PR 2"));
  assert.equal(p.mod.state.open, 1, "the picked PR survives the switch");
  assert.equal(p.calls("gh", "pr", "list"), 1, "same repository, no second listing");
  assert.equal(p.calls("gh", "repo"), 1, "a known checkout root is not looked up again");
  assert.equal(p.calls("git", "rev-parse"), 2);
});

test("panel: another repository gets its own record and the first comes back as it was, at once", async () => {
  const p = panel("/repo-a");
  await p.settle();
  p.mod.pick(1, p.cx);
  await p.settle();
  p.mod.state.message = "draft for a";
  let seen = p.go("/repo-b", "p3");
  assert.ok(seen.includes("PR 1") && !seen.includes("Loading pull requests…"), "the old record shows until the new one is known");
  await p.settle();
  seen = p.shown();
  assert.ok(seen.includes("PR 7") && !seen.includes("PR 1"));
  assert.equal(p.mod.state.repo, "o/b");
  assert.equal(p.mod.state.open, 7);
  assert.equal(p.inputs.at(-1), "", "the message bar follows the record");
  assert.equal(p.calls("gh", "pr", "list"), 2);
  seen = p.go("/repo-a", "p1");
  assert.ok(seen.includes("PR 1") && seen.includes("PR 2") && !seen.includes("PR 7"), "restored synchronously");
  assert.equal(p.mod.state.open, 1);
  assert.equal(p.mod.state.message, "draft for a");
  assert.equal(p.inputs.at(-1), "draft for a");
  assert.equal(p.calls("gh", "pr", "list"), 2, "a fresh record is not listed again");
  // A record shown again after a while refreshes behind its rows instead of clearing them.
  p.go("/repo-b", "p3");
  await p.settle();
  p.mod.records.get("|o/a").fetched = 1;
  seen = p.go("/repo-a", "p1");
  assert.ok(seen.includes("PR 1") && !seen.includes("Loading pull requests…"));
  await p.settle();
  assert.equal(p.calls("gh", "pr", "list"), 3);
  assert.equal(p.mod.state.open, 1);
});

test("panel: a folder outside git shows the error, keeps nothing, and asks again on refresh", async () => {
  const p = panel("/plain");
  await p.settle();
  assert.ok(p.shown().includes("Not a git repository"));
  assert.equal(p.mod.state, null);
  assert.equal(p.mod.places.size, 0);
  p.mod.refresh(p.cx);
  await p.settle();
  assert.equal(p.calls("git", "rev-parse"), 2);
  const seen = p.go("/repo-a", "p1");
  assert.ok(seen.includes("Loading pull requests…"), "a repository never listed shows the loader");
  await p.settle();
  assert.ok(p.shown().includes("PR 1"));
});

const PR_DETAIL = (pending) => JSON.stringify({ data: { viewer: { login: "timo" }, repository: { pullRequest: {
  id: "PR_1", headRefOid: "abc",
  reviews: { nodes: pending ? [{ id: "R2", databaseId: 22, body: "", author: { login: "timo" }, comments: { nodes: [{ id: "C1", path: "src/a.ts", line: 2, body: "nit here" }] } }] : [] },
  reviewThreads: { nodes: [{ id: "T1", isResolved: false, path: "src/a.ts", line: 4, diffSide: "RIGHT", comments: { totalCount: 1, nodes: [{ author: { login: "rev" }, body: "why?" }] } }] },
  latestReviews: { nodes: [] },
} } } });

test("panel: Files loads the diff once per head, lists the files, and shows the picked file's lines", async () => {
  const p = panel("/repo-a");
  await p.settle();
  assert.ok(!p.shown().includes("src/a.ts"), "the review view has no diff");
  p.mod.view("files", p.cx);
  assert.ok(p.shown().includes("Loading diff…"));
  await p.settle();
  let seen = p.shown();
  assert.equal(p.calls("gh", "pr", "diff"), 1);
  assert.equal(p.mod.state.file, "src/a.ts", "the first file is picked");
  assert.ok(seen.includes("a.ts") && seen.includes("new.md") && seen.includes("gone.txt") && seen.includes("moved.js"));
  assert.ok(seen.includes("old line") && seen.includes("new") && seen.includes("Click a line to comment on it"));
  assert.ok(seen.includes("Files · 5"));
  p.mod.view("review", p.cx);
  p.mod.view("files", p.cx);
  await p.settle();
  assert.equal(p.calls("gh", "pr", "diff"), 1, "switching views keeps the diff");
  // New commits on the PR drop the diff; the next refresh lists them and Files fetches again.
  REPOS["/repo-a"].list = [pr(1), pr(2, { headRefOid: "def" })];
  p.mod.state.fetched = 0;
  p.mod.refresh(p.cx, true);
  await p.settle();
  assert.equal(p.mod.state.diff, null);
  p.mod.loadDiff(p.mod.state, p.cx);
  await p.settle();
  assert.equal(p.calls("gh", "pr", "diff"), 2);
  REPOS["/repo-a"].list = [pr(1), pr(2)];
  // A failing diff shows the reason and keeps the file list empty.
  p.world.diffAnswer = () => Promise.resolve({ code: 1, stdout: "", stderr: "diff exceeded the maximum number of lines" });
  p.mod.pick(1, p.cx);
  p.mod.view("files", p.cx);
  await p.settle();
  assert.ok(p.shown().some((x) => x.includes("Cannot load the diff: diff exceeded")));
});

test("panel: a clicked line takes a draft comment into a new pending review, then into the existing one, and deletes it", async () => {
  const p = panel("/repo-a");
  p.world.detailAnswer = PR_DETAIL(false);
  await p.settle();
  p.mod.view("files", p.cx);
  await p.settle();
  const s = p.mod.state;
  assert.ok(p.shown().includes("1"), "the thread on line 4 is marked");
  const rows = s.diff[0].rows;
  p.mod.pickLine(rows[3], p.cx); // "+new", RIGHT 2
  assert.deepEqual([s.line.path, s.line.number, s.line.side], ["src/a.ts", 2, "RIGHT"]);
  assert.ok(p.shown().includes("src/a.ts:2") && p.shown().includes("Add to review"));
  p.mod.pickLine(rows[0], p.cx);
  assert.equal(s.line.number, 2, "hunk headers are not lines");
  s.message = "";
  p.mod.act("add", p.cx);
  assert.match(s.note, /needs a message/);
  assert.equal(p.world.mutations.length, 0);
  s.message = "nit here";
  p.world.detailAnswer = PR_DETAIL(true);
  p.mod.act("add", p.cx);
  await p.settle();
  assert.equal(p.world.mutations.length, 1);
  assert.match(p.world.mutations[0][0], /addPullRequestReview\(input:\{pullRequestId:\$pr,commitOID:\$oid/);
  assert.deepEqual(p.world.mutations[0].slice(1), ["-f", "pr=PR_1", "-f", "path=src/a.ts", "-F", "line=2", "-f", "side=RIGHT", "-f", "body=nit here", "-f", "oid=abc"]);
  assert.equal(s.message, "", "the box is cleared");
  assert.ok(s.detail.pending, "the detail is reloaded with the new pending review");
  assert.ok(s.pendingNumbers.has(2));
  let seen = p.shown();
  assert.ok(seen.includes("draft") && seen.includes("Delete draft") && seen.includes("Add another") && seen.includes("unsent review"));
  assert.ok(seen.includes("Review · 1 draft"));
  s.message = "and this";
  p.mod.act("add", p.cx);
  await p.settle();
  assert.match(p.world.mutations[1][0], /addPullRequestReviewThread/);
  assert.ok(p.world.mutations[1].includes("review=R2"));
  p.mod.act("delete", p.cx);
  await p.settle();
  assert.match(p.world.mutations[2][0], /deletePullRequestReviewComment/);
  assert.ok(p.world.mutations[2].includes("id=C1"));
  // Picking another line, or Cancel, leaves the line; the bar offers the review again.
  p.mod.pickLine(rows[3], p.cx);
  assert.equal(s.line, null, "clicking the picked line again unpicks it");
  assert.ok(p.shown().includes("Approve"));
});

test("panel: a thread's Show diff and a draft's click reveal the line in Files and scroll to it", async () => {
  const p = panel("/repo-a");
  p.world.detailAnswer = PR_DETAIL(true);
  await p.settle();
  const s = p.mod.state;
  assert.ok(p.shown().includes("Review · 1 draft"));
  p.mod.reveal("src/a.ts", 4, "RIGHT", p.cx);
  assert.equal(s.view, "files");
  assert.equal(s.line, null, "no diff yet: nothing to pick");
  await p.settle();
  p.mod.reveal("src/a.ts", 4, "RIGHT", p.cx);
  assert.deepEqual([s.file, s.line.number, s.line.kind], ["src/a.ts", 4, " "]);
  assert.deepEqual(p.world.scrolls.at(-1), [5, "center"]);
  assert.ok(p.shown().includes("open thread"));
  p.mod.reveal("src/a.ts", 2, "RIGHT", p.cx);
  assert.ok(p.shown().includes("nit here"), "the draft on the line is shown");
  p.mod.reveal("missing.ts", 1, "RIGHT", p.cx);
  assert.equal(s.line, null);
  assert.equal(s.file, "missing.ts");
});

test("panel: nvim fetches the PR's refs into refs/herdr and opens diffview beside the focused pane", async () => {
  const p = panel("/repo-a");
  await p.settle();
  p.mod.nvim(p.cx);
  assert.ok(p.mod.state.busy);
  await p.settle();
  assert.equal(p.calls("git", "fetch"), 1);
  assert.deepEqual(JSON.parse(JSON.stringify(p.world.runs)), [["terminal.open", { argv: ["nvim", "-c", "DiffviewOpen refs/herdr/base/2...refs/herdr/pr/2"], folder: "/repo-a", place: "right" }]]);
  assert.match(p.mod.state.note, /^nvim: base\/2…pr\/2$/);
  assert.ok(!p.mod.state.busy);
});

test("panel: the header counts unsent reviews from one list query", async () => {
  const p = panel("/repo-a");
  p.world.pendingAnswer = JSON.stringify({ data: { repository: { pullRequests: { nodes: [{ number: 1, reviews: { totalCount: 1 } }] } } } });
  await p.settle();
  const seen = p.shown();
  assert.ok(seen.includes("1 unsent") && seen.includes("unsent review"));
  assert.deepEqual(p.mod.state.rows.map((r) => r.number), [1, 2], "the PR with the unsent review sorts first");
});

test("edits change a draft's text or the review summary", () => {
  const edit = prs.editArgs("draft", { commentId: "C1", body: " better " });
  assert.match(edit[3], /updatePullRequestReviewComment\(input:\{pullRequestReviewCommentId:\$id,body:\$body\}\)/);
  assert.deepEqual(edit.slice(-4), ["-f", "id=C1", "-f", "body=better"]);
  assert.throws(() => prs.editArgs("draft", { commentId: "C1", body: " " }), /delete it instead/);
  assert.throws(() => prs.editArgs("draft", { body: "x" }), /No draft comment/);
  const summary = prs.editArgs("summary", { pending: { id: "R2" }, body: "LGTM" });
  assert.match(summary[3], /updatePullRequestReview\(input:\{pullRequestReviewId:\$id,body:\$body\}\)/);
  assert.deepEqual(summary.slice(-4), ["-f", "id=R2", "-f", "body=LGTM"]);
  assert.deepEqual(prs.editArgs("summary", { pending: { id: "R2" }, body: "" }).slice(-2), ["-f", "body="], "a summary may be emptied");
  assert.throws(() => prs.editArgs("summary", { body: "x" }), /No pending review/);
  assert.throws(() => prs.editArgs("reply", {}), /Unknown edit/);
});

test("a snippet is the diff around a commented line, marking the line", () => {
  const diff = prs.parseDiff(DIFF);
  for (const f of diff) f.rows = prs.diffRows(f.lines);
  const rows = prs.snippetOf(diff, "src/a.ts", 2, "RIGHT");
  assert.deepEqual(rows.map((r) => [r.kind, r.number ?? null, r.here]), [["@", null, false], [" ", 1, false], ["-", 2, false], ["+", 2, true], ["+", 3, false], [" ", 4, false]]);
  assert.deepEqual(prs.snippetOf(diff, "src/a.ts", 2, "LEFT", 1, 0).map((r) => [r.kind, r.here]), [[" ", false], ["-", true]]);
  assert.deepEqual(prs.snippetOf(diff, "src/a.ts", 9, "RIGHT"), [], "a line outside the diff has no snippet");
  assert.deepEqual(prs.snippetOf(null, "src/a.ts", 2), []);
});

test("the review file round-trips the summary and drafts and reports what changed", () => {
  const diff = prs.parseDiff(DIFF);
  for (const f of diff) f.rows = prs.diffRows(f.lines);
  const pending = { id: "R2", body: "Looks ok", comments: [{ id: "C1", path: "src/a.ts", line: 2, side: "RIGHT", body: "nit here" }, { id: "C2", path: "new.md", line: 9, side: "RIGHT", body: "typo" }] };
  const text = prs.reviewFile(pending, { repo: "o/a", number: 2, title: "PR 2", diff });
  assert.match(text, /^<!-- Pending review on o\/a#2: PR 2/);
  assert.match(text, /## Summary\n\nLooks ok\n/);
  assert.match(text, /## src\/a\.ts:2 <!-- draft C1 -->\n\n```diff\n@@ -1,3 \+1,4 @@\n {5}1 │ keep\n- {4}2 │ old line\n\+ {4}2 │ new {3}◀\n/);
  assert.match(text, /## new\.md:9 <!-- draft C2 -->\n\ntypo\n/, "a line outside the diff gets no fence");
  const back = prs.parseReviewFile(text);
  assert.equal(back.summary, "Looks ok");
  assert.deepEqual([...back.drafts], [["C1", "nit here"], ["C2", "typo"]]);
  assert.deepEqual(prs.reviewEdits(pending, back), [], "saving the file unchanged changes nothing");
  const changed = prs.parseReviewFile(text.replace("Looks ok", "LGTM\n\nwith a second line").replace("\nnit here\n", "\n\n").replace("typo", "a typo"));
  assert.deepEqual(prs.reviewEdits(pending, changed), [
    { kind: "summary", body: "LGTM\n\nwith a second line" },
    { kind: "delete", id: "C1", path: "src/a.ts", line: 2 },
    { kind: "draft", id: "C2", path: "new.md", line: 9, body: "a typo" },
  ]);
  const partial = prs.parseReviewFile("## new.md:9 <!-- draft C2 -->\n\nonly this\n");
  assert.equal(partial.summary, null);
  assert.deepEqual(prs.reviewEdits(pending, partial), [{ kind: "draft", id: "C2", path: "new.md", line: 9, body: "only this" }], "a missing section is left alone");
  assert.deepEqual(prs.reviewEdits(null, partial), []);
  assert.deepEqual(prs.parseReviewFile("## src/a.ts:2 <!-- draft C1 -->\n```diff\n+ x\n```\n").drafts.get("C1"), "", "a fence alone is an emptied draft");
});

const DRAFTS_DETAIL = JSON.stringify({ data: { viewer: { login: "timo" }, repository: { pullRequest: {
  id: "PR_1", headRefOid: "abc", reviewThreads: { nodes: [] }, latestReviews: { nodes: [] },
  reviews: { nodes: [{ id: "R2", databaseId: 22, body: "Looks ok", author: { login: "timo" }, comments: { nodes: [
    { id: "C1", path: "src/a.ts", line: 2, body: "nit here" }, { id: "C2", path: "new.md", line: 1, body: "typo" },
  ] } }] },
} } } });

test("panel: a draft or the summary is changed in the message box and saved, keeping the unsent text", async () => {
  const p = panel("/repo-a");
  p.world.detailAnswer = DRAFTS_DETAIL;
  await p.settle();
  const s = p.mod.state;
  s.message = "half-written reply";
  find(p.mod.render(p.cx), "draft-0").data.events.on_click(null, p.cx);
  assert.deepEqual([s.editing.kind, s.editing.id, s.editing.path, s.editing.line], ["draft", "C1", "src/a.ts", 2]);
  assert.deepEqual([s.message, p.inputs.at(-1)], ["nit here", "nit here"], "the draft's text is in the box");
  await p.settle();
  let shown = p.shown();
  assert.ok(shown.includes("Changing the draft on src/a.ts:2") && shown.includes("Save") && shown.includes("Delete draft"));
  assert.ok(shown.includes("+new") && shown.includes("-old line"), "the diff around the line is shown");
  s.message = "";
  p.mod.act("edit", p.cx);
  assert.match(s.note, /delete it instead/);
  s.message = "nit, reworded";
  p.mod.act("edit", p.cx);
  await p.settle();
  assert.match(p.world.mutations.at(-1)[0], /updatePullRequestReviewComment/);
  assert.deepEqual(p.world.mutations.at(-1).slice(-4), ["-f", "id=C1", "-f", "body=nit, reworded"]);
  assert.equal(s.editing, null);
  assert.deepEqual([s.message, p.inputs.at(-1)], ["half-written reply", "half-written reply"], "the unsent text comes back");
  assert.match(s.note, /updated/);
  find(p.mod.render(p.cx), "pending-summary").data.events.on_click(null, p.cx);
  assert.deepEqual([s.editing.kind, s.message], ["summary", "Looks ok"]);
  assert.ok(p.shown().includes("Changing the review summary"));
  find(p.mod.render(p.cx), "edit-cancel").data.events.on_click(null, p.cx);
  assert.deepEqual([s.editing, s.message], [null, "half-written reply"]);
  find(p.mod.render(p.cx), "pending-summary").data.events.on_click(null, p.cx);
  s.message = "";
  p.mod.act("edit", p.cx);
  await p.settle();
  assert.match(p.world.mutations.at(-1)[0], /updatePullRequestReview\(/);
  assert.deepEqual(p.world.mutations.at(-1).slice(-4), ["-f", "id=R2", "-f", "body="], "the summary may be emptied");
  // Delete while changing a draft removes that draft, not the picked line's.
  find(p.mod.render(p.cx), "draft-1").data.events.on_click(null, p.cx);
  p.mod.act("delete", p.cx);
  await p.settle();
  assert.match(p.world.mutations.at(-1)[0], /deletePullRequestReviewComment/);
  assert.ok(p.world.mutations.at(-1).includes("id=C2"));
  assert.equal(s.editing, null);
  // From Files, Edit draft on a line with a draft enters the same mode.
  p.mod.view("files", p.cx);
  await p.settle();
  p.mod.pickLine(s.diff[0].rows[3], p.cx);
  assert.ok(p.shown().includes("Edit draft"));
  find(p.mod.render(p.cx), "line-edit").data.events.on_click(null, p.cx);
  assert.deepEqual([s.editing.id, s.message], ["C1", "nit here"]);
});

test("panel: Edit in nvim writes the review as Markdown with diff context, opens nvim, and applies each save", async () => {
  const p = panel("/repo-a");
  p.world.detailAnswer = DRAFTS_DETAIL;
  await p.settle();
  const s = p.mod.state;
  s.message = "keep me";
  find(p.mod.render(p.cx), "pending-nvim").data.events.on_click(null, p.cx);
  await new Promise((r) => setTimeout(r, 10)); // settle would wait for the watch loop
  const path = "/home/t/.cache/herdr-app/reviews/o-a-2.md";
  assert.deepEqual(p.world.dirs, ["/home/t/.cache/herdr-app/reviews"]);
  const text = p.world.files[path];
  assert.ok(text, "the review file is written");
  assert.match(text, /## src\/a\.ts:2 <!-- draft C1 -->\n\n```diff\n/, "the diff was fetched for context");
  assert.deepEqual(JSON.parse(JSON.stringify(p.world.runs.at(-1))), ["terminal.open", { argv: ["nvim", path], folder: "/repo-a", place: "right" }]);
  assert.ok(s.nvimEdit && p.shown().includes("nvim · watching"));
  assert.match(s.note, /~\/\.cache\/herdr-app\/reviews\/o-a-2\.md/);
  assert.equal(s.message, "keep me");
  assert.equal(p.world.watchers.length, 1, "the folder is watched");
  // A save with nothing changed applies nothing.
  const save = async (newText) => { p.world.files[path] = newText; const w = p.world.watchers.shift(); w.resolve([path]); await new Promise((r) => setTimeout(r, 250)); };
  await save(text);
  assert.equal(p.world.mutations.length, 0);
  assert.equal(p.world.watchers.length, 1, "still watching");
  await save(text.replace("Looks ok", "LGTM").replace("\nnit here\n", "\n\n").replace("typo", "a typo"));
  assert.deepEqual(p.world.mutations.map((m) => /\{(\w+)\(input/.exec(m[0])[1]), ["updatePullRequestReview", "deletePullRequestReviewComment", "updatePullRequestReviewComment"]);
  assert.ok(p.world.mutations[2].includes("body=a typo"));
  assert.equal(s.note, "nvim: summary, 1 draft updated, 1 deleted");
  assert.equal(s.message, "keep me", "the box is untouched");
  assert.equal(p.calls("gh", "api", "graphql"), 1 + 1 + 3 + 1, "detail, pending list, three edits, reload");
  // Unpicking the PR ends the watch on its next event.
  p.mod.pick(2, p.cx);
  const w = p.world.watchers.shift(); w.resolve([path]);
  await p.settle(); // the watch loop ends, so every spawned task is done
  assert.equal(s.nvimEdit, null);
  assert.equal(p.world.watchers.length, 0, "the watch is over");
});

const THREADS_DETAIL = JSON.stringify({ data: { viewer: { login: "timo" }, repository: { pullRequest: {
  id: "PR_1", headRefOid: "abc", reviews: { nodes: [] }, latestReviews: { nodes: [] },
  reviewThreads: { nodes: [
    { id: "T1", isResolved: false, path: "src/a.ts", line: 4, comments: { totalCount: 1, nodes: [{ author: { login: "rev" }, body: "why?" }] } },
    { id: "T2", isResolved: true, path: "src/a.ts", line: 8, comments: { totalCount: 2, nodes: [{ author: { login: "rev" }, body: "fixed nit" }] } },
    { id: "T3", isResolved: true, path: "src/b.ts", line: 1, comments: { totalCount: 1, nodes: [{ author: { login: "rev" }, body: "stale" }] } },
  ] },
} } } });
const find = (b, id) => (b && b.data ? (b.data.id === id ? b : b.data.children.map((c) => find(c, id)).find(Boolean)) : undefined);

test("panel: Hide resolved lists only open threads, keeps the selected one, and toggles by command", async () => {
  const p = panel("/repo-a");
  p.world.detailAnswer = THREADS_DETAIL;
  await p.settle();
  const s = p.mod.state;
  let shown = p.shown();
  assert.ok(shown.includes("1 open · 2 resolved") && shown.includes("Hide resolved"));
  assert.ok(shown.includes("rev: fixed nit") && shown.includes("rev: stale"), "resolved threads are listed by default");
  find(p.mod.render(p.cx), "threads-resolved").data.events.on_click(null, p.cx);
  assert.equal(s.hideResolved, true);
  shown = p.shown();
  assert.ok(shown.includes("rev: why?") && shown.includes("Show resolved"));
  assert.ok(!shown.includes("rev: fixed nit") && !shown.includes("rev: stale"), "resolved threads are hidden");
  assert.ok(shown.includes("1 open · 2 resolved"), "the counts still name the hidden ones");
  s.thread = "T2";
  assert.ok(p.shown().includes("rev: fixed nit"), "the selected thread stays listed while selected");
  assert.ok(!p.shown().includes("rev: stale"));
  s.thread = null;
  assert.ok(!p.shown().includes("rev: fixed nit"));
  s.view = "files";
  const send = async (name) => { const resolve = p.world.commands.shift(); resolve(name); await new Promise((r) => setTimeout(r, 0)); };
  await send("resolved");
  assert.deepEqual([s.hideResolved, s.view], [false, "review"], "the command toggles and returns to Review");
  assert.ok(p.shown().includes("rev: stale"));
  const only = JSON.parse(THREADS_DETAIL);
  only.data.repository.pullRequest.reviewThreads.nodes.shift();
  p.world.detailAnswer = JSON.stringify(only);
  p.mod.toggleResolved(p.cx);
  p.mod.sync(p.cx, true);
  await p.settle();
  assert.ok(p.shown().includes("2 resolved threads hidden"), "an all-resolved list says what it hides");
});

test("panel: commands from keys or herdr-app do switch the view, open nvim, and refresh", async () => {
  const p = panel("/repo-a");
  await p.settle();
  assert.equal(p.world.commands.length, 1, "the command loop waits");
  const send = async (name) => { const resolve = p.world.commands.shift(); resolve(name); await new Promise((r) => setTimeout(r, 0)); };
  await send("files");
  assert.equal(p.mod.state.view, "files");
  await p.settle();
  await send("review");
  assert.equal(p.mod.state.view, "review");
  await send("nvim");
  await p.settle();
  assert.equal(p.world.runs.length, 1);
  await send("refresh");
  await p.settle();
  assert.equal(p.calls("gh", "pr", "list"), 2);
  assert.equal(p.world.commands.length, 1, "the loop keeps waiting");
});
