import { execFileSync } from 'node:child_process';
import os from 'node:os';
import fs from 'node:fs';

export function runHerdr(args) {
  return execFileSync('herdr', args, { encoding: 'utf8', timeout: 3000, maxBuffer: 128 * 1024,
    stdio: ['ignore', 'pipe', 'pipe'] });
}
export function ownerIdentity(sessionId, sessionFile, env = process.env) {
  return { sessionId, sessionFile: sessionFile || null, host: os.hostname(),
    paneId: env.HERDR_ENV === '1' ? env.HERDR_PANE_ID || null : null,
    socket: env.HERDR_ENV === '1' ? env.HERDR_SOCKET_PATH || null : null };
}
function requireHerdr(env) {
  if (env.HERDR_ENV !== '1' || !env.HERDR_PANE_ID || !env.HERDR_SOCKET_PATH)
    throw new Error('Requires an explicit Herdr action from inside Herdr with pane/socket identity');
}
function liveOwner(owner, env, run) {
  requireHerdr(env);
  if (!owner.paneId || !owner.sessionFile || owner.host !== os.hostname() || owner.socket !== env.HERDR_SOCKET_PATH)
    throw new Error('Owner has no matching local Herdr session binding');
  let result;
  try { result = JSON.parse(run(['agent', 'get', owner.paneId])); }
  catch (error) { throw new Error(`Cannot inspect owning pane: ${error.message}`); }
  const agent = result?.result?.agent;
  const actual = agent?.agent_session;
  if (agent?.pane_id !== owner.paneId || actual?.agent !== 'pi' || actual?.kind !== 'path')
    throw new Error('Owning pane no longer has a recognized Pi session');
  if (fs.realpathSync(actual.value) !== fs.realpathSync(owner.sessionFile))
    throw new Error('Owning pane now belongs to a different session; refusing stale pane ID');
}
export function focusOwner(contract, env = process.env, run = runHerdr) {
  liveOwner(contract.owner, env, run);
  run(['agent', 'focus', contract.owner.paneId]);
  return 'Focused the owning Pi pane; no worker pane was created.';
}
export function publish(contract, clear = false, env = process.env, run = runHerdr) {
  if (contract.owner.paneId !== env.HERDR_PANE_ID) throw new Error('Only the owning pane may publish metadata');
  liveOwner(contract.owner, env, run);
  const source = `pi-workbench:${contract.owner.sessionId}`;
  const args = ['pane', 'report-metadata', contract.owner.paneId, '--source', source];
  if (clear) args.push('--clear-token', 'workbench', '--clear-token', 'workbench-artifacts');
  else {
    const passed = contract.criteria.filter(a => a.state === 'passed').length;
    const blocked = contract.criteria.filter(a => ['failed', 'blocked'].includes(a.state)).length;
    args.push('--token', `workbench=${contract.id.slice(0, 8)} ${passed}/${contract.criteria.length} assessed ${blocked} blocked`,
      '--ttl-ms', '60000');
  }
  run(args);
  return 'Published display-only workbench token (60s TTL); official Pi lifecycle and subagent metadata unchanged.';
}
