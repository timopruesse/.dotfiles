// Pull requests of the shown space's repo, beside Files and Changes: a list on top,
// the picked PR's pending review, threads, reviews and checks below, and a message
// bar that submits or discards a pending review, replies to and resolves threads.
// Outward-facing actions arm first and run on a second, explicit Confirm click.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { spaces, panes, focused, exec, theme } from "herdr";
import { rowsOf, sortRows, detailOf, reviewArgs, threadArgs, mergeArgs, plain, age, DETAIL_QUERY, DECISION, MERGE_METHODS } from "./prs.js";

function location() {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on, branch: pane?.branch ?? space?.branch ?? null };
}
const key = () => { const { cwd, on } = location(); return JSON.stringify({ cwd, on }); };
const LIST_FIELDS = "number,title,author,isDraft,reviewDecision,reviewRequests,headRefName,baseRefName,headRefOid,mergeable,mergeStateStatus,url,updatedAt,statusCheckRollup,additions,deletions";
const ACTIONS = {
  approve: { label: "Approve", title: "Approve this pull request?" },
  comment: { label: "Comment", title: "Submit a comment review?" },
  request_changes: { label: "Request changes", title: "Request changes on this pull request?" },
  discard: { label: "Discard", title: "Discard the pending review?" },
  checkout: { label: "Checkout", title: "Check out this pull request's branch?" },
  merge: { label: "Merge", title: "Merge this pull request?" },
};

