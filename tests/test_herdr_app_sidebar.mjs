import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";
import test from "node:test";

const root = new URL("../home/herdr-app/mods/dotfiles-spaces/", import.meta.url);
const grouping = await readFile(new URL("grouping.js", root), "utf8");
const { groupRows } = await import(`data:text/javascript;base64,${Buffer.from(grouping).toString("base64")}`);
const main = await readFile(new URL("main.js", root), "utf8");

// Only the native builders and host imports are replaced. Exercise actual methods.
function element(asset) {
  const node = { children: [], events: {}, asset };
  const builder = new Proxy(node, {
    get(target, key) {
      if (key === "id") return id => { target.id = id; return builder; };
      if (key === "child") return child => { target.children.push(child); return builder; };
      if (key === "children") return children => { target.children.push(...children); return builder; };
      if (key === "when") return (condition, fn) => condition ? fn(builder) : builder;
      if (key.startsWith("on_")) return (...args) => { target.events[key] = args.at(-1); return builder; };
      if (key === "data") return target;
      return () => builder;
    },
  });
  return builder;
}

function fixture(sp, ps = [], storage = new Map()) {
  const calls = [];
  const sandbox = {
    View: class {}, div: element, svg: element, h_flex: element, v_flex: element,
    spaces: () => sp, panes: () => ps, machines: () => [], groupRows,
    run: (...args) => calls.push(args), openOverlay: args => calls.push(args),
    shared: () => ({}), localStorage: {
      getItem: key => storage.get(key) ?? null,
      setItem: (key, value) => storage.set(key, value),
    },
  };
  vm.createContext(sandbox);
  vm.runInContext(main.replace(/^import .*;$/gm, "").replace(/export function/g, "function")
    .replace("export default class Spaces", "class Spaces") + "\nglobalThis.Sidebar = Spaces;", sandbox);
  const sidebar = new sandbox.Sidebar();
  sidebar.init({}, { spawn() {}, notify() {}, timer: { every() {} } });
  sandbox.machines = () => sidebar.machines.map(m => ({ name: m.name, layout: "ready" }));
  return { sidebar, calls, storage };
}

function key(machine, folder) { return JSON.stringify([machine ?? null, folder]); }
const theme = new Proxy({}, { get: (_target, key) => key });
const plain = value => JSON.parse(JSON.stringify(value));
const names = nodes => Array.from(nodes, node => node.data?.id ?? node.space);

test("actual ordered adapter uses live cwd, machine-qualified Git, and original indices", () => {
  const sp = [
    { id: "child", machine: null, folder: "/tmp/topic", tabs: [{ id: "t0" }] },
    { id: "remote", machine: "dev", folder: "/srv/user/github/chewielabs/repo", tabs: [] },
    { id: "main", folder: "/old/folder", tabs: [{ id: "t2" }] },
  ];
  const cwd = "/Users/user/github/timopruesse/repo";
  const { sidebar } = fixture(sp, [{ tab: "t2", cwd }]);
  const repo = key(null, `${cwd}/.git`);
  sidebar.git[key(null, "/tmp/topic")] = { repo, linked: true };
  sidebar.git[key(null, cwd)] = { repo, linked: false };
  const rows = sidebar.ordered();
  assert.deepEqual(plain(rows.map(r => [r.w.id, r.i, r.tree])), [
    ["remote", 1, null], ["main", 2, null], ["child", 0, "└─"],
  ]);
  assert.equal(rows[1].path, cwd);
  assert.deepEqual(plain(groupRows(rows).map(g => [g.id, g.rows.map(r => r.w.id)])), [
    ["personal", ["main", "child"]], ["work", ["remote"]],
  ]);
});

