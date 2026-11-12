// Pull requests of the shown space's repo, beside Files and Changes: a list on top,
// the picked PR below in two views. Review shows the pending review, threads, reviews
// and checks; Files shows the changed files and each file's diff, where clicking a line
// adds a draft comment to the pending review. The message box submits or discards the
// pending review, replies to and resolves threads, and writes draft comments.
// Outward-facing actions arm first and run on a second, explicit Confirm click; draft
// comments are private until the review is submitted, so they need no confirmation.
// "nvim" fetches the PR's head and base into refs and walks them with diffview.nvim.
// The panel keeps one record per repository (list, picked PR, details, diff, draft).
// Moving the focus to another agent, tab or space switches records instead of
// clearing the panel, so a repository seen before comes back as it was, at once.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, TextareaState, Textarea, Scrollbar, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { spaces, panes, focused, exec, run, nextCommand, theme, settings } from "herdr";
import { rowsOf, sortRows, detailOf, pendingOf, reviewArgs, threadArgs, mergeArgs, draftArgs, parseDiff, diffRows, markersOf, remoteFor, reviewRefs, plain, age, DETAIL_QUERY, PENDING_QUERY, DECISION, MERGE_METHODS } from "./prs.js";

function location() {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on, branch: pane?.branch ?? space?.branch ?? null, pane: f?.pane ?? null };
}
const key = () => { const { cwd, on } = location(); return JSON.stringify({ cwd, on }); };
const LIST_FIELDS = "number,title,author,isDraft,reviewDecision,reviewRequests,headRefName,baseRefName,headRefOid,mergeable,mergeStateStatus,url,updatedAt,statusCheckRollup,additions,deletions";
// A record shown again after this long refreshes in the background, behind its rows.
const STALE = 20000;
const DIFF_LINES = 4000; // per file; a longer diff is cut and says so
const ACTIONS = {
  approve: { label: "Approve", title: "Approve this pull request?" },
  comment: { label: "Comment", title: "Submit a comment review?" },
  request_changes: { label: "Request changes", title: "Request changes on this pull request?" },
  discard: { label: "Discard", title: "Discard the pending review?" },
  checkout: { label: "Checkout", title: "Check out this pull request's branch?" },
  merge: { label: "Merge", title: "Merge this pull request?" },
  add: { label: "Add to review" },
  delete: { label: "Delete draft" },
  reply: { label: "Reply" },
  resolve: { label: "Resolve" },
  unresolve: { label: "Unresolve" },
};
const STATUS = { A: "ansi2", D: "ansi1", R: "ansi4", M: "blocked" };

// Everything the panel shows for one repository on one machine. Worktrees of the same
// repository share it; the checkout they act in is the current location's root.
function record(repo, on) {
  return { repo, on, raw: [], rows: [], pendingNumbers: new Set(), detail: null, open: null, thread: null, closed: false,
    error: null, note: null, armed: null, message: "", loading: false, busy: false, fetched: 0,
    view: "review", diff: null, diffHead: null, diffError: null, diffLoading: false, file: null, line: null };
}

