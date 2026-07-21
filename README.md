# Stride Exploratory Testing for OpenCode

Structured, charter-based **exploratory testing** — from OpenCode.

This extension helps you test software the way a skilled human tester does: discovering the risks, questions, and bugs that scripted and automated checks miss. It is the [OpenCode](https://opencode.ai) port of the Claude Code plugin [`cheezy/stride-exploratory-testing`](https://github.com/cheezy/stride-exploratory-testing). You plan **charters** (missions for a session), run **time-boxed sessions** that apply named **heuristics** and judge results with **oracles**, capture findings in an SBTM session sheet, and roll everything up into a stakeholder-ready **debrief**.

> **No plugin to install.** Exploratory testing has no lifecycle hooks, so this is a skills/commands/agents bundle — there is no TypeScript plugin, no `plugin.json`, and no `package.json`, and nothing to add to `opencode.json`. OpenCode discovers the pieces from `.opencode/` paths (see Installation).

> **Status:** `0.1.0` — repository scaffold. The skills, commands, agents, `lib/` helpers, and fixtures are ported in subsequent tasks. This README is filled in by the documentation task.

## Installation

OpenCode discovers skills, commands, and agents from `.opencode/` (project) or `~/.config/opencode/` (global), and reads `AGENTS.md` from the project root. Copy the bundle's pieces into place:

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
| `commands/` | Native slash commands |
| `agents/` | Subagents (`agents/<name>.md`) |
| `lib/` | Shared helper scripts |
| `fixtures/` | Calibration and example fixtures |

## License

[MIT](LICENSE) © 2026 Jeff Morgan
