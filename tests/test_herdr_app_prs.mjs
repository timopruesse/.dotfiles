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
  assert.deepEqual(d.pending, { id: "R2", databaseId: 22, body: "**draft** summary", comments: [{ path: "a.ts", line: 7, body: "nit" }, { path: "b.ts", line: 3, body: "rename" }] });
  assert.deepEqual(d.threads.map((t) => [t.id, t.resolved, t.line, t.author, t.count, t.last]), [["T2", false, 9, "rev", 1, "rev"], ["T1", true, 4, "bot", 3, "timo"]]);
  assert.equal(prs.plain(d.threads[1].body), "Fix this.");
  assert.deepEqual(d.reviews.map((r) => [r.author, r.state, r.at > 0]), [["rev", "CHANGES_REQUESTED", true]]);
  assert.deepEqual(prs.detailOf({ data: { repository: { pullRequest: null } } }), { pending: null, threads: [], reviews: [], viewer: null });
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