export default class PullRequests extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.teams = new Set(); this.viewer = null; this.mergeMethod = "squash";
    this.places = new Map(); // location key -> { root, repo, on } once resolved
    this.records = new Map(); // "machine|owner/name" -> record
    this.state = null; this.root = null; this.on = null; this.error = null; this.context = null; this.resolving = null;
    this.scroll = VirtualListScrollHandle.new();
    this.input = TextareaState.new({ placeholder: "Review message, thread reply, or line comment" });
    this.input.set_auto_grow(1, 6);
    this.input.on("change", (_e, cx) => {
      const s = this.state;
      if (!s) return;
      const had = Boolean(s.message.trim());
      s.message = this.input.value();
      if (had !== Boolean(s.message.trim())) cx.notify();
    });
    this.input.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    this.identify(cx);
    this.sync(cx);
    cx.timer.every(60000, (cx) => this.refresh(cx));
    // `dotfiles-prs.<command>` from keys.json or `herdr-app do`: review, files, nvim, refresh.
    cx.spawn(async (cx) => { for (;;) this.command(await nextCommand(), cx); });
  }

  command(name, cx) {
    if (name === "review" || name === "files") this.view(name, cx);
    else if (name === "nvim") this.nvim(cx);
    else if (name === "refresh") this.sync(cx, true);
  }

  rowsFor(s) {
    const rows = rowsOf(s.raw, this.viewer, this.teams).map((r) => ({ ...r, pending: s.pendingNumbers.has(r.number) }));
    return sortRows(rows, s === this.state ? location().branch : null);
  }

  // Who is looking, once: review requests to you or your teams get a badge.
  identify(cx) {
    cx.spawn(async (cx) => {
      try {
        const me = await exec("gh", ["api", "user", "--jq", ".login"]);
        if (me.code === 0) this.viewer = me.stdout.trim() || null;
        const teams = await exec("gh", ["api", "user/teams", "--paginate", "--jq", '.[] | "\\(.organization.login)/\\(.slug)"']);
        if (teams.code === 0) this.teams = new Set(teams.stdout.split("\n").map((s) => s.trim()).filter(Boolean));
      } catch {}
      for (const s of this.records.values()) s.rows = this.rowsFor(s);
      cx.notify();
    });
  }

  // Follows the focused pane. A location seen before switches to its repository's record
  // at once; a new one resolves in the background while the panel keeps showing what it
  // showed, so the loader appears only for a repository that was never listed.
  sync(cx, force = false) {
    const context = key();
    if (context === this.context && !force) return;
    this.context = context;
    const { cwd, on } = location();
    if (!cwd) { this.show({ root: null, repo: null, on, error: "No folder" }, cx); return; }
    const place = force ? null : this.places.get(context);
    if (place) { this.show(place, cx); return; }
    this.error = null; // the old location's error does not describe the new one
    this.resolve(context, cwd, on, cx, force);
  }

  // cwd -> checkout root -> GitHub repository. Failures are not remembered: the next
  // refresh (timer or button) asks again.
  resolve(context, cwd, on, cx, force = false) {
    if (this.resolving === context) return;
    this.resolving = context;
    cx.spawn(async (cx) => {
      const place = { root: null, repo: null, on, error: null };
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
        if (top.code !== 0) place.error = "Not a git repository";
        else {
          place.root = top.stdout.trim();
          const known = [...this.places.values()].find((p) => p.repo && p.root === place.root && p.on === on);
          if (known) place.repo = known.repo;
          else {
            const repo = await exec("gh", ["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], { cwd: place.root, on });
            if (repo.code !== 0) place.error = plain(repo.stderr || "No GitHub repository for this checkout", 160);
            else place.repo = repo.stdout.trim();
          }
        }
      } catch (e) { place.error = e?.message ? String(e.message) : String(e); }
      if (!place.error) this.places.set(context, place);
      if (this.resolving === context) this.resolving = null;
      if (this.context === context) { this.show(place, cx, force); cx.notify(); }
    });
  }

  show(place, cx, force = false) {
    this.root = place.root; this.on = place.on ?? null; this.error = place.error ?? null;
    const s = place.repo ? this.recordFor(place.repo, this.on) : null;
    if (s !== this.state) {
      this.state = s;
      this.input.set_value(s?.message ?? "");
    }
    if (!s) return;
    s.rows = this.rowsFor(s);
    if (force || !s.fetched || Date.now() - s.fetched > STALE) this.refresh(cx, true);
  }

  recordFor(repo, on) {
    const id = `${on ?? ""}|${repo}`;
    let s = this.records.get(id);
    if (!s) { s = record(repo, on); this.records.set(id, s); }
    return s;
  }

  // Lists the current repository's open PRs into its record. The rows it showed stay
  // until the new ones arrive, and the result lands in the record it was fetched for.
  refresh(cx, force = false) {
    const s = this.state;
    if (!s) { if (this.context) this.sync(cx, true); return; }
    if (s.loading || (s.busy && !force)) return;
    s.loading = true;
    const root = this.root, on = this.on;
    cx.spawn(async (cx) => {
      try {
        const list = await exec("gh", ["pr", "list", "--state", "open", "--limit", "50", "--json", LIST_FIELDS], { cwd: root, on });
        if (list.code !== 0) throw new Error(plain(list.stderr || list.stdout, 200));
        s.raw = JSON.parse(list.stdout || "[]"); s.error = null; s.fetched = Date.now();
        s.rows = this.rowsFor(s);
        if (s.open && !s.rows.some((r) => r.number === s.open)) { s.open = null; s.detail = null; s.thread = null; this.forget(s); }
        if (!s.open && !s.closed && s.rows.length) s.open = s.rows[0].number;
        const row = s.rows.find((r) => r.number === s.open);
        if (row && s.diff && (row.headOid ?? "") !== (s.diffHead ?? "")) this.forget(s); // new commits: the diff is stale
        if (s.open) await this.load(s, s.open, root, on);
        cx.notify();
        await this.pendings(s, root, on);
      } catch (e) {
        s.error = e?.message ? String(e.message) : String(e);
      } finally { s.loading = false; cx.notify(); }
    });
  }

  // Which listed PRs carry an unsubmitted review of yours: a badge on the row.
  async pendings(s, root, on) {
    if (!this.viewer) return;
    const [owner, name] = s.repo.split("/");
    try {
      const r = await exec("gh", ["api", "graphql", "-f", `query=${PENDING_QUERY}`, "-f", `owner=${owner}`, "-f", `name=${name}`, "-f", `viewer=${this.viewer}`], { cwd: root, on });
      if (r.code !== 0) return;
      s.pendingNumbers = pendingOf(JSON.parse(r.stdout));
      s.rows = this.rowsFor(s);
    } catch {}
  }

  async load(s, number, root, on) {
    const [owner, name] = s.repo.split("/");
    const r = await exec("gh", ["api", "graphql", "-f", `query=${DETAIL_QUERY}`, "-f", `owner=${owner}`, "-f", `name=${name}`, "-F", `number=${number}`], { cwd: root, on });
    if (s.open !== number) return;
    if (r.code !== 0) { s.detail = null; s.note = `Cannot load review details: ${plain(r.stderr || r.stdout, 200)}`; return; }
    s.detail = detailOf(JSON.parse(r.stdout));
    if (s.thread && !s.detail.threads.some((t) => t.id === s.thread)) s.thread = null;
    if (s.detail.pending) s.pendingNumbers.add(number); else s.pendingNumbers.delete(number);
    s.rows = this.rowsFor(s);
  }

  forget(s) { s.diff = null; s.diffHead = null; s.diffError = null; s.file = null; s.line = null; }

  pick(number, cx) {
    const s = this.state;
    if (!s) return;
    s.open = s.open === number ? null : number;
    s.closed = !s.open; s.detail = null; s.thread = null; s.note = null; s.armed = null;
    this.forget(s);
    const root = this.root, on = this.on;
    if (s.open) cx.spawn(async (cx) => {
      try { await this.load(s, number, root, on); } catch (e) { if (s.open === number) s.note = `Cannot load review details: ${e}`; }
      if (s.open === number && s.view === "files") this.loadDiff(s, cx);
      cx.notify();
    });
    cx.notify();
  }

  // The whole diff once per PR head, cut per file; the picked file shows from it.
  loadDiff(s, cx) {
    const number = s.open;
    if (!number || s.diffLoading || (s.diff && s.diffHead === (s.rows.find((r) => r.number === number)?.headOid ?? s.diffHead))) return;
    s.diffLoading = true; s.diffError = null;
    const root = this.root, on = this.on, head = s.rows.find((r) => r.number === number)?.headOid ?? null;
    cx.spawn(async (cx) => {
      try {
        const r = await exec("gh", ["pr", "diff", String(number)], { cwd: root, on, timeout: 60000 });
        if (s.open !== number) return;
        if (r.code !== 0) throw new Error(plain(r.stderr || r.stdout, 200) || "gh pr diff failed");
        const files = parseDiff(r.stdout);
        for (const f of files) {
          if (f.lines.length > DIFF_LINES) { f.lines = f.lines.slice(0, DIFF_LINES); f.lines.push(`… diff cut after ${DIFF_LINES} lines; use nvim for the rest`); }
          f.rows = diffRows(f.lines);
          f.width = Math.max(300, ...f.rows.map((row) => (row.text.length + 1) * 7 + 60));
        }
        s.diff = files; s.diffHead = head;
        if (s.file && !files.some((f) => f.path === s.file)) { s.file = null; s.line = null; }
        if (!s.file && files.length) s.file = files[0].path;
      } catch (e) { if (s.open === number) { s.diff = null; s.diffError = String(e?.message ?? e); } }
      finally { if (s.open === number) s.diffLoading = false; cx.notify(); }
    });
  }

  view(name, cx) {
    const s = this.state;
    if (!s || s.view === name) return;
    s.view = name; s.armed = null;
    if (name === "files") this.loadDiff(s, cx);
    cx.notify();
  }

  // Jumps to a thread's or draft's line in the Files view.
  reveal(path, line, side, cx) {
    const s = this.state;
    if (!s) return;
    s.view = "files"; s.file = path; s.line = null; s.armed = null;
    if (!s.diff) { this.loadDiff(s, cx); cx.notify(); return; }
    const file = s.diff.find((f) => f.path === path);
    const index = file ? file.rows.findIndex((row) => row.number === line && (row.side ?? "RIGHT") === (side ?? "RIGHT")) : -1;
    if (index >= 0) { s.line = { path, ...file.rows[index] }; try { this.scroll.scroll_to_item(index, "center"); } catch {} }
    cx.notify();
  }

  pickFile(path, cx) {
    const s = this.state;
    if (!s) return;
    s.file = s.file === path ? null : path; s.line = null; s.note = null;
    try { this.scroll.scroll_to_item(0); } catch {}
    cx.notify();
  }

  pickLine(row, cx) {
    const s = this.state;
    if (!s || !s.file || row.kind === "@" || row.kind === "") return;
    const same = s.line && s.line.path === s.file && s.line.number === row.number && s.line.side === row.side;
    s.line = same ? null : { path: s.file, ...row }; s.thread = null; s.armed = null;
    cx.notify();
  }

  // Fetches the PR's head and base into refs/herdr/* (no branch, no worktree) and opens
  // Neovim on the range beside the focused pane, or in a new tab when nothing is focused.
  nvim(cx) {
    const s = this.state;
    const row = s?.rows.find((r) => r.number === s.open);
    if (!row || s.busy || !this.root) return;
    const number = row.number, root = this.root, on = this.on, place = location().pane ? "right" : "tab";
    s.busy = true; s.note = null;
    cx.spawn(async (cx) => {
      try {
        const remotes = await exec("git", ["remote", "-v"], { cwd: root, on });
        const refs = reviewRefs(remoteFor(remotes.stdout, s.repo), { number, base: row.base });
        const fetch = await exec("git", refs.fetch, { cwd: root, on, timeout: 120000 });
        if (fetch.code !== 0) throw new Error(plain(fetch.stderr || fetch.stdout, 240));
        run("terminal.open", { argv: refs.nvim, folder: root, place });
        s.note = `nvim: ${refs.base.replace("refs/herdr/", "")}…${refs.head.replace("refs/herdr/", "")}`;
      } catch (e) { s.note = `nvim failed: ${e?.message ?? e}`; }
      finally { s.busy = false; cx.notify(); }
    });
    cx.notify();
  }

  // Destructive or outward-facing actions ask first: the button row turns into
  // the question with Confirm and Cancel until one is clicked.
  arm(action, cx, detail) {
    const s = this.state;
    if (!s || s.busy) return;
    s.armed = { action, detail, number: s.open };
    cx.notify();
  }

  act(action, cx) {
    const s = this.state;
    const row = s?.rows.find((r) => r.number === s.open);
    if (!row || s.busy) return;
    const number = row.number, root = this.root, on = this.on;
    let args;
    try {
      if (action === "checkout") args = ["pr", "checkout", String(number)];
      else if (action === "merge") args = mergeArgs(this.mergeMethod, { number, headOid: row.headOid });
      else if (action === "open") args = ["pr", "view", String(number), "--web"];
      else if (action === "reply" || action === "resolve" || action === "unresolve") args = threadArgs(action, { id: s.thread, body: s.message });
      else if (action === "add") args = draftArgs("add", { prId: s.detail?.id, pending: s.detail?.pending, headOid: s.detail?.headOid ?? row.headOid, path: s.line?.path, line: s.line?.number, side: s.line?.side, body: s.message });
      else if (action === "delete") args = draftArgs("delete", { commentId: this.draftAt(s)?.id });
      else args = reviewArgs(action, { repo: s.repo, number, pending: s.detail?.pending, body: s.message });
    } catch (e) { s.note = String(e.message ?? e); cx.notify(); return; }
    s.busy = true; s.note = null;
    cx.spawn(async (cx) => {
      try {
        const r = await exec("gh", args, { cwd: root, on });
        if (r.code !== 0) throw new Error(plain(r.stderr || r.stdout, 240));
        if (action === "reply" || action === "comment" || action === "approve" || action === "request_changes" || action === "add") {
          s.message = "";
          if (this.state === s) this.input.set_value("");
        }
        if (action === "merge") s.note = `Merged #${number} (${this.mergeMethod})`;
        else if (action === "add") s.note = `Draft comment on ${s.line?.path}:${s.line?.number} added to your pending review`;
        else if (action === "delete") s.note = "Draft comment deleted";
        else if (action !== "open") s.note = `${ACTIONS[action]?.label ?? "Done"}: #${number}`;
      } catch (e) { s.note = `${ACTIONS[action]?.label ?? action} failed: ${e.message ?? e}`; }
      finally {
        s.busy = false;
        if (action !== "open" && action !== "checkout" && action !== "merge" && s.open === number) { try { await this.load(s, number, root, on); } catch {} }
        if (action === "checkout" || action === "merge") { s.fetched = 0; if (this.state === s) this.refresh(cx, true); }
        cx.notify();
      }
    });
    cx.notify();
  }

  draftAt(s) {
    if (!s?.line) return null;
    return (s.detail?.pending?.comments ?? []).find((c) => c.path === s.line.path && c.line === s.line.number && (c.side ?? "RIGHT") === (s.line.side ?? "RIGHT")) ?? null;
  }

  chip(t, label, color) {
    return div().flex_none().px(5).h(16).rounded(4).bg(color + "26").text_size(10).font_semibold().text_color(color).flex().items_center().child(label);
  }

  checks(t, c) {
    if (c.state === "none") return null;
    const color = c.state === "ok" ? t.ansi2 : c.state === "failed" ? t.ansi1 : t.ansi3;
    return div().size(7).mx(2).flex_none().rounded(4).bg(color);
  }

  row(t, r, branch) {
    const on = this.state?.open === r.number, here = branch && r.head === branch;
    const d = DECISION[r.decision];
    return h_flex().id(`pr-${r.number}`).h(28).flex_none().px(8).gap(6).items_center().rounded(7).cursor_pointer()
      .when(on, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.pick(r.number, cx))
      .child(div().w(36).flex_none().text_size(11).text_color(here ? t.accent : t.dim).child(`#${r.number}`))
      .child(div().flex_1().min_w(0).truncate().text_color(r.draft ? t.muted : t.foreground).child(r.title))
      .when(r.draft, (e) => e.child(this.chip(t, "draft", t.dim)))
      .when(r.conflicts, (e) => e.child(this.chip(t, "conflicts", t.ansi1)))
      .when(r.pending, (e) => e.child(this.chip(t, "unsent review", t.accent)))
      .when(r.requested, (e) => e.child(this.chip(t, "review", t.blocked)))
      .when(!r.requested && Boolean(d), (e) => e.child(this.chip(t, d.label, t[d.color])))
      .when(Boolean(this.checks(t, r.checks)), (e) => e.child(this.checks(t, r.checks)))
      .child(div().flex_none().text_size(10.5).text_color(t.dim).child(age(r.updatedAt)));
  }

  section(t, label, right) {
    return h_flex().h(26).flex_none().px(12).items_center().gap(6).text_size(10.5).font_medium().text_color(t.dim)
      .child(div().child(label)).child(div().flex_1()).when(Boolean(right), (e) => e.child(div().child(right)));
  }

  button(id, label, action, primary = false, enabled = true) {
    const t = theme();
    return div().id(id).h(26).px(10).flex_none().flex().items_center().rounded(7).text_size(11.5)
      .bg(enabled ? (primary ? t.solid : t.raised) : t.raised).text_color(enabled ? (primary ? t.solid_foreground : t.foreground) : t.dim)
      .when(enabled, (e) => e.cursor_pointer().hover((s) => s.opacity(0.85)).on_click((_e, cx) => action(cx)))
      .child(label);
  }

  tab(t, id, label, on, action) {
    return div().id(id).h(22).px(9).flex_none().flex().items_center().rounded(6).text_size(11).cursor_pointer()
      .when(on, (e) => e.bg(t.selected)).text_color(on ? t.foreground : t.muted).hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => action(cx)).child(label);
  }

  threadRow(t, th) {
    const s = this.state, on = s.thread === th.id;
    return v_flex().id(`thread-${th.id}`).flex_none().px(12).py(5).gap(2).cursor_pointer()
      .when(on, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => { s.thread = on ? null : th.id; s.armed = null; cx.notify(); })
      .child(h_flex().gap(6).items_center()
        .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(th.resolved ? t.dim : t.foreground).child(`${th.path}${th.line ? `:${th.line}` : ""}`))
        .when(th.outdated, (e) => e.child(this.chip(t, "outdated", t.dim)))
        .child(this.chip(t, th.resolved ? "resolved" : "open", th.resolved ? t.ansi2 : t.ansi3))
        .child(div().flex_none().text_size(10.5).text_color(t.dim).child(`${th.count}`)))
      .child(div().text_size(11).text_color(t.muted).child(`${th.author}: ${plain(th.body, on ? 600 : 140)}`));
  }

  // The picked PR's header: title, who and where, counts, the view switch, and the
  // local actions (nvim, checkout) with Open and Merge.
  headerView(t, r) {
    const s = this.state, d = s.detail;
    const meta = `${r.author} · ${r.head} → ${r.base}`;
    const files = s.diff ? s.diff.length : null;
    return v_flex().flex_none().px(12).pt(10).pb(6).gap(6)
      .child(div().text_size(12.5).font_semibold().child(r.title))
      .child(h_flex().gap(8).items_center().text_size(11).text_color(t.muted)
        .child(div().flex_1().min_w(0).truncate().child(meta))
        .when(Boolean(r.mergeState), (e) => e.child(div().text_color(r.conflicts ? t.ansi1 : t.dim).child(r.mergeState.toLowerCase())))
        .child(div().text_color(t.ansi2).child(`+${r.additions}`)).child(div().text_color(t.ansi1).child(`−${r.deletions}`)))
      .when(r.requests.length > 0, (e) => e.child(div().text_size(11).text_color(r.requested ? t.blocked : t.dim).child(`Review requested: ${r.requests.join(", ")}`)))
      .child(h_flex().gap(6).pt(2).items_center()
        .child(this.tab(t, "view-review", d?.pending ? `Review · ${d.pending.comments.length} draft` : "Review", s.view === "review", (cx) => this.view("review", cx)))
        .child(this.tab(t, "view-files", files === null ? "Files" : `Files · ${files}`, s.view === "files", (cx) => this.view("files", cx)))
        .child(div().flex_1())
        .child(this.button("pr-nvim", "nvim", (cx) => this.nvim(cx), false, !s.busy))
        .child(this.button("pr-open", "Open", (cx) => this.act("open", cx)))
        .child(this.button("pr-checkout", "Checkout", (cx) => this.arm("checkout", cx, `gh pr checkout ${r.number} in ${this.root}`), false, !s.busy))
        .child(this.button("pr-merge", "Merge", (cx) => this.arm("merge", cx, `#${r.number} ${r.title} into ${r.base}, guarded to ${r.headOid.slice(0, 7)}`), false, !s.busy && !r.draft && !r.conflicts && Boolean(r.headOid))));
  }

  reviewView(t, r) {
    const s = this.state, d = s.detail;
    const c = r.checks;
    const parts = [];
    if (!d) {
      parts.push(div().px(12).py(6).text_size(11).text_color(t.dim).child(s.note ?? "Loading review details…"));
      return parts;
    }
    if (d.pending) {
      parts.push(this.section(t, "Pending review", `${d.pending.comments.length} draft comment${d.pending.comments.length === 1 ? "" : "s"}`));
      parts.push(v_flex().flex_none().mx(8).p(8).gap(6).rounded(8).border_1().border_color(t.blocked + "66").bg(t.blocked + "12")
        .when(Boolean(d.pending.body.trim()), (e) => e.child(div().text_size(11).text_color(t.foreground).child(plain(d.pending.body, 400))))
        .children(d.pending.comments.map((cm, i) => v_flex().id(`draft-${i}`).gap(1).cursor_pointer().rounded(4).hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => this.reveal(cm.path, cm.line, cm.side, cx))
          .child(div().text_size(10.5).text_color(t.dim).truncate().child(`${cm.path}${cm.line ? `:${cm.line}` : ""}`))
          .child(div().text_size(11).text_color(t.muted).child(plain(cm.body, 300)))))
        .child(div().text_size(10.5).text_color(t.dim).child("Only you can see this until it is submitted. Submit it with the buttons below, or discard it. Click a draft to see its line.")));
    } else {
      parts.push(this.section(t, "Your review", "no pending review · comment a line in Files to start one"));
    }
    const open = d.threads.filter((th) => !th.resolved).length;
    parts.push(this.section(t, "Threads", `${open} open · ${d.threads.length - open} resolved`));
    if (!d.threads.length) parts.push(div().px(12).pb(4).text_size(11).text_color(t.dim).child("No review threads"));
    else parts.push(...d.threads.map((th) => this.threadRow(t, th)));
    parts.push(this.section(t, "Reviews", d.reviews.length ? "" : "none yet"));
    parts.push(...d.reviews.map((rv) => h_flex().id(`review-${rv.author}`).h(22).flex_none().px(12).gap(6).items_center().text_size(11)
      .child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(rv.author))
      .child(this.chip(t, rv.state.toLowerCase().replace("_", " "), rv.state === "APPROVED" ? t.ansi2 : rv.state === "CHANGES_REQUESTED" ? t.ansi1 : t.dim))
      .child(div().flex_none().text_size(10.5).text_color(t.dim).child(age(rv.at)))));
    if (c.state !== "none") {
      parts.push(this.section(t, "Checks", `${c.ok} ok · ${c.failed} failed · ${c.pending} pending`));
      parts.push(...c.failing.slice(0, 10).map((name, i) => div().id(`failing-${i}`).px(12).h(20).flex_none().truncate().text_size(11).text_color(t.ansi1).child(name)));
    }
    parts.push(div().h(8).flex_none());
    return parts;
  }

  fileRow(t, f) {
    const s = this.state, on = s.file === f.path;
    const parts = f.path.split("/"), name = parts.pop();
    const drafts = (s.detail?.pending?.comments ?? []).filter((c) => c.path === f.path).length;
    const threads = (s.detail?.threads ?? []).filter((th) => th.path === f.path && !th.resolved).length;
    return h_flex().id(`file-${f.path}`).h(24).flex_none().px(8).gap(6).items_center().rounded(6).cursor_pointer().text_size(11.5)
      .when(on, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.pickFile(f.path, cx))
      .child(div().w(12).flex_none().text_size(10.5).text_color(t[STATUS[f.status]] ?? t.muted).child(f.status))
      .child(h_flex().flex_1().min_w(0).child(div().text_color(t.dim).truncate().child(parts.length ? parts.join("/") + "/" : "")).child(div().min_w(0).truncate().child(name)))
      .when(drafts > 0, (e) => e.child(this.chip(t, `${drafts} draft`, t.accent)))
      .when(threads > 0, (e) => e.child(this.chip(t, `${threads}`, t.ansi3)))
      .when(f.add > 0, (e) => e.child(div().text_size(10.5).text_color(t.ansi2).child(`+${f.add}`)))
      .when(f.del > 0, (e) => e.child(div().text_size(10.5).text_color(t.ansi1).child(`−${f.del}`)));
  }

  diffRow(t, row, marks, picked) {
    if (row.kind === "@") return div().w_full().px(12).h(18).flex_none().truncate().bg(t.raised).text_color(t.dim).child(row.text);
    if (row.kind === "") return div().w_full().px(12).h(18).flex_none().truncate().text_color(t.dim).child(row.text);
    const k = `${row.side}:${row.number}`, draft = marks.drafts.get(k), threads = marks.threads.get(k) ?? [];
    const on = picked && picked.number === row.number && picked.side === row.side;
    return h_flex().w_full().h(18).flex_none().gap(8).cursor_pointer()
      .when(row.kind === "+", (e) => e.bg(t.ansi2 + "18")).when(row.kind === "-", (e) => e.bg(t.ansi1 + "18"))
      .when(on, (e) => e.bg(t.accent + "33"))
      .hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => this.pickLine(row, cx))
      .child(div().w(34).flex_none().text_right().text_color(on ? t.accent : t.dim).child(String(row.number)))
      .child(div().w(8).flex_none().text_color(row.kind === "+" ? t.ansi2 : row.kind === "-" ? t.ansi1 : t.dim).child(row.kind.trim()))
      .when(Boolean(draft), (e) => e.child(this.chip(t, "draft", t.accent)))
      .when(threads.length > 0, (e) => e.child(this.chip(t, `${threads.length}`, threads.some((th) => !th.resolved) ? t.ansi3 : t.dim)))
      .child(div().flex_1().min_w(0).truncate().child(row.text));
  }

  filesView(t, r) {
    const s = this.state, files = s.diff ?? [];
    const file = files.find((f) => f.path === s.file) ?? null;
    const marks = file ? markersOf(s.detail, file.path) : null;
    const draft = this.draftAt(s), thread = s.line ? (marks?.threads.get(`${s.line.side}:${s.line.number}`) ?? [])[0] : null;
    const empty = s.diffError ? `Cannot load the diff: ${s.diffError}` : s.diffLoading && !files.length ? "Loading diff…" : !files.length ? "No changed files" : null;
    return [
      v_flex().id("pr-files").flex_none().h(Math.min(170, Math.max(40, files.length * 24 + 12))).overflow_y_scrollbar().p(6).border_b(1).border_color(t.border)
        .children(files.map((f) => this.fileRow(t, f)))
        .when(Boolean(empty), (e) => e.child(div().p(6).text_size(11).text_color(t.dim).child(empty))),
      div().flex_1().min_h(120).relative().font_family(settings().font_family ?? "JetBrains Mono").text_size(11)
        .when(Boolean(file), (e) => e
          .child(div().id("pr-diff-x").size_full().overflow_x_scrollbar()
            .child(div().w_full().min_w(file.width).h_full().child(v_virtual_list("pr-diff", file.rows.length, 18, (i) => String(i),
              (range) => file.rows.slice(range.start, range.end).map((row) => this.diffRow(t, row, marks, s.line))).track_scroll(this.scroll).size_full())))
          .child(Scrollbar.vertical("pr-diff").viewport_from_layout().absolute().inset_0()))
        .when(!file && files.length > 0, (e) => e.child(div().absolute().top(6).px(12).text_color(t.dim).child("Select a file to view its diff"))),
      s.line
        ? v_flex().flex_none().px(12).py(5).gap(2).border_t(1).border_color(t.border).text_size(11)
          .child(h_flex().gap(6).items_center()
            .child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(`${s.line.path}:${s.line.number}${s.line.side === "LEFT" ? " (old side)" : ""}`))
            .when(Boolean(draft), (e) => e.child(this.chip(t, "draft", t.accent)))
            .when(Boolean(thread), (e) => e.child(this.chip(t, thread.resolved ? "resolved thread" : "open thread", thread.resolved ? t.ansi2 : t.ansi3))))
          .when(Boolean(draft), (e) => e.child(div().text_color(t.muted).child(plain(draft.body, 300))))
          .when(Boolean(thread), (e) => e.child(div().text_color(t.muted).child(`${thread.author}: ${plain(thread.body, 300)}`)))
          .when(!draft && !thread, (e) => e.child(div().text_color(t.dim).child("Write the comment below and add it to your review")))
        : div().flex_none().px(12).py(5).border_t(1).border_color(t.border).text_size(11).text_color(t.dim).child(file ? "Click a line to comment on it" : ""),
    ];
  }

  // The bar's buttons for what is picked: an armed question, a diff line, a thread,
  // or the review itself.
  actions(t, s, row, d, ready, hasMessage) {
    const armed = s?.armed ?? null;
    if (armed && armed.number === s?.open) return v_flex().gap(6)
      .child(div().text_size(11.5).text_color(t.foreground).child(ACTIONS[armed.action].title))
      .child(div().text_size(11).text_color(t.muted).truncate().child(armed.detail ?? ""))
      .when(armed.action === "merge", (e) => e.child(h_flex().gap(4).children(MERGE_METHODS.map((m) =>
        div().id(`merge-${m}`).h(22).px(8).flex().items_center().rounded(6).text_size(11).cursor_pointer()
          .bg(this.mergeMethod === m ? t.selected : t.raised).text_color(this.mergeMethod === m ? t.foreground : t.muted)
          .hover((s) => s.bg(t.hover)).on_click((_e, cx) => { this.mergeMethod = m; cx.notify(); })
          .child(m[0].toUpperCase() + m.slice(1))))))
      .child(h_flex().gap(6)
        .child(this.button("confirm-yes", `Confirm ${ACTIONS[armed.action].label.toLowerCase()}`, (cx) => { const { action } = armed; s.armed = null; this.act(action, cx); }, true, ready))
        .child(this.button("confirm-no", "Cancel", (cx) => { s.armed = null; cx.notify(); })));
    if (s?.view === "files" && s.line) {
      const draft = this.draftAt(s);
      return h_flex().gap(6)
        .child(this.button("line-add", draft ? "Add another" : "Add to review", (cx) => this.act("add", cx), true, ready && hasMessage))
        .when(Boolean(draft), (e) => e.child(this.button("line-delete", "Delete draft", (cx) => this.act("delete", cx), false, ready)))
        .child(div().flex_1())
        .child(this.button("line-done", "Cancel", (cx) => { s.line = null; cx.notify(); }));
    }
    const thread = d?.threads.find((th) => th.id === s.thread);
    if (thread) return h_flex().gap(6)
      .child(this.button("thread-reply", "Reply", (cx) => this.act("reply", cx), true, ready && hasMessage))
      .child(this.button("thread-toggle", thread.resolved ? "Unresolve" : "Resolve", (cx) => this.act(thread.resolved ? "unresolve" : "resolve", cx), false, ready))
      .child(this.button("thread-show", "Show diff", (cx) => this.reveal(thread.path, thread.line, thread.side, cx), false, Boolean(thread.line)))
      .child(div().flex_1())
      .child(this.button("thread-done", "Back", (cx) => { s.thread = null; cx.notify(); }));
    return h_flex().gap(6)
      .child(this.button("pr-approve", "Approve", (cx) => this.arm("approve", cx, `#${row?.number} ${row?.title ?? ""}`), true, ready))
      .child(this.button("pr-comment", "Comment", (cx) => this.arm("comment", cx, `#${row?.number} ${row?.title ?? ""}`), false, ready && (hasMessage || Boolean(d?.pending))))
      .child(this.button("pr-changes", "Request changes", (cx) => this.arm("request_changes", cx, `#${row?.number} ${row?.title ?? ""}`), false, ready))
      .child(div().flex_1())
      .when(Boolean(d?.pending), (e) => e.child(this.button("pr-discard", "Discard", (cx) => this.arm("discard", cx, "The pending review and its draft comments are deleted."), false, ready)));
  }

  render(cx) {
    this.sync(cx);
    const t = theme(), { branch } = location();
    const s = this.state, rows = s?.rows ?? [];
    const row = s ? rows.find((r) => r.number === s.open) : null;
    const d = s?.detail ?? null;
    const ready = Boolean(row && d && !s.busy);
    const hasMessage = Boolean(s?.message.trim());
    const waiting = rows.filter((r) => r.requested).length, unsent = rows.filter((r) => r.pending).length;
    const loading = Boolean(s?.loading) || this.resolving === this.context;
    const error = this.error ?? s?.error ?? null;
    const empty = error || (loading ? "Loading pull requests…" : s ? "No open pull requests" : "No folder");
    const note = s?.note ?? null;
    const files = Boolean(row && s.view === "files");
    return v_flex().id("prs").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13).track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "escape" && this.typing) { this.typing = false; this.handle.focus(); cx.stop_propagation(); cx.notify(); }
      })
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Pull requests"))
        .child(div().px(5).py(1).rounded(4).border_1().border_color(t.border).text_size(10).text_color(t.muted).child(`${rows.length} open`))
        .when(waiting > 0, (e) => e.child(this.chip(t, `${waiting} for you`, t.blocked)))
        .when(unsent > 0, (e) => e.child(this.chip(t, `${unsent} unsent`, t.accent)))
        .child(div().flex_1())
        .when(Boolean(s?.repo), (e) => e.child(div().text_size(11).text_color(t.dim).truncate().max_w(140).child(s.repo)))
        .child(div().id("pr-refresh").size(22).flex().items_center().justify_center().rounded(6).text_color(t.dim).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_click((_e, cx) => this.sync(cx, true))
          .child(loading ? svg("mods/workspace-chrome/spinner.svg").size(13).text_color(t.working).spin(900) : div().text_size(14).child("↻"))))
      .child(v_flex().id("prs-list").flex_none().h(Math.min(row && files ? 120 : 200, Math.max(44, rows.length * 28 + 12))).overflow_y_scrollbar().p(6).border_b(1).border_color(t.border)
        .children(rows.map((r) => this.row(t, r, branch)))
        .when(!rows.length, (e) => e.child(div().p(8).text_color(t.dim).child(empty))))
      .when(Boolean(row), (e) => e.child(this.headerView(t, row)))
      .when(files, (e) => e.child(v_flex().id("prs-files").flex_1().min_h(0).children(this.filesView(t, row))))
      .when(!files, (e) => e.child(v_flex().id("prs-detail").flex_1().min_h(0).overflow_y_scrollbar()
        .when(Boolean(row), (e) => e.children(this.reviewView(t, row)))
        .when(!row && rows.length > 0, (e) => e.child(div().p(12).text_size(11).text_color(t.dim).child("Select a pull request to see its reviews")))))
      .when(Boolean(note), (e) => e.child(div().px(12).py(6).text_size(11).text_color(note.includes("failed") || note.startsWith("Cannot") ? t.ansi1 : t.ansi2).child(note)))
      .child(v_flex().flex_none().p(8).gap(6).border_t(1).border_color(t.border)
        .child(div().id("pr-message").w_full().min_h(32).px(10).py(6).flex().items_center().rounded(8).border_1().border_color(this.typing ? t.accent : t.border).cursor_text()
          .on_mouse_down("left", (_e, cx) => cx.stop_propagation()).child(Textarea.new(this.input).w_full().text_size(12).text_color(t.foreground)))
        .child(this.actions(t, s, row, d, ready, hasMessage)));
  }
}
