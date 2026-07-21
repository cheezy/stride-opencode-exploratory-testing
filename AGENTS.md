# Stride Exploratory Testing Extension for OpenCode

Structured, charter-based **exploratory testing** — from OpenCode. Plan charters, run time-boxed sessions that apply named heuristics and judge results with oracles, and capture findings. This extension is the [OpenCode](https://opencode.ai) port of the Claude Code plugin [`cheezy/stride-exploratory-testing`](https://github.com/cheezy/stride-exploratory-testing).

There is **no plugin to install** — exploratory testing has no lifecycle hooks, so this is a skills/commands/agents bundle. There is no TypeScript plugin, no `plugin.json`, and no `package.json`. OpenCode discovers the pieces from `.opencode/` paths (see Installation) and reads this `AGENTS.md` from the project root.

> **Status:** `0.1.0` — repository scaffold. The skills, commands, agents, `lib/` helpers, and fixtures are added in subsequent tasks. The sections below describe the intended surface; entries are filled in as each piece lands.

## Commands

Native OpenCode slash commands drive the workflow. Doctrine lives in the skills; the commands defer to them rather than restating it. (Populated by subsequent tasks — the port mirrors the upstream `/charter`, `/nightmare-headline`, `/explore`, `/recon`, and `/debrief` commands.)

| Command | When to use |
|---------|-------------|
| _(added in a later task)_ | |

## Skills

The core knowledge skills carry the exploratory-testing doctrine; the commands and agents reference them rather than restating their catalogs. Invoke a skill via OpenCode's `skill` tool. (Populated by subsequent tasks — the port mirrors the upstream `stride-exploratory-testing` orchestrator plus `chartering`, `heuristics`, `oracles`, and `session`.)

## Custom Agents

Subagents are dispatched by the commands (via `@mention`); they are not invoked directly from a user prompt. They live at `agents/<name>.md` (OpenCode subagent format: `mode: subagent`, read-only `tools`). (Populated by subsequent tasks — the port mirrors the upstream `charter-generator` and `explorer` agents.)

## Installation

OpenCode discovers skills, commands, and agents from `.opencode/` (project) or `~/.config/opencode/` (global), and reads `AGENTS.md` from the project root. Copy the pieces into place:

```
skills/   -> .opencode/skills/
commands/ -> .opencode/commands/
agents/   -> .opencode/agents/
AGENTS.md -> ./AGENTS.md
```

## Layout

| Path | Purpose |
|------|---------|
| `skills/` | Core knowledge skills (the doctrine) |
| `commands/` | Native slash commands (no `plugin.json` — OpenCode has native commands) |
| `agents/` | Subagents (`agents/<name>.md`, `mode: subagent`) |
| `lib/` | Shared helper scripts |
| `fixtures/` | Calibration and example fixtures |

There is intentionally **no `plugin.json` and no `package.json`** — this is a content-only bundle with no lifecycle hooks.

## License

[MIT](LICENSE) © 2026 Jeff Morgan
