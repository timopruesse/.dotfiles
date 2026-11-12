// Pure helpers for the Outputs panel: which transcript a terminal's labels point at,
// the grep that narrows it, and the parser that turns transcript lines into rows.
// No host imports, so node tests load this exact file.

export const LABELS = { kind: "agent.kind", transcript: "agent.transcript", session: "agent.session" };
export const EDIT_TOOLS = { Write: "wrote", Edit: "edited", MultiEdit: "edited", NotebookEdit: "edited" };
const ARTIFACT_URL = /https:\/\/claude\.ai\/(?:code\/)?artifact\/[A-Za-z0-9_-]+/g;
// Fenced code languages that are diagrams, and the files that hold one whole.
export const DIAGRAM_LANGS = { mermaid: "mermaid", mmd: "mermaid", plantuml: "plantuml", puml: "plantuml", dot: "graphviz", graphviz: "graphviz", d2: "d2" };
const DIAGRAM_FILES = { mmd: "mermaid", mermaid: "mermaid", puml: "plantuml", plantuml: "plantuml", dot: "graphviz", gv: "graphviz", d2: "d2" };
const FENCE = /```[ \t]*(mermaid|mmd|plantuml|puml|dot|graphviz|d2)\b[^\n]*\n([\s\S]*?)```/g;
const FENCE_GREP = "```[ \\t]*(mermaid|mmd|plantuml|puml|dot|graphviz|d2)";
export const IMAGE = /\.(png|jpe?g|gif|webp|svg|bmp|avif)$/i;

// A session from a terminal record's labels (set by the hc-session-label hooks). The
// kind falls back to the transcript's folder when the label is missing.
export function sessionOf(terminal) {
  const labels = terminal?.labels ?? {};
  const transcript = labels[LABELS.transcript];
  if (typeof transcript !== "string" || !transcript) return null;
  let kind = labels[LABELS.kind];
  if (kind !== "claude" && kind !== "pi") kind = /[\\/]\.claude[\\/]/.test(transcript) ? "claude" : /[\\/]\.pi[\\/]/.test(transcript) ? "pi" : null;
  if (!kind) return null;
  return { kind, transcript, session: labels[LABELS.session] || null };
}

// The shell pipeline that keeps only the transcript lines the parser reads. Claude Code
// transcripts also hold request blobs and prompt snapshots that mention every tool name,
// so those are dropped by their line shape before the name match. Output is bounded.
export function filterScript(kind) {
  const tail = "tail -c 6000000";
  if (kind === "claude") {
    return `grep -E '^\\{"parentUuid":' -- "$1" | grep -vF '"attachment":{' | grep -E '"name":"(Write|Edit|MultiEdit|NotebookEdit|Artifact)"|claude\\.ai/(code/)?artifact/|"type":"assistant".*${FENCE_GREP}' | ${tail}; test -r "$1"`;
  }
  return `grep -E '^\\{"type":"session"|"type":"toolCall","id":"[^"]*","name":"(write|edit)"|"role":"assistant".*${FENCE_GREP}' -- "$1" | ${tail}; test -r "$1"`;
}

// Fenced diagram blocks in a reply or a written file, with their language.
export function diagramsIn(text) {
  const out = [];
  for (const m of String(text ?? "").matchAll(FENCE)) {
    const code = m[2].replace(/\s+$/, "");
    if (code.trim()) out.push({ lang: DIAGRAM_LANGS[m[1].toLowerCase()], code });
  }
  return out;
}

// A whole file that is a diagram (by its extension), else the blocks inside it.
export function diagramsOfFile(path, content) {
  const ext = (path ?? "").split(".").pop().toLowerCase();
  const lang = DIAGRAM_FILES[ext];
  if (lang) return String(content ?? "").trim() ? [{ lang, code: String(content).replace(/\s+$/, "") }] : [];
  return diagramsIn(content);
}

