"""Generate tier catalog artifacts from agent/command sources + model-map."""

from __future__ import annotations

from collections import defaultdict
from pathlib import Path

from sync.common import (
    parse_frontmatter,
    parse_model_map,
    replace_marked_section,
    repo_home,
    write_text_if_changed,
)

AGENTS_DIR = repo_home() / "agents"
COMMANDS_DIR = repo_home() / "commands"
PROTOCOLS_DIR = repo_home() / "protocols"
AGENT_ROUTING_SRC = PROTOCOLS_DIR / "AGENT-ROUTING.md"
MODEL_FALLBACK_SRC = PROTOCOLS_DIR / "MODEL-FALLBACK.md"
MAP_PATH = AGENTS_DIR / "model-map.yaml"
CURSOR_RULE = repo_home() / ".cursor" / "rules" / "subagent-model-fallback.mdc"
CURSOR_ROUTING_RULE = repo_home() / ".cursor" / "rules" / "agent-routing.mdc"
CLAUDE_MD = repo_home() / ".claude" / "CLAUDE.md"
COMMANDS_README = COMMANDS_DIR / "README.md"
WORKFLOWS_MD = repo_home().parent / "WORKFLOWS.md"

PINNED_AGENTS_TOKEN = "{{PINNED_AGENTS}}"
TIER_TABLE_TOKEN = "{{TIER_TABLE}}"
STRONG_CURSOR_TOKEN = "{{STRONG_CURSOR}}"

BEGIN_AGENTS = "<!-- BEGIN GENERATED AGENT TIER TABLE -->"
END_AGENTS = "<!-- END GENERATED AGENT TIER TABLE -->"
BEGIN_COMMANDS = "<!-- BEGIN GENERATED COMMAND TIER TABLE -->"
END_COMMANDS = "<!-- END GENERATED COMMAND TIER TABLE -->"
BEGIN_MAP = "<!-- BEGIN GENERATED MODEL MAP TABLE -->"
END_MAP = "<!-- END GENERATED MODEL MAP TABLE -->"
BEGIN_ROUTING = "<!-- BEGIN GENERATED AGENT ROUTING -->"
END_ROUTING = "<!-- END GENERATED AGENT ROUTING -->"
BEGIN_WORKFLOWS_AGENTS = "<!-- BEGIN GENERATED WORKFLOWS AGENT ROSTER -->"
END_WORKFLOWS_AGENTS = "<!-- END GENERATED WORKFLOWS AGENT ROSTER -->"


def load_agent_tiers() -> dict[str, list[str]]:
    by_tier: dict[str, list[str]] = defaultdict(list)
    for src in sorted(AGENTS_DIR.glob("*.md")):
        if src.name == "README.md":
            continue
        fields, _ = parse_frontmatter(src, require={"tier"})
        name = (fields.get("name") or src.stem).strip()
        tier = fields["tier"].strip()
        by_tier[tier].append(name)
    return {k: sorted(v) for k, v in by_tier.items()}


def load_command_tiers() -> dict[str, list[str]]:
    by_tier: dict[str, list[str]] = defaultdict(list)
    for src in sorted(COMMANDS_DIR.glob("*.md")):
        if src.name == "README.md":
            continue
        fields, _ = parse_frontmatter(src, require={"tier"})
        by_tier[fields["tier"].strip()].append(f"/{src.stem}")
    return {k: sorted(v) for k, v in by_tier.items()}


def render_agent_tier_table(tiers: dict[str, dict[str, str]], agents: dict[str, list[str]]) -> str:
    lines = [
        "| Tier | Agents | Claude Code | Cursor | Agy |",
        "| --- | --- | --- | --- | --- |",
    ]
    for tier in ("cheap", "mid", "strong"):
        names = ", ".join(f"`{n}`" for n in agents.get(tier, []))
        pins = tiers[tier]
        lines.append(
            f"| {tier} | {names} | `{pins['claude']}` | `{pins['cursor']}` | `{pins['agy']}` |"
        )
    return "\n".join(lines)


