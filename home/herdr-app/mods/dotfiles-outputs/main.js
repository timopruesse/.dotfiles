// Outputs of the focused pane's agent session, beside Files, Changes and PRs: the files
// it wrote or edited and the artifacts it published, newest first. The transcript comes
// from the terminal's `agent.transcript` label, which the hc-session-label hooks set for
// Claude Code and Pi. Click a file to preview it read-only; click an artifact to open it.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState } from "gpui-base";
import { spaces, panes, focused, terminals, exec, readTextFile, theme, settings, window } from "herdr";
import { sessionOf, filterScript, parseOutputs, nameOf, placeOf, age } from "./outputs.js";

const LANG = { ts: "js", tsx: "js", mts: "js", cts: "js", jsx: "js", mjs: "js", toml: "yaml", jsonc: "json", svelte: "html", vue: "html" };
const COLOR = { wrote: "ansi2", edited: "ansi3", published: "ansi4" };

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
    this.rows = []; this.file = null; this.code = null;
    this.refresh(cx);
    cx.timer.every(15000, (cx) => this.refresh(cx));
  }

  reset() {
    this.rows = []; this.error = null; this.file = null; this.fileError = null; this.code?.release(); this.code = null;
  }

  refresh(cx, force = false) {
    if (this.loading && !force) return;
    const context = key(), where = location();
    if (context !== this.context) { this.context = context; this.reset(); }
    this.where = where;
    if (!where.session) { this.rows = []; this.loading = false; cx.notify(); return; }
    if (window()?.platform === "windows" && !where.on) { this.error = "Transcripts on a Windows host are not read yet"; cx.notify(); return; }
    this.loading = true;
    const { session, on, cwd } = where;
    cx.spawn(async (cx) => {
      try {
        const r = await exec("sh", ["-c", filterScript(session.kind), "outputs", session.transcript], { on });
        if (key() !== context) return;
        if (r.code !== 0) { this.error = r.stderr.trim() ? r.stderr.trim().split("\n")[0].slice(0, 160) : "Transcript is not readable"; this.rows = []; return; }
        this.error = null;
        this.rows = parseOutputs(r.stdout, session.kind, cwd);
        this.read = Date.now();
      } catch (e) {
        if (key() === context) { this.error = String(e?.message ?? e).slice(0, 160); this.rows = []; }
      } finally { if (key() === context) this.loading = false; cx.notify(); }
    });
  }

  open(row, cx) {
    if (row.kind === "artifact") {
      try { if (typeof cx?.open_url === "function") { cx.open_url(row.url); return; } } catch {}
      cx.spawn(async () => { try { await exec("xdg-open", [row.url]); } catch {} });
      return;
    }
    this.show(row.path, cx);
  }

  show(path, cx) {
    this.code?.release(); this.code = null; this.file = path; this.fileError = null;
    if (!path || !cx) return;
    const context = this.context, on = this.where?.on ?? null;
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(path, { on });
        if (this.file !== path || this.context !== context) return;
        if (text === null) { this.fileError = "This file is no longer available"; return; }
        if (text.includes("\0")) { this.fileError = "Binary file · no text preview"; return; }
        const t = theme(), ext = path.includes(".") ? path.split(".").pop() : "txt";
        this.code = EditorState.new({ language: LANG[ext] ?? ext, readonly: true,
          value: text.length > 400000 ? text.slice(0, 400000) + "\n… (file truncated)" : text,
          font_family: settings().font_family, font_size: 12,
          syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 } });
      } catch { if (this.file === path && this.context === context) this.fileError = "Cannot preview this file (binary, too large, or unreadable)"; }
      finally { cx.notify(); }
    });
  }

  row(row, t, cwd) {
    const artifact = row.kind === "artifact";
    return h_flex().id(`output-${artifact ? row.url : row.path}`).h(34).flex_none().px(8).gap(8).items_center().rounded(7).cursor_pointer().hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => this.open(row, cx))
      .child(svg(artifact ? "mods/dotfiles-outputs/outputs.svg" : "mods/files/file.svg").size(14).flex_none().text_color(t.muted))
      .child(v_flex().flex_1().min_w(0).gap(1)
        .child(div().truncate().child(nameOf(row)))
        .child(div().truncate().text_size(11).text_color(t.dim).child(placeOf(row, cwd))))
      .when(row.count > 1, (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child(`×${row.count}`)))
      .child(div().flex_none().text_size(11).text_color(t[COLOR[row.action]] ?? t.muted).child(row.action))
      .child(div().flex_none().w(28).text_right().text_size(11).text_color(t.dim).child(age(row.at)));
  }

  render(cx) {
    if (key() !== this.context) this.refresh(cx);
    const t = theme(), where = this.where ?? location(), session = where.session;
    const agent = session?.kind === "claude" ? "Claude Code" : session?.kind === "pi" ? "Pi" : null;
    const empty = !where.terminal ? "No terminal focused"
      : !session ? "No agent session recorded in this pane. Start pi or claude here; the hc-session-label hook records its transcript."
      : this.error ? this.error : this.loading && !this.rows.length ? "Reading transcript…" : !this.rows.length ? "Nothing written or published yet" : null;
    const stop = (_e, cx) => cx.stop_propagation();
    return v_flex().id("outputs").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .when(Boolean(this.file), (el) => el.child(div().id("outputs-back").w(20).cursor_pointer().text_color(t.muted).on_click((_e, cx) => { this.show(null); cx.notify(); }).child("←")))
        .child(div().font_semibold().child("Outputs"))
        .child(div().flex_1().min_w(0).truncate().text_right().text_size(12).text_color(t.dim)
          .child(this.file ?? (agent ? `${agent}${this.rows.length ? ` · ${this.rows.length}` : ""}` : "")))
        .when(!this.file && Boolean(session), (el) => el.child(div().id("outputs-refresh").size(22).flex_none().flex().items_center().justify_center().rounded(6).cursor_pointer().text_color(t.dim)
          .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_mouse_down("left", stop).on_click((_e, cx) => this.refresh(cx, true)).child("↻"))))
      .when(!this.file, (el) => el.child(v_flex().id("outputs-list").flex_1().min_h(0).overflow_y_scrollbar().p(6)
        .children(this.rows.map((row) => this.row(row, t, where.cwd)))
        .when(Boolean(empty), (el) => el.child(div().p(8).text_size(12).text_color(t.dim).child(empty)))))
      .when(Boolean(this.file), (el) => el.child(this.code ? Editor.new(this.code).flex_1().min_h(0) : div().p(12).text_color(t.dim).child(this.fileError || "Loading file…")));
  }
}