// The diagram's own first meaningful line: "flowchart LR", "@startuml", "digraph G {".
export function diagramTitle(code) {
  const line = String(code ?? "").split("\n").map((l) => l.trim()).find((l) => l && !l.startsWith("%%") && !l.startsWith("//") && !l.startsWith("#"));
  return (line ?? "diagram").slice(0, 60);
}

// URL-safe base64 of UTF-8 text, for hosts without btoa.
export function base64url(text) {
  const bytes = [];
  for (const ch of String(text ?? "")) {
    let cp = ch.codePointAt(0);
    if (cp < 0x80) bytes.push(cp);
    else if (cp < 0x800) bytes.push(0xc0 | (cp >> 6), 0x80 | (cp & 0x3f));
    else if (cp < 0x10000) bytes.push(0xe0 | (cp >> 12), 0x80 | ((cp >> 6) & 0x3f), 0x80 | (cp & 0x3f));
    else bytes.push(0xf0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3f), 0x80 | ((cp >> 6) & 0x3f), 0x80 | (cp & 0x3f));
  }
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
  let out = "";
  for (let i = 0; i < bytes.length; i += 3) {
    const n = (bytes[i] << 16) | ((bytes[i + 1] ?? 0) << 8) | (bytes[i + 2] ?? 0);
    out += alphabet[n >> 18] + alphabet[(n >> 12) & 63] + (i + 1 < bytes.length ? alphabet[(n >> 6) & 63] : "") + (i + 2 < bytes.length ? alphabet[n & 63] : "");
  }
  return out;
}

// The diagram rendered in the Mermaid live editor: its state in the URL hash, nothing uploaded.
export function mermaidUrl(code, dark = true) {
  const state = { code, mermaid: JSON.stringify({ theme: dark ? "dark" : "default" }), updateDiagram: true, rough: false };
  return `https://mermaid.live/edit#base64:${base64url(JSON.stringify(state))}`;
}

// Whether a path lies in the checkout, so Changes would show it.
export function insideOf(path, root) {
  if (!root) return false;
  const r = posix(root).replace(/\/$/, ""), p = posix(path);
  return p === r || p.startsWith(`${r}/`);
}

