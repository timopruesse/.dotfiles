// Outputs of the focused pane's agent session that Changes does not show: diagrams it
// drew (Mermaid, PlantUML, Graphviz, D2 blocks in replies or written files), pages it
// published, images it made, and files outside the checkout or ignored by git. Files
// tracked in the checkout are left to Changes. The transcript comes from the terminal's
// `agent.transcript` label, which the hc-session-label hooks set for Claude Code and Pi.
// Click a diagram to read its source and open it rendered in the Mermaid live editor;
// click a file for a read-only preview, an image or an artifact to open it outside.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState } from "gpui-base";
import { spaces, panes, focused, terminals, exec, readTextFile, theme, settings, window } from "herdr";
import { sessionOf, filterScript, parseOutputs, nameOf, placeOf, age, mermaidUrl, insideOf } from "./outputs.js";

const LANG = { ts: "js", tsx: "js", mts: "js", cts: "js", jsx: "js", mjs: "js", toml: "yaml", jsonc: "json", svelte: "html", vue: "html" };
const COLOR = { wrote: "ansi2", edited: "ansi3", published: "ansi4", drew: "ansi5" };
const ICON = { artifact: "mods/dotfiles-outputs/outputs.svg", diagram: "mods/dotfiles-outputs/diagram.svg", image: "mods/files/file.svg", file: "mods/files/file.svg" };
const CHECK_IGNORE_MAX = 300;

function location() {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  const terminal = f?.terminal ?? pane?.terminal ?? null;
  const on = f?.pane === null ? (terminal?.includes("/") ? terminal.split("/")[0] : null) : space?.machine ?? null;
  const record = terminal ? terminals().find((t) => t.address === terminal || (on && `${on}/${t.address}` === terminal)) ?? null : null;
  return { terminal, on, record, cwd: record?.cwd || pane?.cwd || f?.cwd || space?.folder || null, session: sessionOf(record) };
}
const key = () => { const { terminal, on, session } = location(); return JSON.stringify({ terminal, on, transcript: session?.transcript ?? null }); };

export default class Outputs extends View {
  init(_props, cx) {
    this.rows = []; this.hidden = 0; this.open = null; this.code = null;
    this.refresh(cx);
    cx.timer.every(15000, (cx) => this.refresh(cx));
  }

  reset() {
    this.rows = []; this.hidden = 0; this.error = null; this.open = null; this.fileError = null; this.code?.release(); this.code = null;
  }

  refresh(cx, force = false) {
    if (this.loading && !force) return;
    const context = key(), where = location();
    if (context !== this.context) { this.context = context; this.reset(); }
    this.where = where;
    if (!where.session) { this.rows = []; this.hidden = 0; this.loading = false; cx.notify(); return; }
    if (window()?.platform === "windows" && !where.on) { this.error = "Transcripts on a Windows host are not read yet"; cx.notify(); return; }
    this.loading = true;
    const { session, on, cwd } = where;
    cx.spawn(async (cx) => {
      try {
        const r = await exec("sh", ["-c", filterScript(session.kind), "outputs", session.transcript], { on });
        if (key() !== context) return;
        if (r.code !== 0) { this.error = r.stderr.trim() ? r.stderr.trim().split("\n")[0].slice(0, 160) : "Transcript is not readable"; this.rows = []; return; }
        this.error = null;
        const { rows, hidden } = await this.narrow(parseOutputs(r.stdout, session.kind, cwd), cwd, on);
        if (key() !== context) return;
        this.rows = rows; this.hidden = hidden;
        this.read = Date.now();
      } catch (e) {
        if (key() === context) { this.error = String(e?.message ?? e).slice(0, 160); this.rows = []; }
      } finally { if (key() === context) this.loading = false; cx.notify(); }
    });
  }

  // Drops the files Changes already shows: inside the checkout and not ignored by git.
  // Outside a checkout, or when git cannot answer, every file stays.
  async narrow(rows, cwd, on) {
    const paths = rows.filter((r) => r.kind === "file" || r.kind === "image").map((r) => r.path);
    if (!cwd || !paths.length) return { rows, hidden: 0 };
    let root = null;
    try {
      const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
      if (top.code === 0) root = top.stdout.trim() || null;
    } catch {}
    if (!root) return { rows, hidden: 0 };
    const inside = paths.filter((p) => insideOf(p, root)).slice(0, CHECK_IGNORE_MAX);
    const ignored = new Set();
    if (inside.length) {
      try {
        const r = await exec("git", ["-C", root, "check-ignore", "-z", "--no-index", "--", ...inside], { cwd: root, on });
        if (r.code === 0 || r.code === 1) for (const p of r.stdout.split("\0")) if (p) ignored.add(insideOf(p, root) ? p : `${root}/${p}`);
      } catch {}
    }
    const kept = rows.filter((r) => (r.kind !== "file" && r.kind !== "image") || !insideOf(r.path, root) || ignored.has(r.path));
    return { rows: kept, hidden: rows.length - kept.length };
  }

  click(row, cx) {
    if (row.kind === "artifact") { this.launch(row.url, cx); return; }
    if (row.kind === "image") {
      // The host's image element reads the app's own folder; an image opens outside instead.
      if (this.where?.on) { this.error = "Images on another machine open there, not here"; cx.notify(); return; }
      cx.spawn(async () => { try { await exec("xdg-open", [row.path]); } catch {} });
      return;
    }
    this.show(row, cx);
  }

