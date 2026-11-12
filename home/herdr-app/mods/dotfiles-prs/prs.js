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

// The checkout's own PR first, then ones waiting on you (a review request, or a review
// you started and have not sent), then yours, newest first.
export function sortRows(rows, branch) {
  const tier = (r) => (branch && r.head === branch ? 0 : r.requested || r.pending ? 1 : r.mine ? 2 : 3);
  return [...rows].sort((a, b) => tier(a) - tier(b) || b.updatedAt - a.updatedAt || a.number - b.number);
}

export const DETAIL_QUERY = `query($owner:String!,$name:String!,$number:Int!){
  viewer{login}
  repository(owner:$owner,name:$name){pullRequest(number:$number){
    id headRefOid
    reviews(states:PENDING,first:5){nodes{id databaseId body author{login} comments(first:100){nodes{id path line originalLine body}}}}
    reviewThreads(first:100){nodes{id isResolved isOutdated path line originalLine diffSide comments(first:20){totalCount nodes{author{login} body createdAt}}}}
    latestReviews(first:30){nodes{author{login} state submittedAt}}
  }}
}`;

// Which open PRs carry an unsubmitted review of the viewer's: one query for the list.
export const PENDING_QUERY = `query($owner:String!,$name:String!,$viewer:String!){
  repository(owner:$owner,name:$name){pullRequests(states:OPEN,first:50,orderBy:{field:UPDATED_AT,direction:DESC}){
    nodes{number reviews(states:PENDING,first:1,author:$viewer){totalCount}}
  }}
}`;

// The numbers of the PRs with a pending review of the viewer's.
export function pendingOf(data) {
  const nodes = data?.data?.repository?.pullRequests?.nodes ?? data?.repository?.pullRequests?.nodes ?? [];
  return new Set(nodes.filter((n) => (n.reviews?.totalCount ?? 0) > 0).map((n) => n.number));
}

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
  if (!pr) return { id: null, headOid: null, pending: null, threads: [], reviews: [], viewer };
  const pendingNode = (pr.reviews?.nodes ?? []).find((r) => !viewer || !r.author || r.author.login === viewer) ?? null;
  const pending = pendingNode ? {
    id: pendingNode.id,
    databaseId: pendingNode.databaseId,
    body: pendingNode.body ?? "",
    // A review comment has no side in GraphQL (threads do); drafts are marked on the new side.
    comments: (pendingNode.comments?.nodes ?? []).map((c) => ({ id: c.id ?? null, path: c.path ?? "", line: c.line ?? c.originalLine ?? null, side: "RIGHT", body: c.body ?? "" })),
  } : null;
  const threads = (pr.reviewThreads?.nodes ?? []).map((t) => {
    const first = t.comments?.nodes?.[0];
    return {
      id: t.id,
      resolved: Boolean(t.isResolved),
      outdated: Boolean(t.isOutdated),
      path: t.path ?? "",
      line: t.line ?? t.originalLine ?? null,
      side: t.diffSide ?? "RIGHT",
      author: first?.author?.login ?? "",
      body: first?.body ?? "",
      count: t.comments?.totalCount ?? (t.comments?.nodes?.length ?? 0),
      last: t.comments?.nodes?.at(-1)?.author?.login ?? "",
    };
  });
  threads.sort((a, b) => Number(a.resolved) - Number(b.resolved));
  const reviews = (pr.latestReviews?.nodes ?? []).map((r) => ({ author: r.author?.login ?? "", state: r.state ?? "", at: Date.parse(r.submittedAt ?? "") || 0 }));
  return { id: pr.id ?? null, headOid: pr.headRefOid ?? null, pending, threads, reviews, viewer };
}

