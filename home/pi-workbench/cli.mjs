#!/usr/bin/env node
import { Workbench } from './core.mjs';
import { focusOwner } from './herdr.mjs';

// Read-only by default. Focus is the only terminal side effect, and must be explicit.
export function main(argv = process.argv.slice(2)) {
  const [action = 'list', taskId, extra] = argv;
  if (extra) throw new Error('Usage: node cli.mjs list | status <task-id> | focus <task-id>');
  const wb = new Workbench(process.cwd(), { sessionId: 'read-only-cli' });
  if (action === 'list' && !taskId) return wb.list();
  if (action === 'status' && taskId) return wb.summary(wb.load(taskId));
  if (action === 'focus' && taskId) return focusOwner(wb.load(taskId));
  throw new Error('Usage: node cli.mjs list | status <task-id> | focus <task-id>');
}
try { console.log(JSON.stringify(main(), null, 2)); }
catch (error) { console.error(error.message); process.exitCode = 1; }
