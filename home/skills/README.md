# Portable skills

Author skills here as directories containing `SKILL.md` and supporting files.
`python3 home/setup_pi.py` links the supported skills into `~/.pi/agent/skills/`
without replacing personal resources. The same installer reapplies the managed
Pi model defaults while preserving unrelated settings.

| Skill | Purpose |
| --- | --- |
| [`herdr`](herdr/) | Explicit terminal, pane, tab, and workspace management. |
| [`improve-codebase-architecture`](improve-codebase-architecture/) | Architectural investigation, visual candidates, and interactive design discussion. |

Skills use the available Pi tools directly. They do not require generated roles,
model tiers, orchestration protocols, or a separate subagent runtime.
See [`docs/PI.md`](../../docs/PI.md) for setup and prompt templates.
