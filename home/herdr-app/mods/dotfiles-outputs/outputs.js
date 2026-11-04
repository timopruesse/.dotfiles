// Pure helpers for the Outputs panel: which transcript a terminal's labels point at,
// the grep that narrows it, and the parser that turns transcript lines into rows.
// No host imports, so node tests load this exact file.

export const LABELS = { kind: "agent.kind", transcript: "agent.transcript", session: "agent.session" };
export const EDIT_TOOLS = { Write: "wrote", Edit: "edited", MultiEdit: "edited", NotebookEdit: "edited" };
const ARTIFACT_URL = /https:\/\/claude\.ai\/(?:code\/)?artifact\/[A-Za-z0-9_-]+/g;

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
    return `grep -E '^\\{"parentUuid":' -- "$1" | grep -vF '"attachment":{' | grep -E '"name":"(Write|Edit|MultiEdit|NotebookEdit|Artifact)"|claude\\.ai/(code/)?artifact/' | ${tail}; test -r "$1"`;
  }
  return `grep -E '^\\{"type":"session"|"type":"toolCall","id":"[^"]*","name":"(write|edit)"' -- "$1" | ${tail}; test -r "$1"`;
}

const when = (record) => { const t = Date.parse(record?.timestamp ?? ""); return Number.isFinite(t) ? t : 0; };
const posix = (p) => p.replace(/\\/g, "/");
const join = (cwd, p) => (!p ? null : /^([A-Za-z]:)?\//.test(posix(p)) ? posix(p) : cwd ? `${posix(cwd).replace(/\/$/, "")}/${posix(p)}` : posix(p));

// Rows from transcript lines, newest first; one row per path with how often it was
// touched, plus one row per published artifact. `cwd` resolves Pi's relative paths
// when the transcript has no session line.
export function parseOutputs(text, kind, cwd = null) {
  const files = new Map(), artifacts = new Map(), pending = new Map();
  let base = cwd;
  const touch = (path, action, at) => {
    if (!path) return;
    const row = files.get(path);
    if (row) { row.count += 1; if (at >= row.at) { row.at = at; row.action = action; } }
    else files.set(path, { kind: "file", path, action, at, count: 1 });
  };
  for (const line of String(text ?? "").split("\n")) {
    if (!line.startsWith("{")) continue;
    let record;
    try { record = JSON.parse(line); } catch { continue; }
    if (kind === "pi") {
      if (record.type === "session" && typeof record.cwd === "string") { base = record.cwd; continue; }
      if (record.type !== "message" || record.message?.role !== "assistant" || !Array.isArray(record.message.content)) continue;
      for (const block of record.message.content) {
        if (block?.type !== "toolCall") continue;
        if (block.name === "write") touch(join(base, block.arguments?.path), "wrote", when(record));
        else if (block.name === "edit") touch(join(base, block.arguments?.path), "edited", when(record));
      }
      continue;
    }
    const content = record.message?.content;
    if (!Array.isArray(content)) continue;
    if (record.type === "assistant") {
      for (const block of content) {
        if (block?.type !== "tool_use") continue;
        const action = EDIT_TOOLS[block.name];
        if (action) touch(join(base, block.input?.file_path ?? block.input?.notebook_path), action, when(record));
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
  return [...artifacts.values(), ...files.values()].sort((a, b) => b.at - a.at || (a.path ?? a.url).localeCompare(b.path ?? b.url));
}

export function nameOf(row) {
  if (row.kind === "artifact") return row.title || row.url.split("/").pop();
  return row.path.split("/").pop() || row.path;
}

export function placeOf(row, cwd) {
  if (row.kind === "artifact") return row.url.replace(/^https:\/\//, "");
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
