# Changelog

All notable changes to the Stride Exploratory Testing extension for OpenCode are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **`interfaces` lens** — the Heuristic Test Strategy Model's **I**nterfaces element joins the coverage lens in the `chartering` skill, covering APIs, imports and exports, UI surfaces, and integration points between systems: the boundaries where service-oriented and LLM tool-calling applications most often fail. **Downstream consumers must handle `interfaces` as a new allowed value of a charter object's optional `lens` field** (`agents/charter-generator.md`), alongside the existing `structure`, `function`, `data`, `platform`, `operations`, and `time`.

### Changed

- **`SFDPOT` renamed to `SFDIPOT`** across the extension — skills, agents, commands, fixtures, and docs. Bach's HTSM (v6.0, 2024) lists seven Product Elements; the six-letter `SFDPOT` the extension cited is a superseded form of the same heuristic. The `Interfaces` row slots between `Data` and `Platform`; no existing row was renamed, reordered, or dropped. The charter object's `source` enum value is still the literal `sfdpot` — it is a wire value, not the acronym, and renaming it would break existing consumers. The `[0.1.0]` entry below is left as written: it is a historical record of what that release shipped.
- **The `explorer` agent no longer reports numbers it cannot observe.** `session_sheet` drops `duration` and `tbs` (Task Breakdown Metric percentages) — a wall-clock measurement an agent has no way to take, whose presence contradicted the agent's own hard rule against fabricating a result. In their place it reports what it genuinely counts: `probe_budget`, `probes_attempted`, `probes_with_finding`, `on_charter_probes`/`off_charter_probes`, `tool_calls_used`, `heuristics_applied`, and `stop_reason`. An agent session is now bounded by an **agent-native budget** — a probe budget (default 12, band 8–20) and a tool-call ceiling (5 × the probe budget), whichever is reached first. The `session` skill keeps the 60–120 minute box and TBS for **human-run and paired** sessions and now states plainly that neither binds an agent session; the four stopping heuristics are unchanged in substance (bullet 2 now reads "The box or the budget is up"). **`/explore` gains `--probes <count>`** for the per-session probe budget; **`--timebox <minutes>` keeps its unit** and is now documented as doing only what it always effectively did — deciding how many charters run (one session ≈ 90 minutes) — and is never passed to the explorer. `fixtures/example-session-sheet.md` is now an agent-run sheet whose counts are derivable from its own notes. **Downstream consumers that read `session_sheet.duration` or `session_sheet.tbs` must switch to the counts**; `/debrief` is unaffected (it consumes unstructured tagged notes).

## [0.1.0] - 2026-07-21

### Added

- **Initial repository scaffold.** Standalone git repository for the [OpenCode](https://opencode.ai) port of `cheezy/stride-exploratory-testing`. Content-only bundle (no lifecycle hooks) — intentionally **no `plugin.json` and no `package.json`**; OpenCode discovers `skills/`, `commands/`, and `agents/` from the `.opencode/` config dir and reads `AGENTS.md`. Lays down the `skills/`, `commands/`, `agents/`, `lib/`, and `fixtures/` directory skeleton, an `AGENTS.md` skeleton orienting the agent to the extension, `README.md`, `LICENSE` (MIT), this changelog, and a `.gitignore`. The skills, commands, agents, helpers, and fixtures are ported in subsequent tasks.
- **Five core skills** — the `stride-exploratory-testing` orchestrator plus `chartering`, `heuristics`, `oracles`, and `session`.
- **Five native slash commands** — `/charter`, `/nightmare-headline`, `/explore`, `/recon`, and `/debrief`.
- **Two subagents** — `charter-generator` (read-only charter generation) and `explorer` (single-session execution under an absolute safety boundary).
- **Cross-platform smoke-test harness** under `lib/` — dual bash + PowerShell structure/frontmatter/runner scripts that validate the bundle offline and gate a release.
- **Worked fixtures** — an example charter set, session sheet (with Task Breakdown Metrics), and debrief (Explored/Found/Unknown + PROOF), all synthetic.
- **Install-script distribution** — `install.sh` and `install.ps1` are the sole distribution mechanism (OpenCode has no marketplace): install project-local into `.opencode/` by default or globally into `~/.config/opencode/` with `--global` / `-Global`, via `curl -fsSL .../install.sh | bash` or a clone-and-run. They copy `skills/`, `commands/`, `agents/`, `lib/`, and `fixtures/` into the discovery paths and insert this extension's `AGENTS.md` as an idempotent managed block that never clobbers user-authored content. There is no `plugin.json`/`package.json` and nothing to register in `opencode.json`.
