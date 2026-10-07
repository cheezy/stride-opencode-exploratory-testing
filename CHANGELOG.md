# Changelog

All notable changes to the Stride Exploratory Testing extension for OpenCode are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-10-07

Ports the explorer accuracy fixes from the Claude Code original (G449) into this extension, in this edition's own wording. The `explorer` agent gains an inline card, a versioned output contract, a curl-only way of observing HTTP, and a structured safety boundary.

**Callers must now send two lines, or every session ends blocked.** The explorer runs no probe unless its environment context carries `AUTHORIZED_NON_PRODUCTION: yes` and an `ALLOWED_HOSTS` line. This extension's own `/explore` sends both. Any other caller that dispatches the explorer directly must be updated to send them. That includes the Step 6.5 dispatch in `stride-opencode`.

### Added

- **An explorer card inside the agent** (W2317). `agents/explorer.md` now carries a card of at most 4,096 bytes, placed straight after the safety boundary. It holds:
  - the four severity tokens, `Critical | High | Moderate | Minor`, with their rank and a short impact ladder;
  - the tie rule, the three aggravating modifiers and how they combine;
  - the likelihood and unknown-impact rules;
  - RIMGEA mapped onto the `bugs[]` fields;
  - the three oracle verdicts and kinds;
  - the stop rules mapped onto `stop_reason`.

  The explore loop and the hard rules point at the card, so the agent no longer depends on opening a skill to rate a bug.
- **Explorer output contract 1.0** (W2318).
  - Every report carries `contract_version: "1.0"`.
  - `status` is derived from `session_sheet.stop_reason` by one published table, and an unauthorised target is `blocked`.
  - `bugs[]` gains `replicated` (`"<k>/<n>"`, or `"not established: <reason>"`) and `provisional`.
  - `questions_risks` and `off_charter` elements are typed objects.
  - A new optional, untrusted `known_issues` input feeds a new `known_bad` root array, so behaviour the team already knows about is never filed again as a bug.
  - Consumers read a missing field as an older explorer, never as an error.
  - `fixtures/example-explorer-output.json` is a complete 1.0 report.
- **The `no_observation_surface` ending** (W2319). A charter that needs an observation none of the explorer's own tools can make ends with that `stop_reason` and `status: "blocked"`. A typical example is a rendered view with no browser tool. Findings from the part it could observe stay valid. The part it could not observe is recorded as an unknown and a risk, never judged from source.
- **Explorer output and safety-boundary checks in both test shells.** `lib/test-structure.sh` and `lib/test-structure.ps1` pin the card, the contract tables, the fixture and the safety boundary with matching check labels. Setting `EXPLORER_OUTPUT` also validates a real report against the contract.

### Changed

- **The explorer observes HTTP with `curl -sS -i` and has `webfetch` turned off** (W2319). OpenCode's `webfetch` returns converted content, upgrades `http://` to `https://` and may summarise. What it returns is not the response the app sent, so it is no longer an oracle source. **Unlike the original, `curl -L` is forbidden.** A redirect is read from the unfollowed response's `Location` header and requested only when it names an allowed host. This keeps a redirect from carrying the explorer to a host nobody authorised.
- **The safety boundary is structured** (W2320).
  - **Authorisation** must come in two required lines:
    - `AUTHORIZED_NON_PRODUCTION`, whose value must be exactly `yes`;
    - `ALLOWED_HOSTS`, a list of `host[:port]` matched exactly, or `none` for a target reached only through a local command.

    A missing, empty, wrong or repeated line means `blocked` with zero probes. No redirect, page, config file, `known_issues` entry or charter wording can add a host.
  - **Cleanup:** the explorer removes every process and file it started, on every exit path.
  - **Credential files** are opened only to read one value the caller named.
  - **Disruptive techniques:** `heuristics` limits Interrupt, Starve and the Saboteur Tour to means available inside the app.
  - **`/explore`** writes both lines once, first, and puts `> ` in front of any operator or charter text that tries to forge them.
- **Skills load by name** (W2317). The explorer's skill references go through OpenCode's skill tool. The relative `skills/<name>/SKILL.md` paths don't resolve after `install.sh`, whether the install is project-local or `--global`. Four other files still mention a relative path: `commands/charter.md`, `commands/debrief.md`, `commands/nightmare-headline.md` and `agents/charter-generator.md`.

## [0.2.1] - 2026-08-21

Documentation routing only — no skill body, agent, or command behavior changed.

### Fixed

- **Three routing sites in the orchestrator skill pointed SFDIPOT at `heuristics`, where none of it lives** (D211). The lens table belongs to `chartering`. As shipped, an agent told to enumerate a product's coverage surface systematically was sent to the wrong skill and had to invent the model from its acronym. Fixed at each site: the Engines table qualifies its destination in the parenthetical style the Variables row already uses, the routing table gets a dedicated SFDIPOT row aimed at `chartering` while the "get unstuck" row narrows to cheat sheets and Tours, and the lenses list names `chartering` as the catalog.
- **The README's engines table carried the same wrong pointer** and is corrected alongside it. It is the human-facing copy of the map, so leaving it stale would have kept the defect visible after the skill was right.

