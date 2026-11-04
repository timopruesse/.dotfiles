import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";
import test from "node:test";

const main = await readFile(new URL("../home/herdr-app/mods/dotfiles-agents/main.js", import.meta.url), "utf8");

// Only the native builders and host imports are replaced. Exercise actual methods.
function element() {
  const node = { children: [], events: {} };
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

const theme = new Proxy({}, { get: (_target, key) => key });
// Sandbox objects have their own prototypes; compare them as plain data.
const plain = value => JSON.parse(JSON.stringify(value));

function agent(address, status, seq, extra = {}) {
  return { address, pane: `p-${address}`, space: "s1", space_name: "one", tab: `tb-${address}`, tab_index: 0,
    tab_name: "", status, app: "pi", program: { name: "Pi", key: "pi" }, title: "", seq, pinned: false, focused: false, ...extra };
}

function fixture(list, { sort = "priority", commands = [] } = {}) {
  const calls = [];
  const order = [];
  let pending = [...commands];
  const sandbox = {
    console, View: class {}, div: element, image: element, svg: element, v_flex: element, h_flex: element,
    agents: () => list, terminals: () => [], panes: () => [], focused: () => ({ agent: null }), spaces: () => [],
    run: (...args) => calls.push(args), theme: () => theme, shared: key => (key === "agents.sort" ? sort : null),
    setShared() {}, setAgentOrder: addresses => order.push(addresses), openOverlay() {}, closeOverlay() {},
    props: () => undefined, window: () => ({ platform: "linux" }),
    layout: () => ({ id: "root", children: [{ id: "sidebar", size: { px: 268 } }] }),
    nextCommand: () => (pending.length ? Promise.resolve(pending.shift()) : new Promise(() => {})),
    localStorage: { getItem: () => null, setItem() {}, removeItem() {} },
  };
  vm.createContext(sandbox);
  vm.runInContext(main.replace(/^import .*;$/gm, "").replace("export default class Agents", "class Agents")
    + "\nglobalThis.Mod = Agents;", sandbox);
  const mod = new sandbox.Mod();
  const spawned = [];
  const cx = { spawn: fn => spawned.push(fn(cx)), notify() {}, timer: { every() {} } };
  mod.init({}, cx);
  return { mod, calls, order, spawned };
}

const sample = () => [agent("t1", "idle", 1), agent("t2", "blocked", 2), agent("t3", "working", 3, { pinned: true })];

test("priority view: focus<n> follows the drawn order, pinned first, and matches agent.next order", () => {
  const { mod, calls, order } = fixture(sample());
  mod.render();
  assert.deepEqual(plain(order.at(-1)), ["t3", "t2", "t1"]);
  mod.command("focus1");
  mod.command("focus2");
  mod.command("focus:3");
  mod.command("focus9");
  mod.command("focus");
  mod.command("nonsense");
  assert.deepEqual(plain(calls), [["pane.focus", { pane: "p-t3" }], ["pane.focus", { pane: "p-t2" }], ["pane.focus", { pane: "p-t1" }]]);
});

test("grouped view: focus<n> follows model order with pinned agents first", () => {
  const { mod, calls, order } = fixture(sample(), { sort: "grouped" });
  mod.render();
  assert.deepEqual(plain(order.at(-1)), ["t3", "t1", "t2"]);
  mod.command("focus2");
  assert.deepEqual(plain(calls), [["pane.focus", { pane: "p-t1" }]]);
});

test("before the first render, model order with pinned first stands in", () => {
  const { mod, calls } = fixture(sample());
  mod.command("focus3");
  assert.deepEqual(plain(calls), [["pane.focus", { pane: "p-t2" }]]);
});

test("the key loop delivers nextCommand() to command()", async () => {
  const { mod, calls } = fixture(sample(), { commands: ["focus2"] });
  mod.render();
  await new Promise(resolve => setTimeout(resolve, 0));
  assert.deepEqual(plain(calls), [["pane.focus", { pane: "p-t2" }]]);
  assert.equal(typeof mod.command, "function");
});

test("the sort menu copy opens the owned mod, not the shipped one", () => {
  assert.ok(main.includes('openOverlay({ mod: "dotfiles-agents"'));
  assert.ok(!main.includes('mod: "agents"'));
});