export default class PullRequests extends View {
  init(_props, cx) {
    this.rows = []; this.detail = null; this.open = null; this.thread = null; this.message = "";
    this.handle = cx.focus_handle();
    this.teams = new Set(); this.viewer = null; this.repo = null; this.mergeMethod = "squash";
    this.input = InputState.new({ placeholder: "Review message or thread reply" });
    this.input.on("change", (_e, cx) => {
      const had = Boolean(this.message.trim());
      this.message = this.input.value();
      if (had !== Boolean(this.message.trim())) cx.notify();
    });
    this.input.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    this.identify(cx);
    this.refresh(cx);
    cx.timer.every(60000, (cx) => this.refresh(cx));
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
      this.rows = sortRows(rowsOf(this.raw ?? [], this.viewer, this.teams), location().branch);
      cx.notify();
    });
  }

  reset() {
    this.root = null; this.repo = null; this.raw = []; this.rows = []; this.detail = null; this.open = null; this.thread = null;
    this.error = null; this.note = null; this.armed = null; this.closed = false; this.message = ""; this.input.set_value("");
  }

  refresh(cx, force = false) {
    if (this.loading || (this.busy && !force)) return;
    const { cwd, on } = location(), context = key();
    if (context !== this.context) { this.context = context; this.reset(); }
    if (!cwd) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
        if (key() !== context) return;
        if (top.code !== 0) { this.reset(); this.error = "Not a git repository"; return; }
        const root = top.stdout.trim();
        if (!this.repo || this.root !== root) {
          const repo = await exec("gh", ["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], { cwd: root, on });
          if (key() !== context) return;
          if (repo.code !== 0) { this.reset(); this.root = root; this.error = plain(repo.stderr || "No GitHub repository for this checkout", 160); return; }
          this.repo = repo.stdout.trim();
        }
        const list = await exec("gh", ["pr", "list", "--state", "open", "--limit", "50", "--json", LIST_FIELDS], { cwd: root, on });
        if (key() !== context) return;
        if (list.code !== 0) throw new Error(plain(list.stderr || list.stdout, 200));
        this.root = root; this.on = on; this.raw = JSON.parse(list.stdout || "[]"); this.error = null;
        this.rows = sortRows(rowsOf(this.raw, this.viewer, this.teams), location().branch);
        if (this.open && !this.rows.some((r) => r.number === this.open)) { this.open = null; this.detail = null; this.thread = null; }
        if (!this.open && !this.closed && this.rows.length) this.open = this.rows[0].number;
        if (this.open) await this.load(this.open, context);
      } catch (e) {
        if (key() === context) this.error = e?.message ? String(e.message) : String(e);
      } finally { this.loading = false; cx.notify(); }
    });
  }

  async load(number, context) {
    const [owner, name] = (this.repo ?? "/").split("/");
    const r = await exec("gh", ["api", "graphql", "-f", `query=${DETAIL_QUERY}`, "-f", `owner=${owner}`, "-f", `name=${name}`, "-F", `number=${number}`], { cwd: this.root, on: this.on });
    if (key() !== context || this.open !== number) return;
    if (r.code !== 0) { this.detail = null; this.note = `Cannot load review details: ${plain(r.stderr || r.stdout, 200)}`; return; }
    this.detail = detailOf(JSON.parse(r.stdout));
    if (this.thread && !this.detail.threads.some((t) => t.id === this.thread)) this.thread = null;
  }

  pick(number, cx) {
    this.open = this.open === number ? null : number;
    this.closed = !this.open; this.detail = null; this.thread = null; this.note = null; this.armed = null;
    const context = this.context;
    if (this.open) cx.spawn(async (cx) => {
      try { await this.load(number, context); } catch (e) { if (key() === context) this.note = `Cannot load review details: ${e}`; }
      cx.notify();
    });
    cx.notify();
  }

  // Destructive or outward-facing actions ask first: the button row turns into
  // the question with Confirm and Cancel until one is clicked.
  arm(action, cx, detail) {
    if (this.busy) return;
    this.armed = { action, detail, number: this.open };
    cx.notify();
  }

  act(action, cx) {
    const row = this.rows.find((r) => r.number === this.open);
    if (!row || !this.repo || this.busy) return;
    const context = this.context, number = row.number;
    let args;
    try {
      if (action === "checkout") args = ["pr", "checkout", String(number)];
      else if (action === "merge") args = mergeArgs(this.mergeMethod, { number, headOid: row.headOid });
      else if (action === "open") args = ["pr", "view", String(number), "--web"];
      else if (action === "reply" || action === "resolve" || action === "unresolve") args = threadArgs(action, { id: this.thread, body: this.message });
      else args = reviewArgs(action, { repo: this.repo, number, pending: this.detail?.pending, body: this.message });
    } catch (e) { this.note = String(e.message ?? e); cx.notify(); return; }
    this.busy = true; this.note = null;
    cx.spawn(async (cx) => {
      try {
        const r = await exec("gh", args, { cwd: this.root, on: this.on });
        if (r.code !== 0) throw new Error(plain(r.stderr || r.stdout, 240));
        if (key() === context) {
          if (action === "reply" || action === "comment" || action === "approve" || action === "request_changes") { this.message = ""; this.input.set_value(""); }
          if (action === "merge") this.note = `Merged #${number} (${this.mergeMethod})`;
          else if (action !== "open") this.note = `${ACTIONS[action]?.label ?? "Done"}: #${number}`;
        }
      } catch (e) { if (key() === context) this.note = `${ACTIONS[action]?.label ?? action} failed: ${e.message ?? e}`; }
      finally {
        this.busy = false;
        if (action !== "open" && action !== "checkout" && action !== "merge" && this.open === number) { try { await this.load(number, context); } catch {} }
        if (action === "checkout" || action === "merge") this.refresh(cx, true);
        cx.notify();
      }
    });
    cx.notify();
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
    const on = this.open === r.number, here = branch && r.head === branch;
    const d = DECISION[r.decision];
    return h_flex().id(`pr-${r.number}`).h(28).flex_none().px(8).gap(6).items_center().rounded(7).cursor_pointer()
      .when(on, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.pick(r.number, cx))
      .child(div().w(36).flex_none().text_size(11).text_color(here ? t.accent : t.dim).child(`#${r.number}`))
      .child(div().flex_1().min_w(0).truncate().text_color(r.draft ? t.muted : t.foreground).child(r.title))
      .when(r.draft, (e) => e.child(this.chip(t, "draft", t.dim)))
      .when(r.conflicts, (e) => e.child(this.chip(t, "conflicts", t.ansi1)))
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

  threadRow(t, th) {
    const on = this.thread === th.id;
    return v_flex().id(`thread-${th.id}`).flex_none().px(12).py(5).gap(2).cursor_pointer()
      .when(on, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => { this.thread = on ? null : th.id; cx.notify(); })
      .child(h_flex().gap(6).items_center()
        .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(th.resolved ? t.dim : t.foreground).child(`${th.path}${th.line ? `:${th.line}` : ""}`))
        .when(th.outdated, (e) => e.child(this.chip(t, "outdated", t.dim)))
        .child(this.chip(t, th.resolved ? "resolved" : "open", th.resolved ? t.ansi2 : t.ansi3))
        .child(div().flex_none().text_size(10.5).text_color(t.dim).child(`${th.count}`)))
      .child(div().text_size(11).text_color(t.muted).child(`${th.author}: ${plain(th.body, on ? 600 : 140)}`));
  }

  detailView(t, r) {
    const d = this.detail;
    const meta = `${r.author} · ${r.head} → ${r.base}`;
    const c = r.checks;
    const parts = [v_flex().flex_none().px(12).pt(10).pb(6).gap(6)
      .child(div().text_size(12.5).font_semibold().child(r.title))
      .child(h_flex().gap(8).items_center().text_size(11).text_color(t.muted)
        .child(div().flex_1().min_w(0).truncate().child(meta))
        .when(Boolean(r.mergeState), (e) => e.child(div().text_color(r.conflicts ? t.ansi1 : t.dim).child(r.mergeState.toLowerCase())))
        .child(div().text_color(t.ansi2).child(`+${r.additions}`)).child(div().text_color(t.ansi1).child(`−${r.deletions}`)))
      .when(r.requests.length > 0, (e) => e.child(div().text_size(11).text_color(r.requested ? t.blocked : t.dim).child(`Review requested: ${r.requests.join(", ")}`)))
      .child(h_flex().gap(6).pt(2)
        .child(this.button("pr-open", "Open", (cx) => this.act("open", cx)))
        .child(this.button("pr-checkout", "Checkout", (cx) => this.arm("checkout", cx, `gh pr checkout ${r.number} in ${this.root}`), false, !this.busy))
        .child(div().flex_1())
        .child(this.button("pr-merge", "Merge", (cx) => this.arm("merge", cx, `#${r.number} ${r.title} into ${r.base}, guarded to ${r.headOid.slice(0, 7)}`), false, !this.busy && !r.draft && !r.conflicts && Boolean(r.headOid))))];
    if (!d) {
      parts.push(div().px(12).py(6).text_size(11).text_color(t.dim).child(this.note ?? "Loading review details…"));
      return parts;
    }
    if (d.pending) {
      parts.push(this.section(t, "Pending review", `${d.pending.comments.length} draft comment${d.pending.comments.length === 1 ? "" : "s"}`));
      parts.push(v_flex().flex_none().mx(8).p(8).gap(6).rounded(8).border_1().border_color(t.blocked + "66").bg(t.blocked + "12")
        .when(Boolean(d.pending.body.trim()), (e) => e.child(div().text_size(11).text_color(t.foreground).child(plain(d.pending.body, 400))))
        .children(d.pending.comments.map((cm, i) => v_flex().id(`draft-${i}`).gap(1)
          .child(div().text_size(10.5).text_color(t.dim).truncate().child(`${cm.path}${cm.line ? `:${cm.line}` : ""}`))
          .child(div().text_size(11).text_color(t.muted).child(plain(cm.body, 300)))))
        .child(div().text_size(10.5).text_color(t.dim).child("Only you can see this until it is submitted. Submit it with the buttons below, or discard it.")));
    } else {
      parts.push(this.section(t, "Your review", "no pending review"));
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

  render(cx) {
    if (key() !== this.context) this.refresh(cx);
    const t = theme(), { branch } = location();
    const row = this.rows.find((r) => r.number === this.open);
    const d = this.detail;
    const thread = d?.threads.find((th) => th.id === this.thread);
    const ready = Boolean(row && d && !this.busy);
    const hasMessage = Boolean(this.message.trim());
    const waiting = this.rows.filter((r) => r.requested).length;
    return v_flex().id("prs").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13).track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "escape" && this.typing) { this.typing = false; this.handle.focus(); cx.stop_propagation(); cx.notify(); }
      })
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Pull requests"))
        .child(div().px(5).py(1).rounded(4).border_1().border_color(t.border).text_size(10).text_color(t.muted).child(`${this.rows.length} open`))
        .when(waiting > 0, (e) => e.child(this.chip(t, `${waiting} for you`, t.blocked)))
        .child(div().flex_1())
        .when(Boolean(this.repo), (e) => e.child(div().text_size(11).text_color(t.dim).truncate().max_w(140).child(this.repo)))
        .child(div().id("pr-refresh").size(22).flex().items_center().justify_center().rounded(6).text_color(t.dim).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_click((_e, cx) => this.refresh(cx, true))
          .child(this.loading ? svg("mods/workspace-chrome/spinner.svg").size(13).text_color(t.working).spin(900) : div().text_size(14).child("↻"))))
      .child(v_flex().id("prs-list").flex_none().h(Math.min(200, Math.max(44, this.rows.length * 28 + 12))).overflow_y_scrollbar().p(6).border_b(1).border_color(t.border)
        .children(this.rows.map((r) => this.row(t, r, branch)))
        .when(!this.rows.length, (e) => e.child(div().p(8).text_color(t.dim).child(this.error || (this.loading ? "Loading pull requests…" : this.repo ? "No open pull requests" : "No folder")))))
      .child(v_flex().id("prs-detail").flex_1().min_h(0).overflow_y_scrollbar()
        .when(Boolean(row), (e) => e.children(this.detailView(t, row)))
        .when(!row && this.rows.length > 0, (e) => e.child(div().p(12).text_size(11).text_color(t.dim).child("Select a pull request to see its reviews"))))
      .when(Boolean(this.note), (e) => e.child(div().px(12).py(6).text_size(11).text_color(this.note.includes("failed") || this.note.startsWith("Cannot") ? t.ansi1 : t.ansi2).child(this.note)))
      .child(v_flex().flex_none().p(8).gap(6).border_t(1).border_color(t.border)
        .child(div().id("pr-message").w_full().h(32).px(10).flex().items_center().rounded(8).border_1().border_color(this.typing ? t.accent : t.border).cursor_text()
          .on_mouse_down("left", (_e, cx) => cx.stop_propagation()).child(Input.new(this.input).h_full().text_size(12).text_color(t.foreground)))
        .child(this.armed && this.armed.number === this.open
          ? v_flex().gap(6)
            .child(div().text_size(11.5).text_color(t.foreground).child(ACTIONS[this.armed.action].title))
            .child(div().text_size(11).text_color(t.muted).truncate().child(this.armed.detail ?? ""))
            .when(this.armed.action === "merge", (e) => e.child(h_flex().gap(4).children(MERGE_METHODS.map((m) =>
              div().id(`merge-${m}`).h(22).px(8).flex().items_center().rounded(6).text_size(11).cursor_pointer()
                .bg(this.mergeMethod === m ? t.selected : t.raised).text_color(this.mergeMethod === m ? t.foreground : t.muted)
                .hover((s) => s.bg(t.hover)).on_click((_e, cx) => { this.mergeMethod = m; cx.notify(); })
                .child(m[0].toUpperCase() + m.slice(1))))))
            .child(h_flex().gap(6)
              .child(this.button("confirm-yes", `Confirm ${ACTIONS[this.armed.action].label.toLowerCase()}`, (cx) => { const { action } = this.armed; this.armed = null; this.act(action, cx); }, true, ready))
              .child(this.button("confirm-no", "Cancel", (cx) => { this.armed = null; cx.notify(); })))
          : thread
          ? h_flex().gap(6)
            .child(this.button("thread-reply", "Reply", (cx) => this.act("reply", cx), true, ready && hasMessage))
            .child(this.button("thread-toggle", thread.resolved ? "Unresolve" : "Resolve", (cx) => this.act(thread.resolved ? "unresolve" : "resolve", cx), false, ready))
            .child(div().flex_1())
            .child(this.button("thread-done", "Back", (cx) => { this.thread = null; cx.notify(); }))
          : h_flex().gap(6)
            .child(this.button("pr-approve", "Approve", (cx) => this.arm("approve", cx, `#${row?.number} ${row?.title ?? ""}`), true, ready))
            .child(this.button("pr-comment", "Comment", (cx) => this.arm("comment", cx, `#${row?.number} ${row?.title ?? ""}`), false, ready && (hasMessage || Boolean(d?.pending))))
            .child(this.button("pr-changes", "Request changes", (cx) => this.arm("request_changes", cx, `#${row?.number} ${row?.title ?? ""}`), false, ready))
            .child(div().flex_1())
            .when(Boolean(d?.pending), (e) => e.child(this.button("pr-discard", "Discard", (cx) => this.arm("discard", cx, "The pending review and its draft comments are deleted."), false, ready)))));
  }
}