test("actual grouped adapter keeps machine boundaries, owner headings, and compact indices", () => {
  const sp = [
    { id: "work", folder: "/home/a/github/chewielabs/repo" },
    { id: "other", machine: "dev", folder: "/tmp/unknown" },
    { id: "personal", machine: "dev", folder: "/srv/a/github/timopruesse/repo" },
  ];
  const { sidebar } = fixture(sp);
  sidebar.machines = [{ name: "dev", state: "connected" }];
  sidebar.row = r => ({ space: r.w.id, index: r.i });
  sidebar.compact = r => ({ space: r.w.id, index: r.i });
  for (const compact of [false, true]) {
    const nodes = sidebar.grouped(theme, compact);
    assert.deepEqual(names(nodes), ["machine-local", "owner-local-work", "work",
      "machine-dev", "owner-dev-personal", "personal", "owner-dev-other", "other"]);
    assert.deepEqual(Array.from(nodes.filter(n => typeof n.space === "string"), n => n.index), [0, 2, 1]);
  }
  sidebar.folded.add("dev");
  assert.deepEqual(names(sidebar.grouped(theme, false)), ["machine-local", "owner-local-work", "work", "machine-dev"]);
});

test("single machine needs no machine header and empty remote retains new-space action", () => {
  const { sidebar, calls } = fixture([{ id: "other", folder: "/tmp/unknown" }]);
  sidebar.row = r => ({ space: r.w.id });
  assert.deepEqual(names(sidebar.grouped(theme, false)), ["owner-local-other", "other"]);
  sidebar.machines = [{ name: "empty", state: "connected" }];
  const nodes = sidebar.grouped(theme, false);
  const empty = nodes.find(n => n.data?.id === "machine-new-empty");
  empty.data.events.on_click();
  assert.deepEqual(plain(calls), [["space.new", { machine: "empty" }]]);
});

test("owner click callbacks fold only their machine's section and persist independently", () => {
  const sp = [
    { id: "lp", folder: "/home/a/github/timopruesse/repo" },
    { id: "lw", folder: "/home/a/github/chewielabs/repo" },
    { id: "lo", folder: "/tmp/other" },
    { id: "rp", machine: "dev", folder: "/srv/a/github/timopruesse/repo" },
    { id: "rw", machine: "dev", folder: "/srv/a/github/chewielabs/repo" },
  ];
  const { sidebar, storage } = fixture(sp);
  sidebar.machines = [{ name: "dev", state: "connected" }];
  sidebar.row = sidebar.compact = r => ({ space: r.w.id, index: r.i });
  let notifications = 0;
  const cx = { notify() { notifications++; } };
  const click = (id, compact = false) => sidebar.grouped(theme, compact)
    .find(n => n.data?.id === id).data.events.on_click(null, cx);
  const visible = () => names(sidebar.grouped(theme, false)).filter(id => sp.some(s => s.id === id));

  click("owner-local-personal");
  assert.deepEqual(visible(), ["lw", "lo", "rp", "rw"]);
  assert.deepEqual(JSON.parse(storage.get("owners.folded")), [[null, "personal"]]);
  assert.equal(storage.has("machines.folded"), false);
  const folded = sidebar.grouped(theme, false).find(n => n.data?.id === "owner-local-personal");
  assert.equal(folded.data.children[1].data.asset, "mods/workspace-chrome/chevron-right.svg");
  click("owner-dev-work", true);
  assert.deepEqual(visible(), ["lw", "lo", "rp"]);
  assert.deepEqual(JSON.parse(storage.get("owners.folded")), [[null, "personal"], ["dev", "work"]]);
  click("machine-dev");
  assert.deepEqual(visible(), ["lw", "lo"]);
  assert.deepEqual(JSON.parse(storage.get("machines.folded")), ["dev"]);
  click("machine-dev");
  assert.deepEqual(visible(), ["lw", "lo", "rp"]);
  click("owner-local-personal", true);
  assert.deepEqual(visible(), ["lp", "lw", "lo", "rp"]);
  click("owner-local-other", true);
  assert.deepEqual(visible(), ["lp", "lw", "rp"]);
  assert.equal(notifications, 6);
  assert.deepEqual(Array.from(sidebar.grouped(theme, true).filter(n => typeof n.space === "string"), n => n.index), [0, 1, 3]);

  click("machine-dev");
  const restored = fixture(sp, [], storage).sidebar;
  restored.machines = sidebar.machines;
  restored.row = restored.compact = sidebar.row;
  assert.deepEqual(names(restored.grouped(theme, false)), names(sidebar.grouped(theme, false)));
  restored.grouped(theme, false).find(n => n.data?.id === "machine-dev").data.events.on_click(null, cx);
  assert.deepEqual(names(restored.grouped(theme, false)), [
    "machine-local", "owner-local-personal", "lp", "owner-local-work", "lw", "owner-local-other",
    "machine-dev", "owner-dev-personal", "rp", "owner-dev-work",
  ]);
});

