// Pure helpers for the PR panel: GitHub CLI output in, row and detail models out.
// No host imports, so node can test them directly.

const FAILED = new Set(["FAILURE", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE", "ERROR"]);
const OK = new Set(["SUCCESS", "NEUTRAL", "SKIPPED"]);

// One line per check run or status context: ok, failed, or pending.
export function checkState(entry) {
  if (entry.__typename === "StatusContext") {
    const state = entry.state ?? "";
    return FAILED.has(state) ? "failed" : OK.has(state) ? "ok" : "pending";
  }
  if (entry.status && entry.status !== "COMPLETED") return "pending";
  const conclusion = entry.conclusion ?? "";
  return FAILED.has(conclusion) ? "failed" : OK.has(conclusion) ? "ok" : "pending";
}

export function summarizeChecks(rollup) {
  const counts = { ok: 0, failed: 0, pending: 0, failing: [] };
  for (const entry of rollup ?? []) {
    const state = checkState(entry);
    counts[state]++;
    if (state === "failed") counts.failing.push(entry.name ?? entry.context ?? "check");
  }
  const total = counts.ok + counts.failed + counts.pending;
  counts.state = total === 0 ? "none" : counts.failed ? "failed" : counts.pending ? "pending" : "ok";
  return counts;
}

// Whether the viewer, or one of the viewer's teams ("org/slug"), is asked to review.
export function requestedOf(requests, viewer, teams) {
  return (requests ?? []).some((r) => (r.__typename === "User" || r.login) ? r.login === viewer : teams.has(r.slug));
}

export function requestNames(requests) {
  return (requests ?? []).map((r) => r.login ?? r.name ?? r.slug ?? "").filter(Boolean);
}

// `gh pr list --json ...` entries into rows.
export function rowsOf(list, viewer, teams = new Set()) {
  return (list ?? []).map((pr) => ({
    number: pr.number,
    title: pr.title ?? "",
    author: pr.author?.login ?? "",
    mine: pr.author?.login === viewer,
    draft: Boolean(pr.isDraft),
    decision: pr.reviewDecision ?? "",
    requested: requestedOf(pr.reviewRequests, viewer, teams),
    requests: requestNames(pr.reviewRequests),
    head: pr.headRefName ?? "",
    base: pr.baseRefName ?? "",
    url: pr.url ?? "",
    updatedAt: Date.parse(pr.updatedAt ?? "") || 0,
    additions: pr.additions ?? 0,
    deletions: pr.deletions ?? 0,
    headOid: pr.headRefOid ?? "",
    mergeable: pr.mergeable ?? "",
    mergeState: pr.mergeStateStatus ?? "",
    conflicts: pr.mergeable === "CONFLICTING",
    checks: summarizeChecks(pr.statusCheckRollup),
  }));
}

// The checkout's own PR first, then ones waiting on you, then yours, newest first.
export function sortRows(rows, branch) {
  const tier = (r) => (branch && r.head === branch ? 0 : r.requested ? 1 : r.mine ? 2 : 3);
  return [...rows].sort((a, b) => tier(a) - tier(b) || b.updatedAt - a.updatedAt || a.number - b.number);
}

export const DETAIL_QUERY = `query($owner:String!,$name:String!,$number:Int!){
  viewer{login}
  repository(owner:$owner,name:$name){pullRequest(number:$number){
    reviews(states:PENDING,first:5){nodes{id databaseId body author{login} comments(first:100){nodes{path line originalLine body}}}}
    reviewThreads(first:100){nodes{id isResolved isOutdated path line originalLine comments(first:20){totalCount nodes{author{login} body createdAt}}}}
    latestReviews(first:30){nodes{author{login} state submittedAt}}
  }}
}`;

// Markdown and bot HTML down to a short plain line.
export function plain(text, max = 240) {
  const s = String(text ?? "")
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/<details>[\s\S]*?<\/details>/g, "")
    .replace(/<[^>]+>/g, "")
    .replace(/```[\s\S]*?```/g, " ")
    .replace(/[*_`#>]+/g, "")
    .replace(/\s+/g, " ")
    .trim();
  return s.length > max ? s.slice(0, max - 1) + "…" : s;
}

// The GraphQL detail answer into pending review, threads, and latest reviews.
export function detailOf(data) {
  const pr = data?.data?.repository?.pullRequest ?? data?.repository?.pullRequest;
  const viewer = data?.data?.viewer?.login ?? data?.viewer?.login ?? null;
  if (!pr) return { pending: null, threads: [], reviews: [], viewer };
  const pendingNode = (pr.reviews?.nodes ?? []).find((r) => !viewer || !r.author || r.author.login === viewer) ?? null;
  const pending = pendingNode ? {
    id: pendingNode.id,
    databaseId: pendingNode.databaseId,
    body: pendingNode.body ?? "",
    comments: (pendingNode.comments?.nodes ?? []).map((c) => ({ path: c.path ?? "", line: c.line ?? c.originalLine ?? null, body: c.body ?? "" })),
  } : null;
  const threads = (pr.reviewThreads?.nodes ?? []).map((t) => {
    const first = t.comments?.nodes?.[0];
    return {
      id: t.id,
      resolved: Boolean(t.isResolved),
      outdated: Boolean(t.isOutdated),
      path: t.path ?? "",
      line: t.line ?? t.originalLine ?? null,
      author: first?.author?.login ?? "",
      body: first?.body ?? "",
      count: t.comments?.totalCount ?? (t.comments?.nodes?.length ?? 0),
      last: t.comments?.nodes?.at(-1)?.author?.login ?? "",
    };
  });
  threads.sort((a, b) => Number(a.resolved) - Number(b.resolved));
  const reviews = (pr.latestReviews?.nodes ?? []).map((r) => ({ author: r.author?.login ?? "", state: r.state ?? "", at: Date.parse(r.submittedAt ?? "") || 0 }));
  return { pending, threads, reviews, viewer };
}

// `gh` arguments for each action. `pending` is the viewer's pending review, if any.
export function reviewArgs(action, { repo, number, pending, body }) {
  const text = (body ?? "").trim();
  if (action === "discard") {
    if (!pending) throw new Error("No pending review to discard");
    return ["api", "-X", "DELETE", `repos/${repo}/pulls/${number}/reviews/${pending.databaseId}`];
  }
  const event = { approve: "APPROVE", comment: "COMMENT", request_changes: "REQUEST_CHANGES" }[action];
  if (!event) throw new Error(`Unknown review action ${action}`);
  if (pending) {
    const args = ["api", "-X", "POST", `repos/${repo}/pulls/${number}/reviews/${pending.databaseId}/events`, "-f", `event=${event}`];
    if (text) args.push("-f", `body=${text}`);
    return args;
  }
  if (event === "COMMENT" && !text) throw new Error("A comment review needs a message");
  const flag = { APPROVE: "--approve", COMMENT: "--comment", REQUEST_CHANGES: "--request-changes" }[event];
  const args = ["pr", "review", String(number), flag];
  if (text) args.push("--body", text);
  return args;
}

export const MERGE_METHODS = ["squash", "merge", "rebase"];

// `gh pr merge` guarded to the head the panel showed, so a push in between fails instead of merging unseen commits.
export function mergeArgs(method, { number, headOid }) {
  if (!MERGE_METHODS.includes(method)) throw new Error(`Unknown merge method ${method}`);
  if (!headOid) throw new Error("No head commit to guard the merge with");
  return ["pr", "merge", String(number), `--${method}`, "--match-head-commit", headOid];
}

export function threadArgs(action, { id, body }) {
  if (action === "reply") {
    const text = (body ?? "").trim();
    if (!text) throw new Error("A reply needs a message");
    return ["api", "graphql", "-f", "query=mutation($id:ID!,$body:String!){addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$id,body:$body}){comment{id}}}", "-f", `id=${id}`, "-f", `body=${text}`];
  }
  const name = action === "resolve" ? "resolveReviewThread" : action === "unresolve" ? "unresolveReviewThread" : null;
  if (!name) throw new Error(`Unknown thread action ${action}`);
  return ["api", "graphql", "-f", `query=mutation($id:ID!){${name}(input:{threadId:$id}){thread{isResolved}}}`, "-f", `id=${id}`];
}

export function age(ms, now = Date.now()) {
  if (!ms) return "";
  const m = Math.floor((now - ms) / 60000);
  if (m < 1) return "now";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h`;
  const d = Math.floor(h / 24);
  return d < 30 ? `${d}d` : `${Math.floor(d / 30)}mo`;
}

export const DECISION = {
  APPROVED: { label: "Approved", color: "ansi2" },
  CHANGES_REQUESTED: { label: "Changes", color: "ansi1" },
  REVIEW_REQUIRED: { label: "Review", color: "ansi3" },
};
