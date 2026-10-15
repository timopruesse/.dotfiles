import { test } from 'node:test';
import assert from 'node:assert/strict';
import os from 'node:os';
import fs from 'node:fs';
import path from 'node:path';
import { ownerIdentity, focusOwner, publish } from '../herdr.mjs';

function fixture(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'workbench-herdr-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  const session = path.join(dir, 'session.jsonl'); fs.writeFileSync(session, '');
  const env = { HERDR_ENV: '1', HERDR_PANE_ID: 'w4:p1', HERDR_SOCKET_PATH: '/test/socket' };
  const contract = { id: 'abcdefgh-1234', owner: ownerIdentity('session1', session, env),
    criteria: [{ state: 'passed' }, { state: 'blocked' }] };
  const calls = [];
  const run = args => {
    calls.push(args);
    return JSON.stringify({ result: { agent: { pane_id: env.HERDR_PANE_ID,
      agent_session: { agent: 'pi', kind: 'path', value: session } } } });
  };
  return { env, contract, calls, run };
}
test('outside Herdr refuses before contacting CLI', t => {
  const { contract, run, calls } = fixture(t);
  assert.throws(() => focusOwner(contract, {}, run), /inside Herdr/);
  assert.equal(calls.length, 0);
});
test('focus validates exact owner session before focusing; never creates a pane', t => {
  const { contract, env, run, calls } = fixture(t);
  focusOwner(contract, env, run);
  assert.deepEqual(calls, [['agent', 'get', 'w4:p1'], ['agent', 'focus', 'w4:p1']]);
});
test('reused pane, remote host/socket and unrecognized sessions fail closed', t => {
  const { contract, env, run, calls } = fixture(t);
  assert.throws(() => focusOwner({ ...contract, owner: { ...contract.owner, host: os.hostname() + '-other' } }, env, run), /matching/);
  assert.throws(() => focusOwner(contract, { ...env, HERDR_SOCKET_PATH: '/other' }, run), /matching/);
  assert.throws(() => focusOwner(contract, env, () => '{}'), /recognized/);
  const other = contract.owner.sessionFile + '-other'; fs.writeFileSync(other, '');
  const reused = () => JSON.stringify({ result: { agent: { pane_id: env.HERDR_PANE_ID,
    agent_session: { agent: 'pi', kind: 'path', value: other } } } });
  assert.throws(() => focusOwner(contract, env, reused), /different session/);
  assert.equal(calls.length, 0);
});
test('publication uses separate expiring display token, not lifecycle or raw prompts', t => {
  const { contract, env, run, calls } = fixture(t);
  publish(contract, false, env, run);
  const args = calls[1];
  assert.deepEqual(args.slice(0, 5), ['pane', 'report-metadata', 'w4:p1', '--source', 'pi-workbench:session1']);
  assert(args.includes('60000'));
  assert(args.some(v => v.startsWith('workbench=')));
  assert(!args.includes('--title'));
  assert(!args.includes('--state-label'));
  assert(!args.includes('report-agent'));
  publish(contract, true, env, run);
  assert(calls[3].includes('--clear-token'));
});
test('metadata cannot be published from a different pane', t => {
  const { contract, env, run, calls } = fixture(t);
  assert.throws(() => publish(contract, false, { ...env, HERDR_PANE_ID: 'w8:p9' }, run), /owning pane/);
  assert.equal(calls.length, 0);
});
