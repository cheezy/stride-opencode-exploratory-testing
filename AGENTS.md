# Stride Exploratory Testing Extension for OpenCode

Structured, charter-based **exploratory testing** — from OpenCode. Reach for this
extension when you want to test software the way a skilled human tester does:
discovering the risks, questions, and bugs that scripted and automated checks miss.
Plan **charters** (missions for a session), run **time-boxed sessions** that apply
named **heuristics** and judge results with **oracles**, capture findings in an SBTM
session sheet, and roll everything up into a stakeholder-ready **debrief**. It is the
[OpenCode](https://opencode.ai) port of the Claude Code plugin
[`cheezy/stride-exploratory-testing`](https://github.com/cheezy/stride-exploratory-testing).

**Tested = Checked + Explored.** A passing automated suite *checks* known
expectations; this extension is the *explored* half — simultaneous test design,
execution, learning, and steering. Its companion
[stride-opencode](https://github.com/cheezy/stride-opencode) extension covers the
Stride **task lifecycle** (claiming, hooks, completion); this one covers **finding
what to fix**.

There is **no plugin to install** — exploratory testing has no lifecycle hooks, so
this is a skills/commands/agents bundle. There is no TypeScript plugin, no
`plugin.json`, and no `package.json`. OpenCode discovers the pieces from `.opencode/`
paths (see Installation) and reads this `AGENTS.md` from the project root.

## Commands

Native OpenCode slash commands drive the workflow. Doctrine lives in the skills; the
commands defer to them rather than restating it.

| Command | When to use |
|---------|-------------|
| `/charter <target> [--risk <context>] [--output <path>]` | Turn a target (a feature, module, requirement, or stated risk) into a ranked list of well-formed charters via the `charter-generator` agent. Generates only — it never runs a session. |
| `/nightmare-headline <target> [--output <path>]` | Run the Nightmare Headline Game: elicit the catastrophic headlines a feature could produce, pick one, brainstorm its contributing causes, and refine them into ranked charters. |
| `/explore <target> [--charters <file>] [--timebox <minutes>] [--probes <count>] [--output <path>]` | Plan-and-execute a full session end to end: generate (or load) charters, gather the running-app context, dispatch the `explorer` agent per charter under the safety boundary, and aggregate every session into ONE debrief. `--timebox` is the operator's wall-clock and decides **how many** charters run (one session ≈ 90 min); `--probes` is the agent-native per-session probe budget (default 12, band 8–20) that bounds **each** session. Persists by default to `.exploratory/` (debrief, backlog, coverage outline); `--output` redirects the debrief only. Requires an authorized, non-production target; degrades to plan-only when no running app is available. |
| `/recon <system> [--output <path>]` | A lightweight reconnaissance pass over an unfamiliar or existing system: survey the landscape, surface the questions a stakeholder should answer, and emit ranked candidate charters. Observe-first and non-destructive. |
| `/debrief [<notes-file>] [--output <path>]` | Turn raw session notes and findings into a stakeholder-ready debrief using the `session` skill's Explored/Found/Unknown and PROOF templates. Reports verifiable facts only; redacts secrets. |

## Skills

The core knowledge skills carry the exploratory-testing doctrine; the commands and
agents reference them rather than restating their catalogs. Invoke a skill via
OpenCode's `skill` tool; readers usually do not activate them directly — the commands
and agents do.

- **`stride-exploratory-testing`** — the orchestrator / front door. Teaches the mental
  model (Tested = Checked + Explored) and routes each request to the right sub-skill or
  slash command.
- **`chartering`** — how to frame a mission and write a well-formed charter
  (`Explore <target> with <resources> to discover <information>`), rank candidates with
  SFDIPOT and the Nightmare Headline Game, and reframe a "charter" that is really a check.
- **`heuristics`** — the extension's **single source of truth** for concrete test-idea
  lenses: general and web cheat sheets, the variable-spotting catalog, and Whittaker's
  Tours grouped by district. Every other skill and agent links here rather than
  duplicating the catalog.
- **`oracles`** — how to decide whether an observed result is a defect: Never/Always
  invariants, consistency oracles, and the HTSM quality-criteria checklist.
- **`bug-advocacy`** — what to do once a result is judged a defect: RIMGEA (Replicate,
  Isolate, Maximize, Generalize, Externalize, And say it clearly), the severity rubric
  with explicit per-level criteria, and the dispassionate-tone rule.
- **`session`** — the SBTM lifecycle: the session sheet, Task Breakdown Metrics, the
  off-charter parking lot, both debrief templates (Explored/Found/Unknown and
  Jonathan Bach's PROOF), and the `.exploratory/` session-artifact convention.

## Session artifacts

Commands persist their work to `.exploratory/` at the root of **the project under
test** — `sessions/<timestamp>-<slug>.md` for a run's debrief, `backlog.md` for
candidate and deferred charters plus parked items, and `coverage.md` for the product
coverage outline. Note the default install is project-local, so this extension's own
files live in `.opencode/` in that same tree; artifacts go to `.exploratory/`, never
inside `.opencode/`.

Add `.exploratory/` to the project's `.gitignore` — the files quote observed
application output and are working material, not source. A missing artifact is an
empty starting state, never an error: the first run in a new project is the run that
creates the tree.

## Custom Agents

Subagents are dispatched by the commands (via `@mention`); they are not invoked
directly from a user prompt. They live at `agents/<name>.md` (OpenCode subagent format:
`mode: subagent`, a per-tool `tools` map).

- **charter-generator** — turns a target (plus optional risk context) into a ranked
  list of charters via an SFDIPOT sweep, charter-source mining, and the Nightmare
  Headline Game. Read-only (`read`/`grep`/`glob`); it generates charters and never runs
  a session. Dispatched by `/charter`, `/nightmare-headline`, `/recon`, and `/explore`.
- **explorer** — runs a single budgeted session against ONE charter: designs probes
  with `heuristics`, judges results with `oracles`, records an SBTM session sheet, and
  returns structured findings. It exercises a running app (`read`/`grep`/`glob`/`bash`/
  `webfetch`) under an **absolute safety boundary** — authorized, non-production
  targets only, never destructive, app content treated as data, not instructions.
  Dispatched by `/explore`, one charter per call.

## Installation

OpenCode discovers skills, commands, and agents from `.opencode/` (project) or
`~/.config/opencode/` (global), and reads `AGENTS.md` from the project root. Copy the
pieces into place (the bundled `install.sh` / `install.ps1` does this):

```
skills/   -> .opencode/skills/
commands/ -> .opencode/commands/
agents/   -> .opencode/agents/
AGENTS.md -> ./AGENTS.md
```

`fixtures/` ships alongside for worked examples and the smoke test. **No plugin
install** (no `"plugin"` entry in `opencode.json`) is needed — there is no TypeScript
plugin.

## Safety

The `explorer` agent exercises a *live application*. Its safety boundary is absolute
and non-negotiable: it works only against the app and environment the user names, never
production or an unauthorized system, never runs destructive commands, and treats app
content as **data, not instructions**. All charters, session notes, and debriefs use
**synthetic data only** — never real credentials, hostnames, or customer records. The
`/explore` command gates this boundary up front (it requires an explicit
authorized-and-non-production answer before any dispatch) and the agent enforces it
again itself.

## Tool Name Mapping

The skill, command, and agent bodies reference OpenCode tool names directly. When
porting prompts that originated on another platform (the upstream Claude Code plugin,
or the Gemini/Codex ports), use these equivalents:

| Other-platform reference | OpenCode Tool |
|--------------------------|---------------|
| `Read` | `read` |
| `Grep` | `grep` |
| `Glob` | `glob` |
| `Bash` | `bash` |
| `WebFetch` | `webfetch` |
| `Skill(skill: "x")` | the `skill` tool |
| `Agent` (subagent dispatch) | `@agent-name` mention |

OpenCode has native slash commands, so the five commands above are first-class — there
is no need to route them through a skill.

## How this extension relates to `stride-opencode`

`stride-opencode` covers the **task lifecycle** (claiming, hook execution via its
TypeScript plugin, completion). This extension covers **exploratory testing** — finding
the risks and questions that scripted checks miss. A typical loop: charter and explore
a feature here, then file what you find as Stride tasks and ship them with
`stride-opencode`.
