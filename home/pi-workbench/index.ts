import { Type } from 'typebox';
import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { Workbench } from './core.mjs';
import { ownerIdentity, focusOwner, publish } from './herdr.mjs';

export default function workbenchExtension(pi: ExtensionAPI) {
  function store(ctx: ExtensionContext) {
    return new Workbench(ctx.cwd, ownerIdentity(ctx.sessionManager.getSessionId(), ctx.sessionManager.getSessionFile()));
  }
  function selected(ctx: ExtensionContext): string | undefined {
    let taskId: string | undefined;
    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type === 'custom' && entry.customType === 'workbench-selection')
        taskId = (entry.data as { taskId?: string })?.taskId;
    }
    return taskId;
  }
  function select(taskId: string) { pi.appendEntry('workbench-selection', { taskId }); }
  function compact(s: ReturnType<Workbench['list']>[number]) {
    return 'error' in s ? { id: s.id, error: s.error } : { id: s.id, title: s.title, counts: s.counts };
  }
  function status(ctx: ExtensionContext, taskId = selected(ctx)) {
    if (!taskId) throw new Error('No selected task. Create one with workbench or select an existing ID.');
    const wb = store(ctx);
    return wb.summary(wb.load(taskId));
  }
  function refresh(ctx: ExtensionContext) {
    if (!ctx.hasUI) return;
    try {
      const s = status(ctx);
      ctx.ui.setStatus('pi-workbench', `Contract ${s.counts.passed}/${Object.values(s.counts).reduce((a: number, b: number) => a + b, 0)} assessed · ${s.open.length} open · ${s.stale.length} stale`);
    } catch { ctx.ui.setStatus('pi-workbench', undefined); }
  }
  const fields = {
    taskId: Type.Optional(Type.String()), revision: Type.Optional(Type.Integer({ minimum: 0 })),
    title: Type.Optional(Type.String()), criteria: Type.Optional(Type.Array(Type.String(), { maxItems: 64 })),
    criterion: Type.Optional(Type.String()), assertion: Type.Optional(Type.String()),
    state: Type.Optional(Type.String()), note: Type.Optional(Type.String()),
    evidence: Type.Optional(Type.Array(Type.String(), { maxItems: 8 })), scope: Type.Optional(Type.String()),
    agent: Type.Optional(Type.String()), objective: Type.Optional(Type.String()),
    handoffId: Type.Optional(Type.String()), runId: Type.Optional(Type.String()),
    summary: Type.Optional(Type.String()), blockers: Type.Optional(Type.Array(Type.String(), { maxItems: 8 })),
  };
  pi.registerTool({
    name: 'workbench', label: 'Workbench', executionMode: 'sequential',
    description: 'Persistent verification contracts and artifact-first native subagent handoffs. Actions: create(title,criteria), status/list, add(criterion), record(assertion,state,note,evidence,scope), handoff(agent,objective), receipt(handoffId,state,runId,summary,blockers). Mutations require current revision. Handoff PREPARES native params; it never launches. Receipts and passes are parent assessments, not verified completion. Read the workbench skill before orchestration. No delivery authority is granted.',
    parameters: Type.Object({ action: Type.Union(['create', 'status', 'list', 'add', 'record', 'handoff', 'receipt'].map(v => Type.Literal(v))), ...fields }),
    async execute(_id, p, _signal, _update, ctx) {
      const wb = store(ctx);
      const taskId = p.taskId || selected(ctx);
      let result;
      if (p.action === 'create') {
        result = wb.create(p.title, p.criteria);
        select(result.id);
      } else if (p.action === 'list') {
        const all = wb.list();
        result = { tasks: all.slice(-12).map(compact),
          omitted: Math.max(0, all.length - 12), note: 'Use the package CLI for the complete list.' };
      } else {
        if (!taskId) throw new Error('taskId is required without a selected task');
        if (p.action === 'status') result = status(ctx, taskId);
        else if (p.action === 'add') result = wb.add(taskId, p.revision, p.criterion);
        else if (p.action === 'record') result = wb.record(taskId, p.revision, p.assertion, p.state, p.note, p.evidence, p.scope);
        else if (p.action === 'handoff') result = wb.handoff(taskId, p.revision, p.agent, p.objective);
        else result = wb.receipt(taskId, p.revision, p.handoffId, p.state, p.runId, p.summary, p.blockers);
      }
      refresh(ctx);
      return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }], details: result };
    },
  });
  pi.registerCommand('workbench', {
    description: 'Contract status/list/select <id>; herdr [clear] publishes explicit metadata; focus [id] navigates to owner',
    handler: async (args, ctx) => {
      try {
        const [action = 'status', arg, extra] = args.trim().split(/\s+/).filter(Boolean);
        if (extra) throw new Error('Too many arguments');
        const wb = store(ctx);
        let result;
        if (action === 'list') result = wb.list().map(compact);
        else if (action === 'select') {
          if (!arg) throw new Error('select requires a task ID');
          result = status(ctx, arg); select(arg);
        } else if (action === 'status') result = status(ctx, arg);
        else if (action === 'focus') {
          const s = status(ctx, arg);
          result = focusOwner(wb.load(s.id));
        } else if (action === 'herdr') {
          if (arg && arg !== 'clear') throw new Error('Use herdr or herdr clear');
          const s = status(ctx);
          result = publish(wb.load(s.id), arg === 'clear');
        } else throw new Error('Use status [id], list, select <id>, herdr [clear], or focus [id]');
        refresh(ctx);
        pi.sendMessage({ customType: 'workbench-status', content: JSON.stringify(result, null, 2), display: true });
      } catch (error) { ctx.ui.notify(error instanceof Error ? error.message : String(error), 'error'); }
    },
  });
  pi.on('session_start', (_event, ctx) => refresh(ctx));
  pi.on('session_tree', (_event, ctx) => refresh(ctx));
  pi.on('before_agent_start', (_event, ctx) => {
    if (!selected(ctx)) return;
    try {
      const s = status(ctx);
      return { message: { customType: 'workbench-contract', display: false,
        content: `Workbench task ${s.id}, revision ${s.revision}: ${JSON.stringify(s.counts)}; stale evidence ${s.stale.join(',') || 'none detected'}. Contract: ${s.contract}. Artifacts: ${s.artifacts}. Parent-recorded assessments are not proof; revalidate exact patch before delivery. Read the contract on resume or before assessing criteria. ${s.attentionHandoffs.length} handoffs need attention; inspect status. Never hide blockers or infer completion from a launch receipt.` } };
    } catch (error) {
      return { message: { customType: 'workbench-contract', display: false,
        content: `Workbench contract unavailable: ${error instanceof Error ? error.message : String(error)}. Do not infer readiness.` } };
    }
  });
}
