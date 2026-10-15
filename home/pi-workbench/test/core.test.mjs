import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { Workbench } from '../core.mjs';

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'pi-workbench-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const cwd = path.join(root, 'repo'); fs.mkdirSync(cwd);
  const wb = new Workbench(cwd, { sessionId: 'parent' }, path.join(root, 'state'));
  const task = wb.create('Focused task', ['Check behavior', 'Review exact patch']);
  return { root, cwd, wb, task };
}
test('private durable contract and stable append-only criteria', t => {
  const { wb, task } = fixture(t);
  assert.equal(fs.statSync(task.contract).mode & 0o777, 0o600);
  assert.equal(fs.statSync(task.artifacts).mode & 0o777, 0o700);
  const next = wb.add(task.id, 0, 'New requirement');
  assert.equal(next.revision, 1);
  assert.deepEqual(wb.load(task.id).criteria.map(a => a.id), ['A1', 'A2', 'A3']);
  assert.equal(wb.load(task.id).history.length, 1);
  assert.throws(() => wb.add(task.id, 0, 'Lost update'), /Revision conflict/);
  assert.equal(wb.load(task.id).criteria.length, 3);
});
test('assessments require evidence and explicit waiver reasons/scope', t => {
  const { wb, task, cwd } = fixture(t);
  assert.throws(() => wb.record(task.id, 0, 'A1', 'passed', 'ok'), /evidence/);
  assert.throws(() => wb.record(task.id, 0, 'A1', 'waived', ''), /reason/);
  assert.throws(() => wb.record(task.id, 0, 'A1', 'waived', 'approved'), /scope/);
  const evidence = path.join(cwd, 'tests.log'); fs.writeFileSync(evidence, '2 passed');
  const passed = wb.record(task.id, 0, 'A1', 'passed', 'Observed focused tests', [evidence], 'HEAD abc + diff sha256:123');
  assert.equal(passed.counts.passed, 1);
  assert.equal(passed.assessment, 'open');
  const done = wb.record(task.id, 1, 'A2', 'waived', 'User explicitly waived optional review', [], 'same patch');
  assert.equal(done.assessment, 'criteria-recorded-ready');
  fs.writeFileSync(evidence, 'changed');
  assert.deepEqual(wb.summary(wb.load(task.id)).stale, ['A1']);
  assert.equal(wb.summary(wb.load(task.id)).assessment, 'open');
  fs.unlinkSync(evidence);
  assert.deepEqual(wb.summary(wb.load(task.id)).stale, ['A1']);
});
test('only owner mutates; reload restores disk state and evidence', t => {
  const { wb, task, cwd, root } = fixture(t);
  const foreign = new Workbench(cwd, { sessionId: 'other' }, path.join(root, 'state'));
  assert.equal(foreign.load(task.id).id, task.id);
  assert.throws(() => foreign.add(task.id, 0, 'Unowned'), /owning/);
  const restored = new Workbench(cwd, { sessionId: 'parent' }, path.join(root, 'state'));
  assert.equal(restored.add(task.id, 0, 'After reload').revision, 1);
  assert.throws(() => wb.load('../../escape'), /Invalid task ID/);
});
test('reject empty, oversized, malformed, symlinked and foreign evidence', t => {
  const { wb, task, root, cwd } = fixture(t);
  assert.throws(() => wb.create('empty', []), /At least/);
  assert.throws(() => wb.create('long', ['x'.repeat(2001)]), /printable/);
  const foreign = path.join(root, 'private'); fs.writeFileSync(foreign, 'secret');
  fs.symlinkSync(foreign, path.join(cwd, 'link'));
  assert.throws(() => wb.evidence(task.id, path.join(cwd, 'link')), /checkout/);
  const body = fs.readFileSync(task.contract, 'utf8');
  fs.writeFileSync(task.contract, '{');
  assert.throws(() => wb.load(task.id), /contract JSON/);
  fs.writeFileSync(task.contract, body);
  fs.renameSync(task.artifacts, task.artifacts + '-saved');
  fs.symlinkSync(task.artifacts + '-saved', task.artifacts);
  assert.throws(() => wb.load(task.id), /Unsafe/);
});
test('locking fails closed without stealing another writer lock', t => {
  const { wb, task } = fixture(t);
  const lock = path.join(task.artifacts, '.lock'); fs.writeFileSync(lock, 'owner');
  assert.throws(() => wb.add(task.id, 0, 'Concurrent'), /locked/);
  assert.equal(fs.readFileSync(lock, 'utf8'), 'owner');
});
test('handoff prepares native file-only params without launching; receipt is separate', t => {
  const { wb, task } = fixture(t);
  const brief = wb.handoff(task.id, 0, 'reviewer', 'Review only the scoped diff sha256:123');
  assert.equal(brief.subagent.options.outputMode, 'file-only');
  assert.equal('outputMode' in brief.subagent, false);
  assert.equal(brief.subagent.async, true);
  assert.equal(brief.subagent.worktree, false);
  assert.equal(brief.subagent.options.context, 'fresh');
  assert.equal(brief.subagent.options.agentScope, 'user');
  assert.match(brief.subagent.task, /remain read-only/);
  assert.match(brief.subagent.task, /blockers to the supervisor immediately/);
  assert.equal(fs.existsSync(brief.subagent.output), false);
  assert.throws(() => wb.receipt(task.id, 1, brief.handoffId, 'completed', 'run1', 'No blockers', []), /ENOENT/);
  fs.writeFileSync(brief.subagent.output, 'Full review report');
  const receipt = wb.receipt(task.id, 1, brief.handoffId, 'completed', 'run1', 'No findings in scoped review', []);
  assert.equal(receipt.handoffs[0].state, 'completed');
  assert.equal(receipt.counts.passed, 0);
  assert.throws(() => wb.receipt(task.id, 2, brief.handoffId, 'completed', 'run1', 'Again', []), /already/);
});
test('failed/blocked receipt cannot omit blockers or silently pass assertions', t => {
  const { wb, task } = fixture(t);
  const brief = wb.handoff(task.id, 0, 'researcher', 'Research API details');
  assert.throws(() => wb.receipt(task.id, 1, brief.handoffId, 'failed', 'run1', 'Failed', []), /explicit blockers/);
  const receipt = wb.receipt(task.id, 1, brief.handoffId, 'failed', 'run1', 'Lookup failed', ['Provider unavailable']);
  assert.deepEqual(receipt.handoffs[0].blockers, ['Provider unavailable']);
  assert.deepEqual(receipt.attentionHandoffs, [brief.handoffId]);
  assert.equal(receipt.counts.passed, 0);
});
test('compact status limits summaries and retains attention IDs/omission counts', t => {
  const { wb, task } = fixture(t);
  for (let revision = 0; revision < 7; revision++) wb.handoff(task.id, revision, 'scout', 'Inspect bounded scope');
  const s = wb.summary(wb.load(task.id));
  assert.equal(s.handoffs.length, 4);
  assert.equal(s.omittedHandoffs, 3);
  assert.equal(s.attentionHandoffs.length, 7);
});
