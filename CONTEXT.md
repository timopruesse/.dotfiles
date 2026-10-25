# Domain context

Terms used by the active dotfiles setup:

| Term | Meaning |
| --- | --- |
| **machine setup** | External `timopruesse/machine_setup` tool interpreting `machine_setup.yaml`; installs tools and applies dotfiles. |
| **Pi** | Default coding harness, using its native tools, model selection, sessions, skills, and prompt templates. |
| **Pi resources** | Instructions and prompts in `home/.pi/agent/`, plus portable skills in `home/skills/`. Installed selectively by `home/setup_pi.py`. |
| **agent directory** | Machine-local `~/.pi/agent`: includes credentials, preferences, trust decisions, releases, and saved sessions. Never bulk-symlinked or committed. |
| **prompt template** | Markdown under `home/.pi/agent/prompts/`, invoked as a Pi slash command. Expands into model-followed instructions, not a deterministic runtime; Poteto playbooks can invoke pstack delegates. |
| **pi-pstack** | Approved full Poteto package providing skills, sticky mode, task tracking, model-role configuration, and isolated local subagents. Replaces pi-subagents/workbench. |
| **skill** | Directory under `home/skills/` with a `SKILL.md` entry point and optional supporting files. Loaded on demand. |
| **coding-agent launcher** | Shared shell/Herdr/Neovim entry point; defaults to Pi, accepts explicit alternative CLI overrides. Independent of Git identity. |
| **Herdr** | Terminal multiplexer. The official Pi integration reports pane state and native session references. Not an implicit subagent runtime. |
| **pane context** | Per-pane metadata such as AWS profile, working-tree label, and agent label; owned by `pane_context.sh`. |
| **99 provider** | Neovim adapter invoking `pi --print --no-session` for one-off editor requests. |

Configuration and workflow: [`docs/PI.md`](docs/PI.md).
