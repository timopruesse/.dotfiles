// Pi extension: label this herdr-core terminal with the session's id and transcript
// path (`agent.kind`, `agent.session`, `agent.transcript`), so the native Herdr app's
// Outputs panel can list what the session wrote. Only acts inside an hc terminal
// (HC_TERMINAL_ID) and only for sessions that have a file; `pi --no-session` is skipped.
// @ts-nocheck

import { execFile } from "node:child_process";
import os from "node:os";
import path from "node:path";

const terminal = process.env.HC_TERMINAL_ID;
const candidates = ["hc", path.join(os.homedir(), ".local/bin/hc")];

function sessionRef(ctx) {
  let file, id;
  try { file = ctx?.sessionManager?.getSessionFile?.(); } catch { file = undefined; }
  try { id = ctx?.sessionManager?.getSessionId?.(); } catch { id = undefined; }
  if (typeof file !== "string" || !(path.posix.isAbsolute(file) || path.win32.isAbsolute(file))) return null;
  if (/[\n\r\0]/.test(file)) return null;
  return { file, id: typeof id === "string" && !/[\n\r\0]/.test(id) ? id : "" };
}

function runHc(args, index = 0) {
  if (index >= candidates.length) return;
  execFile(candidates[index], args, { timeout: 5000, windowsHide: true }, (error) => {
    if (error && error.code === "ENOENT") runHc(args, index + 1);
  });
}

export default function (pi) {
  let last = "";
  function label(ctx) {
    if (!terminal) return;
    const ref = sessionRef(ctx);
    if (!ref) return;
    const args = ["label", terminal, "agent.kind=pi", `agent.session=${ref.id}`, `agent.transcript=${ref.file}`];
    const key = args.join("\0");
    if (key === last) return;
    last = key;
    runHc(args);
  }
  pi.on("session_start", (_event, ctx) => label(ctx));
  pi.on("agent_start", (_event, ctx) => label(ctx));
}