test("compact owner headings retain labels, chevrons, and click callbacks without machine headers", () => {
  const { sidebar } = fixture([
    { id: "personal", folder: "/a/github/timopruesse/repo" },
    { id: "work", folder: "/a/github/chewielabs/repo" },
    { id: "other", folder: "/tmp/unknown" },
  ]);
  sidebar.compact = r => ({ space: r.w.id });
  for (const [id, label] of [["personal", "P"], ["work", "W"], ["other", "O"]]) {
    const head = sidebar.grouped(theme, true).find(n => n.data?.id === `owner-local-${id}`);
    assert.equal(head.data.children[0].data.children[0], label);
    assert.equal(head.data.children[1].data.asset, "mods/workspace-chrome/chevron-down.svg");
    head.data.events.on_click(null, { notify() {} });
    assert.equal(names(sidebar.grouped(theme, true)).includes(id), false);
    assert.equal(names(sidebar.grouped(theme, true)).includes(`owner-local-${id}`), true);
  }
});

test("malformed saved owner folds default open or discard invalid entries", () => {
  const sp = [{ id: "work", folder: "/a/github/chewielabs/repo" }];
  for (const saved of ["{", "null", "true", "42", '"work"', '{}', '[null, true, 1, "work", {}, [], [null], [3, "work"], [null, "unknown"], [null, "work", "extra"]]']) {
    const { sidebar } = fixture(sp, [], new Map([["owners.folded", saved]]));
    sidebar.row = r => ({ space: r.w.id });
    assert.deepEqual(names(sidebar.grouped(theme, false)), ["owner-local-work", "work"], saved);
  }
  const { sidebar } = fixture(sp, [], new Map([["owners.folded", JSON.stringify([
    null, [null, "work"], [null, "work"], ["dev", "personal"], [false, "other"],
  ])]]));
  sidebar.row = r => ({ space: r.w.id });
  assert.deepEqual(names(sidebar.grouped(theme, false)), ["owner-local-work"]);
  assert.equal(sidebar.foldedOwners.size, 2);
});

test("native row actions still target original id and global move index", () => {
  const sp = [{ id: "first", name: "First" }, { id: "second", name: "Second" }];
  const { sidebar, calls } = fixture(sp);
  const node = sidebar.row({ w: sp[1], i: 1, g: null, tree: null }, theme);
  const cx = { notify() {} };
  node.data.events.on_mouse_up(null, cx);
  assert.deepEqual(plain(calls.pop()), ["space.select", { id: "second" }]);
  sidebar.pressed = 0;
  node.data.events.on_mouse_up(null, cx);
  assert.deepEqual(plain(calls.pop()), ["space.move", { id: "first", index: 2 }]);
  node.data.events.on_mouse_down();
  assert.equal(calls.pop().props.target.id, "second");
  const compact = sidebar.compact({ w: sp[1], i: 1 }, theme);
  assert.equal(compact.data.children[0].data.children[0], "2");
  compact.data.events.on_click();
  assert.deepEqual(plain(calls.pop()), ["space.select", { id: "second" }]);
});