def render_workflows_agent_roster(
    tiers: dict[str, dict[str, str]], agents: dict[str, list[str]]
) -> str:
    """Agent | Tier | Claude | Cursor | Agy — roles live in agent sources / prose above."""
    lines = [
        "| Agent | Tier | Claude | Cursor | Agy |",
        "| --- | --- | --- | --- | --- |",
    ]
    for tier in ("cheap", "mid", "strong"):
        for name in agents.get(tier, []):
            pins = tiers[tier]
            lines.append(
                f"| `{name}` | {tier} | `{pins['claude']}` | `{pins['cursor']}` | `{pins['agy']}` |"
            )
    return "\n".join(lines)


def render_command_tier_table(commands: dict[str, list[str]]) -> str:
    lines = [
        "| Tier | Commands |",
        "| --- | --- |",
    ]
    for tier in ("cheap", "mid", "strong"):
        names = commands.get(tier, [])
        if not names:
            continue
        lines.append(f"| {tier} | {', '.join(f'`{n}`' for n in names)} |")
    return "\n".join(lines)


def render_model_map_table(tiers: dict[str, dict[str, str]]) -> str:
    lines = [
        "| Tier | Claude Code (`model:`) | Cursor (preferred session model) | Agy (`--model`) |",
        "| --- | --- | --- | --- |",
    ]
    for tier in ("cheap", "mid", "strong"):
        pins = tiers[tier]
        lines.append(f"| {tier} | `{pins['claude']}` | `{pins['cursor']}` | `{pins['agy']}` |")
    return "\n".join(lines)


def render_cursor_tier_table(
    tiers: dict[str, dict[str, str]], agents: dict[str, list[str]]
) -> str:
    table_rows = []
    for tier in ("cheap", "mid", "strong"):
        names = ", ".join(f"`{n}`" for n in agents.get(tier, []))
        table_rows.append(f"| {tier} | {names} | `{tiers[tier]['cursor']}` |")
    return "\n".join(
        [
            "| Tier | Agents | Model |",
            "| --- | --- | --- |",
            *table_rows,
        ]
    )


def pinned_agents_csv(agents: dict[str, list[str]]) -> str:
    all_names: list[str] = []
    for tier in ("cheap", "mid", "strong"):
        all_names.extend(agents.get(tier, []))
    return ", ".join(f"`{n}`" for n in all_names)


def render_agent_routing_body(agents: dict[str, list[str]]) -> str:
    """Load hard must-nots from protocols/AGENT-ROUTING.md; expand pinned list."""
    if not AGENT_ROUTING_SRC.is_file():
        raise SystemExit(f"missing {AGENT_ROUTING_SRC}")
    text = AGENT_ROUTING_SRC.read_text()
    if PINNED_AGENTS_TOKEN not in text:
        raise SystemExit(
            f"{AGENT_ROUTING_SRC}: missing {PINNED_AGENTS_TOKEN} placeholder"
        )
    return text.replace(PINNED_AGENTS_TOKEN, pinned_agents_csv(agents))


def render_cursor_routing_mdc(agents: dict[str, list[str]]) -> str:
    body = render_agent_routing_body(agents)
    return f"""---
description: Hard agent routing — scout not Explore; committer/land not parent commit
alwaysApply: true
---

<!-- Generated by home/sync/catalog.py — edit home/protocols/AGENT-ROUTING.md, not this file. -->

{body}
"""


