# Changelog

All notable changes to the Stride Exploratory Testing extension for OpenCode are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-21

### Added

- **Initial repository scaffold.** Standalone git repository for the [OpenCode](https://opencode.ai) port of `cheezy/stride-exploratory-testing`. Content-only bundle (no lifecycle hooks) — intentionally **no `plugin.json` and no `package.json`**; OpenCode discovers `skills/`, `commands/`, and `agents/` from the `.opencode/` config dir and reads `AGENTS.md`. Lays down the `skills/`, `commands/`, `agents/`, `lib/`, and `fixtures/` directory skeleton, an `AGENTS.md` skeleton orienting the agent to the extension, `README.md`, `LICENSE` (MIT), this changelog, and a `.gitignore`. The skills, commands, agents, helpers, and fixtures are ported in subsequent tasks.
- **Five core skills** — the `stride-exploratory-testing` orchestrator plus `chartering`, `heuristics`, `oracles`, and `session`.
- **Five native slash commands** — `/charter`, `/nightmare-headline`, `/explore`, `/recon`, and `/debrief`.
- **Two subagents** — `charter-generator` (read-only charter generation) and `explorer` (single-session execution under an absolute safety boundary).
- **Cross-platform smoke-test harness** under `lib/` — dual bash + PowerShell structure/frontmatter/runner scripts that validate the bundle offline and gate a release.
- **Worked fixtures** — an example charter set, session sheet (with Task Breakdown Metrics), and debrief (Explored/Found/Unknown + PROOF), all synthetic.
- **Install-script distribution** — `install.sh` and `install.ps1` are the sole distribution mechanism (OpenCode has no marketplace): install project-local into `.opencode/` by default or globally into `~/.config/opencode/` with `--global` / `-Global`, via `curl -fsSL .../install.sh | bash` or a clone-and-run. They copy `skills/`, `commands/`, `agents/`, `lib/`, and `fixtures/` into the discovery paths and insert this extension's `AGENTS.md` as an idempotent managed block that never clobbers user-authored content. There is no `plugin.json`/`package.json` and nothing to register in `opencode.json`.