const when = (record) => { const t = Date.parse(record?.timestamp ?? ""); return Number.isFinite(t) ? t : 0; };
const posix = (p) => p.replace(/\\/g, "/");
const join = (cwd, p) => (!p ? null : /^([A-Za-z]:)?\//.test(posix(p)) ? posix(p) : cwd ? `${posix(cwd).replace(/\/$/, "")}/${posix(p)}` : posix(p));

// Rows from transcript lines, newest first; one row per path with how often it was
// touched, plus one row per published artifact. `cwd` resolves Pi's relative paths
// when the transcript has no session line.
export function parseOutputs(text, kind, cwd = null) {
  const files = new Map(), artifacts = new Map(), diagrams = new Map(), pending = new Map();
  let base = cwd;
  const touch = (path, action, at) => {
    if (!path) return;
    const row = files.get(path);
    if (row) { row.count += 1; if (at >= row.at) { row.at = at; row.action = action; } }
    else files.set(path, { kind: IMAGE.test(path) ? "image" : "file", path, action, at, count: 1 });
  };
  // One row per distinct diagram; the same one drawn again counts up and keeps its latest place.
  const draw = (found, path, at) => {
    for (const { lang, code } of found) {
      const id = `${lang}\n${code.replace(/\s+/g, " ").trim()}`, row = diagrams.get(id);
      if (row) { row.count += 1; if (at >= row.at) { row.at = at; row.path = path ?? row.path; } }
      else diagrams.set(id, { kind: "diagram", lang, code, title: diagramTitle(code), path, action: "drew", at, count: 1 });
    }
  };
  for (const line of String(text ?? "").split("\n")) {
    if (!line.startsWith("{")) continue;
    let record;
    try { record = JSON.parse(line); } catch { continue; }
    if (kind === "pi") {
      if (record.type === "session" && typeof record.cwd === "string") { base = record.cwd; continue; }
      if (record.type !== "message" || record.message?.role !== "assistant" || !Array.isArray(record.message.content)) continue;
      for (const block of record.message.content) {
        if (block?.type === "text") { draw(diagramsIn(block.text), null, when(record)); continue; }
        if (block?.type !== "toolCall") continue;
        if (block.name === "write") {
          const path = join(base, block.arguments?.path);
          touch(path, "wrote", when(record));
          draw(diagramsOfFile(path, block.arguments?.content), path, when(record));
        } else if (block.name === "edit") touch(join(base, block.arguments?.path), "edited", when(record));
      }
      continue;
    }
    const content = record.message?.content;
    if (!Array.isArray(content)) continue;
    if (record.type === "assistant") {
      for (const block of content) {
        if (block?.type === "text") { draw(diagramsIn(block.text), null, when(record)); continue; }
        if (block?.type !== "tool_use") continue;
        const action = EDIT_TOOLS[block.name];
        if (action) {
          const path = join(base, block.input?.file_path ?? block.input?.notebook_path);
          touch(path, action, when(record));
          if (block.name === "Write") draw(diagramsOfFile(path, block.input?.content), path, when(record));
        }
        else if (block.name === "Artifact" && (block.input?.action ?? "publish") === "publish" && !block.input?.asset) {
          pending.set(block.id, { at: when(record), file: block.input?.file_path ? join(base, block.input.file_path) : null, title: block.input?.title ?? null });
        }
      }
    } else if (record.type === "user") {
      for (const block of content) {
        if (block?.type !== "tool_result" || !pending.has(block.tool_use_id)) continue;
        const use = pending.get(block.tool_use_id); pending.delete(block.tool_use_id);
        const body = typeof block.content === "string" ? block.content : JSON.stringify(block.content ?? "");
        const url = body.match(ARTIFACT_URL)?.[0];
        if (!url || block.is_error) continue;
        const at = Math.max(use.at, when(record)), row = artifacts.get(url);
        if (row) { row.count += 1; if (at >= row.at) { row.at = at; row.path = use.file ?? row.path; } }
        else artifacts.set(url, { kind: "artifact", url, path: use.file, title: use.title, action: "published", at, count: 1 });
      }
    }
  }
  const label = (r) => r.path ?? r.url ?? r.title ?? "";
  return [...artifacts.values(), ...diagrams.values(), ...files.values()].sort((a, b) => b.at - a.at || label(a).localeCompare(label(b)));
}

export function nameOf(row) {
  if (row.kind === "artifact") return row.title || row.url.split("/").pop();
  if (row.kind === "diagram") return row.title;
  return row.path.split("/").pop() || row.path;
}

export function placeOf(row, cwd) {
  if (row.kind === "artifact") return row.url.replace(/^https:\/\//, "");
  if (row.kind === "diagram" && !row.path) return `${row.lang} · in a reply`;
  if (row.kind === "diagram") return `${row.lang} · ${placeOf({ kind: "file", path: row.path }, cwd)}/${row.path.split("/").pop()}`.replace("· ./", "· ");
  const dir = row.path.slice(0, Math.max(0, row.path.lastIndexOf("/")));
  const root = cwd ? posix(cwd).replace(/\/$/, "") : null;
  if (root && dir === root) return ".";
  if (root && dir.startsWith(`${root}/`)) return dir.slice(root.length + 1);
  return dir || "/";
}

export function age(at, now = Date.now()) {
  if (!at) return "";
  const s = Math.max(0, Math.round((now - at) / 1000));
  if (s < 60) return `${s}s`;
  if (s < 3600) return `${Math.round(s / 60)}m`;
  if (s < 86400) return `${Math.round(s / 3600)}h`;
  return `${Math.round(s / 86400)}d`;
}
