# Changelog

All notable changes to the Stride Exploratory Testing extension for OpenCode are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-10-07

Ports the rest of the G449-G451 batch from the Claude Code original (G450 and G451) into this extension, in this edition's own wording. The explorer can write its full report to a file and return a short summary, re-check one fixed bug in verify mode, and read files in bounded ranges; `/harden` can run unattended from that report; and the always-loaded descriptions are shorter.

This is the release for the whole G449-G451 port; the batch's commits since 0.2.1 are W2317 to W2325. The G449 part (W2317 explorer card, W2318 output contract 1.0, W2319 curl-only HTTP and `no_observation_surface`, W2320 structured safety boundary) was already tagged and published as 0.3.0, so it is described in the [0.3.0] entry below and not repeated here. This entry describes W2321 to W2325.

**Callers that dispatch `explorer` directly must still send the two authorisation lines, or every session ends blocked.** Nothing in this release relaxes 0.3.0's requirement: the environment context must carry `AUTHORIZED_NON_PRODUCTION: yes` and an `ALLOWED_HOSTS` line, and a verify dispatch without them returns `not_verified`. That includes the Step 6.5 dispatch in `stride-opencode`. The new inputs below are optional: `EXPLORATORY_REPORT_PATH`, `EXPLORATORY_MODE=verify`, and at most one test-account pointer on its own line ahead of any untrusted text. `contract_version` stays `"1.0"`.

### Added

- **The explorer report file** (W2321, porting W2266). Given an absolute `EXPLORATORY_REPORT_PATH`, the explorer writes its full contract-1.0 findings there and replies with a plain-text summary of at most 2,048 bytes and no json fence.
  - The file is written with one `bash` command under `noclobber`, and never over an existing file or link. The path must start with `/` and has no `..` segment, single quote, newline or other control character; it is used exactly as the caller gave it and is never built from app content, files read, the charter or `known_issues`.
  - The path comes only from a line that starts with `EXPLORATORY_REPORT_PATH`. A line starting with `> ` never counts, and two or more such lines are a failed write.
  - `edit` and `write` stay off, because a frontmatter permission glob cannot name a path chosen at dispatch time.
  - A refused or failed write replies `report: NOT WRITTEN - <reason>` followed by the full fenced JSON.
  - With no path the output is unchanged.
  - **`/explore` never passes a path.** It puts `> ` in front of any `EXPLORATORY_REPORT_PATH` line in operator or charter text, so the explorer never receives one that counts. If a result still starts with a `report:` line, `/explore` never opens the path it names: it parses the fence that follows, or records the session as unusable.
- **Verify mode** (W2322, porting W2268). `EXPLORATORY_MODE=verify` re-checks one fixed bug from its `minimal_repro` on a 2-probe, 10-tool-call budget. OpenCode sets no turn bound on an agent, so the explorer counts the calls itself.
  - The findings gain a root `verify` object, `{ "result": "pass" | "fail" | "not_verified", "repro_reached", "evidence" }`, and the summary gains a `verify:` line.
  - A partial fix is `fail`. An unreached repro, or a bug with no usable `minimal_repro`, is `not_verified`, which is never a pass.
  - `status` is still derived from `stop_reason`, and the safety boundary, both required lines and cleanup still apply.
- **`/harden` runs unattended** (W2323, porting W2269). Given both a bug source and `--framework`, it never asks a question. `--framework none` is reserved for the no-framework path, a bug source that cannot be read stops the run in every mode, and the explorer's report file is accepted as a bug source.
  - **`--framework` also changes interactive runs.** Whenever it is supplied, with or without a bug source, `/harden` no longer asks about weak framework evidence or two competing runners: it uses the given framework and names the runner it overrode. A named framework with no evidence in the repository is used anyway and reported as *given but not found*. A name that is neither in the table nor `none` is used only when the repository's markers and test files agree on it; otherwise it takes the no-framework path.
  - The never-overwrite rule and the credential, real-host and destructive-step prohibitions bind an unattended run exactly as they bind an interactive one.
- **A reading rule and a single test-account pointer** (W2324, porting the explorer half of W2270). A new *Reading files* section after the card says to find lines with `grep` first, read a bounded range with `read`'s `offset` and `limit` (or `sed -n`), read each file, range or skill once per session unless it changed, and inspect binary files through `bash`. A test-account pointer names a value only when it is the only one in the dispatch, on its own line, ahead of any text the caller marked untrusted.
- **Checks for all of the above in both test shells.** `lib/test-structure.sh` and `lib/test-structure.ps1` pin the report-file rules, verify mode, the unattended `/harden` rules, the reading section and its position, the pointer rule, and the new skill references.

### Changed

- **Shorter always-loaded descriptions and two skill sections moved to references** (W2325, porting W2272). The `explorer` and `charter-generator` descriptions drop their `<example>` blocks and how-it-works prose, and the `/explore`, `/harden` and `/pair` descriptions keep their triggers only. Every triggering condition and the explorer's safety statement stay. The other description blocks are unchanged. All the agent and command description blocks together went from 6,830 to 4,199 bytes. The session skill's on-disk artifacts section moves to `skills/session/references/session-artifacts.md`, and the bug-advocacy worked example and tone section to `skills/bug-advocacy/references/worked-example-and-tone.md`. Each skill keeps a stub with the headings the commands cite. No behaviour changed, and `install.sh` and `install.ps1` already copy the new `references/` directories.

### Not carried by this edition

These items from the batch are recorded here so that "not applicable" can be told apart from "missed".

- **W2265, W2267 and W2271** change `stride`'s own Step 5.5 consumer: the move to the new contract, grouping manual tests into charters, and trimming the Step 5.5 and findings contracts. This extension has no Step 5.5. The equivalent work belongs to the Step 6.5 dispatch in `stride-opencode`.
- **The fixed dispatch template half of W2270** places the two safety lines, the report path and the pointers in one template. It belongs to the Step 6.5 dispatch in `stride-opencode`, not to this extension. Only the explorer half is ported here.
- **W2273** measured the Claude Code edition only. Its figures say nothing about OpenCode, so this release claims no measured saving for this edition. The description and skill-size figures above are byte counts, not a measurement of cost.

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
