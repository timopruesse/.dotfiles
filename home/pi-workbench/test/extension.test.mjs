import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import workbenchExtension from '../index.ts';

// Real extension factory and TypeBox schemas; no provider calls or Herdr server.
function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'workbench-extension-'));
  const previous = process.env.PI_CODING_AGENT_DIR;
  process.env.PI_CODING_AGENT_DIR = path.join(root, 'agent');
  t.after(() => {
    if (previous === undefined) delete process.env.PI_CODING_AGENT_DIR;
    else process.env.PI_CODING_AGENT_DIR = previous;
    fs.rmSync(root, { recursive: true, force: true });
  });
  const entries = [], tools = [], commands = new Map(), events = new Map(), messages = [], notifications = [];
  const pi = {
    registerTool: tool => tools.push(tool),
    registerCommand: (name, command) => commands.set(name, command),
    on: (name, handler) => events.set(name, handler),
    appendEntry: (customType, data) => entries.push({ type: 'custom', customType, data }),
    sendMessage: message => messages.push(message),
  };
  const ctx = { cwd: root, hasUI: false,
    sessionManager: { getSessionId: () => 'owner', getSessionFile: () => undefined, getBranch: () => entries },
    ui: { notify: (message, type) => notifications.push({ message, type }) } };
  workbenchExtension(pi);
  return { tools, commands, events, entries, ctx, messages, notifications, pi };
}
test('factory registers only ledger tool/commands; no work or prompt replacement at startup', t => {
  const { tools, commands, events, ctx } = fixture(t);
  assert.deepEqual(tools.map(tool => tool.name), ['workbench']);
  assert.equal(tools[0].executionMode, 'sequential');
  assert.deepEqual([...commands.keys()], ['workbench']);
  assert.equal(events.get('before_agent_start')({}, ctx), undefined);
  assert.equal(fs.existsSync(path.join(process.env.PI_CODING_AGENT_DIR, 'workbench')), false);
});
test('create, prepare, reload/branch restore and context remain artifact-first', async t => {
  const f = fixture(t);
  const tool = f.tools[0];
  const created = await tool.execute('call', { action: 'create', title: 'Test', criteria: ['Prove behavior'] }, undefined, undefined, f.ctx);
  const task = created.details;
  assert.equal(task.revision, 0);
  assert.equal(f.entries.length, 1);
  const prepared = await tool.execute('call2', { action: 'handoff', revision: 0, agent: 'worker', objective: 'Only inspect the scoped fixture' }, undefined, undefined, f.ctx);
  assert.equal(prepared.details.subagent.options.outputMode, 'file-only');
  assert.equal(fs.existsSync(prepared.details.subagent.output), false);
  const context = f.events.get('before_agent_start')({}, f.ctx);
  assert(!('systemPrompt' in context));
  assert(context.message.content.length < 2000);
  assert.match(context.message.content, /not proof/);
  assert(!context.message.content.includes('Only inspect the scoped fixture'));
  // A replacement factory restores selection through branch entries, not captured state.
  workbenchExtension(f.pi);
  assert.match(f.events.get('before_agent_start')({}, f.ctx).message.content, new RegExp(task.id));
  f.entries.length = 0;
  assert.equal(f.events.get('before_agent_start')({}, f.ctx), undefined);
});
test('commands inspect/select but cannot grant ownership; outside-Herdr focus fails visibly', async t => {
  const f = fixture(t);
  const created = await f.tools[0].execute('c', { action: 'create', title: 'Test', criteria: ['Check'] }, undefined, undefined, f.ctx);
  await f.commands.get('workbench').handler(`select ${created.details.id}`, f.ctx);
  assert.equal(f.messages.length, 1);
  await f.commands.get('workbench').handler('herdr invalid', f.ctx);
  assert.equal(f.notifications.at(-1).type, 'error');
  await f.commands.get('workbench').handler('focus', f.ctx);
  assert.match(f.notifications.at(-1).message, /binding|inside Herdr/);
  const foreignCtx = { ...f.ctx, sessionManager: { ...f.ctx.sessionManager, getSessionId: () => 'foreign' } };
  await assert.rejects(f.tools[0].execute('c2', { action: 'add', revision: 0, criterion: 'Unowned' }, undefined, undefined, foreignCtx), /owning/);
});