  launch(url, cx) {
    try { if (typeof cx?.open_url === "function") { cx.open_url(url); return; } } catch {}
    cx.spawn(async () => { try { await exec("xdg-open", [url]); } catch {} });
  }

  // The preview: a diagram's source or a file's text.
  show(row, cx) {
    this.code?.release(); this.code = null; this.open = row; this.fileError = null;
    if (!row || !cx) return;
    const t = theme(), font = settings().font_family;
    if (row.kind === "diagram") {
      this.code = EditorState.new({ language: row.lang === "graphviz" ? "c" : "yaml", readonly: true, value: row.code, font_family: font, font_size: 12,
        syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 } });
      cx.notify();
      return;
    }
    const context = this.context, on = this.where?.on ?? null, path = row.path;
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(path, { on });
        if (this.open !== row || this.context !== context) return;
        if (text === null) { this.fileError = "This file is no longer available"; return; }
        if (text.includes("\0")) { this.fileError = "Binary file · no text preview"; return; }
        const ext = path.includes(".") ? path.split(".").pop() : "txt";
        this.code = EditorState.new({ language: LANG[ext] ?? ext, readonly: true,
          value: text.length > 400000 ? text.slice(0, 400000) + "\n… (file truncated)" : text,
          font_family: font, font_size: 12,
          syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 } });
      } catch { if (this.open === row && this.context === context) this.fileError = "Cannot preview this file (binary, too large, or unreadable)"; }
      finally { cx.notify(); }
    });
  }

  rowId(row) { return row.kind === "artifact" ? row.url : row.kind === "diagram" ? `diagram-${row.lang}-${row.title}-${row.at}` : row.path; }

  row(row, t, cwd) {
    return h_flex().id(`output-${this.rowId(row)}`).h(34).flex_none().px(8).gap(8).items_center().rounded(7).cursor_pointer().hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => this.click(row, cx))
      .child(svg(ICON[row.kind]).size(14).flex_none().text_color(row.kind === "diagram" ? t.ansi5 : t.muted))
      .child(v_flex().flex_1().min_w(0).gap(1)
        .child(div().truncate().child(nameOf(row)))
        .child(div().truncate().text_size(11).text_color(t.dim).child(placeOf(row, cwd))))
      .when(row.count > 1, (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child(`×${row.count}`)))
      .child(div().flex_none().text_size(11).text_color(t[COLOR[row.action]] ?? t.muted).child(row.action))
      .child(div().flex_none().w(28).text_right().text_size(11).text_color(t.dim).child(age(row.at)));
  }

  preview(t) {
    if (this.code) return Editor.new(this.code).flex_1().min_h(0);
    return div().p(12).text_color(t.dim).child(this.fileError || "Loading…");
  }

  render(cx) {
    if (key() !== this.context) this.refresh(cx);
    const t = theme(), where = this.where ?? location(), session = where.session;
    const agent = session?.kind === "claude" ? "Claude Code" : session?.kind === "pi" ? "Pi" : null;
    const empty = !where.terminal ? "No terminal focused"
      : !session ? "No agent session recorded in this pane. Start pi or claude here; the hc-session-label hook records its transcript."
      : this.error ? this.error : this.loading && !this.rows.length ? "Reading transcript…"
      : !this.rows.length ? (this.hidden ? "Nothing beyond the checkout's changes yet" : "Nothing drawn, published, or written yet") : null;
    const stop = (_e, cx) => cx.stop_propagation();
    const open = this.open;
    const title = open ? (open.kind === "diagram" ? `${open.lang} · ${open.title}` : open.path) : agent ? `${agent}${this.rows.length ? ` · ${this.rows.length}` : ""}` : "";
    return v_flex().id("outputs").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .when(Boolean(open), (el) => el.child(div().id("outputs-back").w(20).cursor_pointer().text_color(t.muted).on_click((_e, cx) => { this.show(null); cx.notify(); }).child("←")))
        .child(div().font_semibold().child("Outputs"))
        .child(div().flex_1().min_w(0).truncate().text_right().text_size(12).text_color(t.dim).child(title))
        .when(open?.kind === "diagram" && open.lang === "mermaid", (el) => el.child(div().id("outputs-render").h(24).px(9).flex_none().flex().items_center().rounded(6).cursor_pointer().text_size(11.5).bg(t.raised).text_color(t.foreground)
          .hover((s) => s.opacity(0.85)).on_mouse_down("left", stop).on_click((_e, cx) => this.launch(mermaidUrl(open.code, settings().appearance !== "light"), cx)).child("Render")))
        .when(!open && Boolean(session), (el) => el.child(div().id("outputs-refresh").size(22).flex_none().flex().items_center().justify_center().rounded(6).cursor_pointer().text_color(t.dim)
          .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_mouse_down("left", stop).on_click((_e, cx) => this.refresh(cx, true)).child("↻"))))
      .when(!open, (el) => el.child(v_flex().id("outputs-list").flex_1().min_h(0).overflow_y_scrollbar().p(6)
        .children(this.rows.map((row) => this.row(row, t, where.cwd)))
        .when(Boolean(empty), (el) => el.child(div().p(8).text_size(12).text_color(t.dim).child(empty)))))
      .when(!open && this.hidden > 0, (el) => el.child(div().flex_none().px(14).py(6).border_t(1).border_color(t.border).text_size(11).text_color(t.dim)
        .child(`${this.hidden} changed file${this.hidden === 1 ? "" : "s"} in the checkout: see Changes`)))
      .when(Boolean(open), (el) => el.child(this.preview(t)));
  }
}
