import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

// A data URL loads the exact plain-JS runtime module without package.json changes.
const source = await readFile(new URL("../home/herdr-app/mods/dotfiles-spaces/grouping.js", import.meta.url), "utf8");
const { groupRows } = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`);
const row = (i, path, extra = {}) => ({ i, path, tree: null, ...extra });
const ids = rows => groupRows(rows).map(group => [group.id, group.rows.map(r => r.i)]);

test("ordered registry, stable rows, original global indices, and Other fallback", () => {
  const rows = [row(0, "/tmp/project"), row(1, "/home/timo/github/chewielabs/a"),
    row(2, "/Users/alex/github/timopruesse/b"), row(3, "/home/timo/github/chewielabs/c")];
  assert.deepEqual(ids(rows), [["personal", [2]], ["work", [1, 3]], ["other", [0]]]);
  const flattened = groupRows(rows).flatMap(group => group.rows);
  assert.equal(new Set(flattened).size, rows.length);
  for (const r of rows) assert.ok(flattened.includes(r));
  assert.deepEqual(rows.map(r => r.i), [0, 1, 2, 3]);
});

test("segment boundaries, non-repos, missing paths, and alternate remote homes", () => {
  assert.deepEqual(ids([
    row(0, "/srv/remote-user/github/chewielabs/repo"),
    row(1, "/home/u/github/chewielabs-extra/repo"),
    row(2, "/home/u/notgithub/timopruesse/repo"),
    row(3, "/home/u/github/timopruesse"), row(4, undefined),
    row(5, "C:\\Users\\dev\\github\\timopruesse\\repo"),
    row(6, "~/github/timopruesse/repo/src"),
  ]), [["personal", [5, 6]], ["work", [0]], ["other", [1, 2, 3, 4]]]);
});

test("common git directory classifies external worktree even without visible parent", () => {
  assert.deepEqual(ids([
    row(0, "/home/u/.herdr/worktrees/repo/topic", { repoPath: "/home/u/github/chewielabs/repo/.git" }),
    row(1, "/tmp/checkout", { repoPath: "/Users/sam/github/timopruesse/repo/.git" }),
  ]), [["personal", [1]], ["work", [0]]]);
});

test("checkout family stays adjacent, including conflicting worktree location", () => {
  const rows = [row(4, "/home/u/github/chewielabs/repo"),
    row(0, "/home/u/github/timopruesse/topic", { tree: "├─" }),
    row(7, "/tmp/topic2", { tree: "└─" }), row(1, "/home/u/github/timopruesse/main")];
  assert.deepEqual(ids(rows), [["personal", [1]], ["work", [4, 0, 7]]]);
  assert.deepEqual(groupRows(rows)[1].rows, rows.slice(0, 3));
});

test("common checkout wins conflicting cwd and cwd fallback works before git refresh", () => {
  assert.deepEqual(ids([row(0, "/home/u/github/timopruesse/repo", {
    repoPath: "/home/u/github/chewielabs/repo/.git",
  }), row(1, "/home/u/github/timopruesse/repo")]), [["personal", [1]], ["work", [0]]]);
  assert.deepEqual(groupRows([]), []);
});