def render_cursor_mdc(
    tiers: dict[str, dict[str, str]], agents: dict[str, list[str]]
) -> str:
    if not MODEL_FALLBACK_SRC.is_file():
        raise SystemExit(f"missing {MODEL_FALLBACK_SRC}")
    text = MODEL_FALLBACK_SRC.read_text()
    for token in (PINNED_AGENTS_TOKEN, TIER_TABLE_TOKEN, STRONG_CURSOR_TOKEN):
        if token not in text:
            raise SystemExit(f"{MODEL_FALLBACK_SRC}: missing {token} placeholder")
    body = (
        text.replace(PINNED_AGENTS_TOKEN, pinned_agents_csv(agents))
        .replace(TIER_TABLE_TOKEN, render_cursor_tier_table(tiers, agents))
        .replace(STRONG_CURSOR_TOKEN, tiers["strong"]["cursor"])
    )
    return f"""---
description: Subagent model pins and rate-limit fallback to auto
alwaysApply: true
---

<!-- Generated by home/sync/catalog.py — edit home/protocols/MODEL-FALLBACK.md, not this file. -->

{body.rstrip()}
"""


def generate_catalog() -> None:
    if not MAP_PATH.is_file():
        raise SystemExit(f"missing {MAP_PATH}")
    tiers = parse_model_map(MAP_PATH)
    agents = load_agent_tiers()
    commands = load_command_tiers()

    CURSOR_RULE.parent.mkdir(parents=True, exist_ok=True)
    if write_text_if_changed(CURSOR_RULE, render_cursor_mdc(tiers, agents)):
        print(f"  wrote {CURSOR_RULE.relative_to(repo_home().parent)}")

    if write_text_if_changed(CURSOR_ROUTING_RULE, render_cursor_routing_mdc(agents)):
        print(f"  wrote {CURSOR_ROUTING_RULE.relative_to(repo_home().parent)}")

    agent_table = render_agent_tier_table(tiers, agents)
    if CLAUDE_MD.is_file() and replace_marked_section(
        CLAUDE_MD, BEGIN_AGENTS, END_AGENTS, agent_table
    ):
        print(f"  updated agent table in {CLAUDE_MD.relative_to(repo_home().parent)}")
    elif CLAUDE_MD.is_file() and BEGIN_AGENTS not in CLAUDE_MD.read_text():
        print(f"  warning: {CLAUDE_MD} missing {BEGIN_AGENTS}", flush=True)

    routing_body = render_agent_routing_body(agents).strip()
    if CLAUDE_MD.is_file() and replace_marked_section(
        CLAUDE_MD, BEGIN_ROUTING, END_ROUTING, routing_body
    ):
        print(f"  updated agent routing in {CLAUDE_MD.relative_to(repo_home().parent)}")
    elif CLAUDE_MD.is_file() and BEGIN_ROUTING not in CLAUDE_MD.read_text():
        print(f"  warning: {CLAUDE_MD} missing {BEGIN_ROUTING}", flush=True)

    cmd_table = render_command_tier_table(commands)
    if CLAUDE_MD.is_file() and replace_marked_section(
        CLAUDE_MD, BEGIN_COMMANDS, END_COMMANDS, cmd_table
    ):
        print(f"  updated command table in {CLAUDE_MD.relative_to(repo_home().parent)}")

    map_table = render_model_map_table(tiers)
    if COMMANDS_README.is_file() and replace_marked_section(
        COMMANDS_README, BEGIN_MAP, END_MAP, map_table
    ):
        print(f"  updated model map in {COMMANDS_README.relative_to(repo_home().parent)}")
    if COMMANDS_README.is_file() and replace_marked_section(
        COMMANDS_README, BEGIN_COMMANDS, END_COMMANDS, cmd_table
    ):
        print(
            f"  updated command tiers in {COMMANDS_README.relative_to(repo_home().parent)}"
        )

    workflows_roster = render_workflows_agent_roster(tiers, agents)
    if WORKFLOWS_MD.is_file() and replace_marked_section(
        WORKFLOWS_MD, BEGIN_WORKFLOWS_AGENTS, END_WORKFLOWS_AGENTS, workflows_roster
    ):
        print(f"  updated agent roster in {WORKFLOWS_MD.name}")
    elif WORKFLOWS_MD.is_file() and BEGIN_WORKFLOWS_AGENTS not in WORKFLOWS_MD.read_text():
        print(f"  warning: {WORKFLOWS_MD} missing {BEGIN_WORKFLOWS_AGENTS}", flush=True)