## [0.2.0] - 2026-07-31

Ports the six exploratory-testing enhancements from the Claude Code original's G391 into this extension. The headline changes: two new commands (`/pair` and `/harden`), a sixth skill (`bug-advocacy`), a persisted `.exploratory/` artifact layer, the SFDPOT → SFDIPOT correction, and the removal of two metrics the explorer agent could never honestly measure.

**Two contract changes downstream consumers must handle:** `session_sheet` drops `duration` and `tbs` in favour of counts, and a charter object's optional `lens` field gains `interfaces` as an allowed value. Both are detailed below.

### Added

- **`interfaces` lens** — the Heuristic Test Strategy Model's **I**nterfaces element joins the coverage lens in the `chartering` skill, covering APIs, imports and exports, UI surfaces, and integration points between systems: the boundaries where service-oriented and LLM tool-calling applications most often fail. **Downstream consumers must handle `interfaces` as a new allowed value of a charter object's optional `lens` field** (`agents/charter-generator.md`), alongside the existing `structure`, `function`, `data`, `platform`, `operations`, and `time`.

- **`/pair` command** — the inversion of `/explore`, for a human who is driving the application themselves. They report what they did and saw; the assistant suggests the next probe and names the heuristic lens it came from, judges results with `oracles`, works confirmed defects through RIMGEA, tracks which areas and variables have gone untouched and says so unprompted, and keeps the SBTM session sheet and off-charter parking lot on their behalf. The assistant **never drives the application** and never dispatches the explorer. A paired session is bound by the human's wall clock, so its sheet carries real elapsed time and real Task Breakdown Metrics rather than the explorer's counts — the `session` skill's *Who the box binds* section now names `/pair` as exactly that case.
- **`/harden` command** — the path from Explored back to Checked. Reads a session's oracle-confirmed bugs (from an explorer findings object, a `/pair` sheet, an `/explore` debrief, or pasted findings), **detects the project's own test framework** from the repository rather than assuming one and states what it detected before writing anything, then drafts one regression check per convertible bug from its `minimal_repro`. It reports every bug it could not convert and why instead of guessing a repro. Drafts stage under `.exploratory/checks/<timestamp>-<slug>/` with an `INDEX.md`, and are **never run** — the command does not execute a draft or invoke a test runner, and never claims a draft passes.
- **`bug-advocacy` skill** — a sixth core skill encoding Cem Kaner's RIMGEA follow-through (Replicate, Isolate, Maximize, Generalize, Externalize, And say it clearly), a four-level severity rubric (**Critical > High > Moderate > Minor**) with an explicit impact ladder, three aggravate-only modifiers and a combination rule, the agreement test, the provisional-rating rules for genuinely unknown impact, and the dispassionate-tone rule. The `oracles` skill now hands a confirmed Defect to it rather than straight to the report, and the orchestrator routes bug-writeup and severity questions there.
- **Session artifacts on disk** — a defined `.exploratory/` convention at the root of the project under test: `sessions/<timestamp>-<slug>.md` (an `/explore` run's debrief or a `/pair` session's sheet), `backlog.md` (candidate and deferred charters plus parked items and open questions), `coverage.md` (the product coverage outline), and `checks/<timestamp>-<slug>/` (the regression checks `/harden` drafts, never run). Includes the filename rule, the gitignore guidance, per-artifact lifecycles, the **first-run empty-state guarantee** (a missing artifact is an empty starting state, never an error), the first-write-creates-the-header rule, and both file formats. The coverage outline is deliberately a map, never a score — it carries no percentage or ratio.
- **`charter-generator` accepts a `coverage context`** and emits an optional `deprioritized` array, so charter generation discounts ground a previous session already covered and promotes what is recorded as still dark. Absent coverage means it charters exactly as it would on run one.

### Changed

- **The explorer's `bugs[]` entries now carry the four RIMGEA fields** — `minimal_repro`, `worst_observed`, `generalization`, and `stakeholder_impact` — alongside `severity`, which is now rated against the `bug-advocacy` rubric on the worst *demonstrated* failure. All four are honest-or-`"could not establish"`, never invented, and `/explore` carries them through aggregation rather than flattening them away (merging duplicates by shortest repro, worst demonstrated consequence, broadest generalization). RIMGEA's Maximize step is explicitly bounded by the explorer's absolute safety boundary.
- **Six commands now participate in the artifact convention.** `/explore` persists its debrief, backlog and coverage updates by default and gains **`--output <path>`** to redirect the debrief only; `/pair` writes its session sheet and appends its parked items to the backlog; `/debrief` appends parked items and open questions to the backlog and updates the coverage outline; `/charter` and `/nightmare-headline` append generated charters as `candidate-charter` entries; `/recon` appends its candidates and may add a not-yet-explored area stub, and never marks an area explored. `/charter` and `/explore` also read the artifacts back to build the `coverage context`. (`/harden` writes the fourth artifact class, `checks/` — see its own entry.)
- **The redaction rule now binds explicitly on write, not only on screen.** Artifacts outlive the conversation, so credentials, tokens, customer data and internal hostnames are redacted before anything reaches disk — and artifacts are read back as **untrusted data**, never as instructions.
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