// The threads the Review view lists. With resolved ones hidden, the selected thread
// stays listed even when resolved, so resolving it from the bar does not drop it.
export function visibleThreads(threads, hideResolved, selected = null) {
  if (!hideResolved) return threads;
  return threads.filter((t) => !t.resolved || t.id === selected);
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

// `gh pr diff` output into one entry per file: the hunks from the first @@ on, the
// counts, and whether the file is new, gone, renamed, or binary.
export function parseDiff(text) {
  const files = [];
  let file = null;
  for (const line of String(text ?? "").replace(/\n$/, "").split("\n")) {
    const head = /^diff --git a\/(.*) b\/(.*)$/.exec(line);
    if (head) { file = { path: head[2], oldPath: head[1], status: "M", binary: false, lines: [], add: 0, del: 0 }; files.push(file); continue; }
    if (!file) continue;
    if (!file.lines.length) {
      if (line.startsWith("new file mode")) file.status = "A";
      else if (line.startsWith("deleted file mode")) file.status = "D";
      else if (line.startsWith("rename from") || line.startsWith("similarity index")) file.status = "R";
      else if (line.startsWith("Binary files") || line.startsWith("GIT binary patch")) file.binary = true;
      if (!line.startsWith("@@")) continue;
    }
    file.lines.push(line);
    if (line.startsWith("+")) file.add++;
    else if (line.startsWith("-")) file.del++;
  }
  return files;
}

// Text draws a tab as nothing: pad each to the next 4-column stop.
const untab = (text) => text.replace(/[^\t]*\t/g, (s) => s.slice(0, -1).padEnd((s.length - 1) - (s.length - 1) % 4 + 4));

// Numbers each hunk line once with the side GitHub comments on: deletions are LEFT
// lines of the old file, additions and context are RIGHT lines of the new one.
export function diffRows(lines) {
  let old = 0, next = 0;
  return (lines ?? []).map((line) => {
    const match = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    if (match) { old = +match[1]; next = +match[2]; return { kind: "@", text: line }; }
    const kind = line[0];
    if (kind === "-") return { kind, side: "LEFT", number: old++, text: untab(line.slice(1)) || " " };
    if (kind === "+") return { kind, side: "RIGHT", number: next++, text: untab(line.slice(1)) || " " };
    if (kind === " ") { old++; return { kind, side: "RIGHT", number: next++, text: untab(line.slice(1)) || " " }; }
    return { kind: "", text: line };
  });
}

// Draft comments and threads of one file, keyed "side:line", so a diff row can show them.
export function markersOf(detail, path) {
  const drafts = new Map(), threads = new Map();
  for (const c of detail?.pending?.comments ?? []) if (c.path === path && c.line) drafts.set(`${c.side ?? "RIGHT"}:${c.line}`, c);
  for (const t of detail?.threads ?? []) if (t.path === path && t.line) {
    const k = `${t.side ?? "RIGHT"}:${t.line}`;
    threads.set(k, [...(threads.get(k) ?? []), t]);
  }
  return { drafts, threads };
}

// `gh` arguments for draft comments. Adding one to a PR without a pending review
// starts the review (no event, so it stays unsubmitted); otherwise it joins the
// pending review. Deleting one removes it from the pending review.
export function draftArgs(action, { prId, pending, headOid, path, line, side, body, commentId }) {
  if (action === "delete") {
    if (!commentId) throw new Error("No draft comment to delete");
    return ["api", "graphql", "-f", "query=mutation($id:ID!){deletePullRequestReviewComment(input:{id:$id}){clientMutationId}}", "-f", `id=${commentId}`];
  }
  if (action !== "add") throw new Error(`Unknown draft action ${action}`);
  const text = (body ?? "").trim();
  if (!text) throw new Error("A review comment needs a message");
  if (!path || !line) throw new Error("Pick a diff line to comment on");
  const diffSide = side === "LEFT" ? "LEFT" : "RIGHT";
  if (pending) {
    return ["api", "graphql",
      "-f", "query=mutation($review:ID!,$path:String!,$line:Int!,$side:DiffSide!,$body:String!){addPullRequestReviewThread(input:{pullRequestReviewId:$review,path:$path,line:$line,side:$side,body:$body}){thread{id}}}",
      "-f", `review=${pending.id}`, "-f", `path=${path}`, "-F", `line=${line}`, "-f", `side=${diffSide}`, "-f", `body=${text}`];
  }
  if (!prId) throw new Error("The pull request's id is not loaded yet");
  const args = ["api", "graphql",
    "-f", `query=mutation($pr:ID!,$path:String!,$line:Int!,$side:DiffSide!,$body:String!${headOid ? ",$oid:GitObjectID!" : ""}){addPullRequestReview(input:{pullRequestId:$pr${headOid ? ",commitOID:$oid" : ""},threads:[{path:$path,line:$line,side:$side,body:$body}]}){pullRequestReview{id}}}`,
    "-f", `pr=${prId}`, "-f", `path=${path}`, "-F", `line=${line}`, "-f", `side=${diffSide}`, "-f", `body=${text}`];
  if (headOid) args.push("-f", `oid=${headOid}`);
  return args;
}

// Changing what a pending review already holds: a draft comment's text, or the
// review's summary. Both stay private until the review is submitted.
export function editArgs(kind, { commentId, pending, body }) {
  const text = (body ?? "").trim();
  if (kind === "draft") {
    if (!commentId) throw new Error("No draft comment to change");
    if (!text) throw new Error("A draft comment needs a message; delete it instead");
    return ["api", "graphql", "-f", "query=mutation($id:ID!,$body:String!){updatePullRequestReviewComment(input:{pullRequestReviewCommentId:$id,body:$body}){pullRequestReviewComment{id}}}", "-f", `id=${commentId}`, "-f", `body=${text}`];
  }
  if (kind === "summary") {
    if (!pending) throw new Error("No pending review to change");
    return ["api", "graphql", "-f", "query=mutation($id:ID!,$body:String!){updatePullRequestReview(input:{pullRequestReviewId:$id,body:$body}){pullRequestReview{id}}}", "-f", `id=${pending.id}`, "-f", `body=${text}`];
  }
  throw new Error(`Unknown edit ${kind}`);
}

// The diff rows around a commented line: `before` rows above it and `after` below,
// hunk headers included, from the loaded diff. Empty when the diff or line is not there.
export function snippetOf(diff, path, line, side = "RIGHT", before = 3, after = 2) {
  const rows = (diff ?? []).find((f) => f.path === path)?.rows ?? [];
  const at = rows.findIndex((r) => r.number === line && (r.side ?? "RIGHT") === (side ?? "RIGHT"));
  if (at < 0) return [];
  return rows.slice(Math.max(0, at - before), at + after + 1).map((r) => ({ ...r, here: r === rows[at] }));
}

const fenceOf = (rows) => rows.length ? ["```diff", ...rows.map((r) => r.kind === "@" || r.kind === "" ? r.text : `${r.kind}${String(r.number).padStart(5)} │ ${r.text}${r.here ? "   ◀" : ""}`), "```"] : [];

// The pending review as a Markdown file for an editor: the summary, then each draft
// under a header that names its line and carries its id, with the diff around the
// line in a fence. parseReviewFile reads it back; the fence is not part of the body.
export function reviewFile(pending, { repo, number, title, diff } = {}) {
  const out = [
    `<!-- Pending review on ${repo}#${number}: ${title ?? ""}`,
    "     Change the summary and the drafts below and save; the panel applies what changed.",
    "     Keep the \"## \" headers and their ids. An emptied draft is deleted; a missing one is",
    "     left as it is. The diff fences are context only and are ignored. -->",
    "", "## Summary", "", pending?.body ?? "", "",
  ];
  for (const c of pending?.comments ?? []) {
    out.push(`## ${c.path}${c.line ? `:${c.line}` : ""} <!-- draft ${c.id} -->`, "");
    const fence = fenceOf(snippetOf(diff, c.path, c.line, c.side));
    if (fence.length) out.push(...fence, "");
    out.push(c.body ?? "", "");
  }
  return out.join("\n");
}

export function parseReviewFile(text) {
  const parsed = { summary: null, drafts: new Map() };
  let put = null, lines = [];
  const close = () => { if (put) put(stripFence(lines).join("\n").trim()); lines = []; };
  for (const line of String(text ?? "").split("\n")) {
    const draft = /^## .*<!-- draft (\S+) -->\s*$/.exec(line);
    if (/^## Summary\s*$/.test(line)) { close(); put = (body) => { parsed.summary = body; }; continue; }
    if (draft) { close(); put = (body) => { parsed.drafts.set(draft[1], body); }; continue; }
    if (/^## /.test(line)) { close(); put = null; continue; }
    lines.push(line);
  }
  close();
  return parsed;
}

function stripFence(lines) {
  const first = lines.findIndex((l) => l.trim());
  if (first < 0 || !lines[first].startsWith("```diff")) return lines;
  const end = lines.findIndex((l, i) => i > first && l.trim() === "```");
  return end < 0 ? lines : [...lines.slice(0, first), ...lines.slice(end + 1)];
}

// What a saved review file changes against the pending review: the summary, draft
// texts, and drafts emptied out (deleted). Drafts missing from the file are untouched.
export function reviewEdits(pending, parsed) {
  const edits = [];
  if (!pending) return edits;
  if (parsed.summary !== null && parsed.summary !== (pending.body ?? "").trim()) edits.push({ kind: "summary", body: parsed.summary });
  for (const c of pending.comments ?? []) {
    if (!parsed.drafts.has(c.id)) continue;
    const body = parsed.drafts.get(c.id);
    if (!body) edits.push({ kind: "delete", id: c.id, path: c.path, line: c.line });
    else if (body !== (c.body ?? "").trim()) edits.push({ kind: "draft", id: c.id, path: c.path, line: c.line, body });
  }
  return edits;
}

// The remote that fetches from the repository, by `git remote -v`; origin otherwise.
export function remoteFor(remotes, repo) {
  const want = String(repo ?? "").toLowerCase().replace(/\.git$/, "");
  for (const line of String(remotes ?? "").split("\n")) {
    const m = /^(\S+)\s+(\S+)\s+\(fetch\)$/.exec(line.trim());
    if (!m) continue;
    const url = m[2].toLowerCase().replace(/\.git$/, "").replace(/\/$/, "");
    if (want && (url.endsWith(`/${want}`) || url.endsWith(`:${want}`))) return m[1];
  }
  return "origin";
}

// Walking a PR in Neovim: fetch its head and base into refs that touch no branch or
// worktree, then open diffview.nvim on the range (`<leader>gd` in the dotfiles config).
export function reviewRefs(remote, { number, base }) {
  const head = `refs/herdr/pr/${number}`, baseRef = `refs/herdr/base/${number}`;
  return {
    head, base: baseRef,
    fetch: ["fetch", "--no-tags", "--quiet", remote, `+refs/pull/${number}/head:${head}`, `+refs/heads/${base}:${baseRef}`],
    nvim: ["nvim", "-c", `DiffviewOpen ${baseRef}...${head}`],
  };
}
