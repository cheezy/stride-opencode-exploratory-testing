# Changelog

All notable changes to the Stride Exploratory Testing extension for OpenCode are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-21

### Added

- **Initial repository scaffold.** Standalone git repository for the [OpenCode](https://opencode.ai) port of `cheezy/stride-exploratory-testing`. Content-only bundle (no lifecycle hooks) — intentionally **no `plugin.json` and no `package.json`**; OpenCode discovers `skills/`, `commands/`, and `agents/` from the `.opencode/` config dir and reads `AGENTS.md`. Lays down the `skills/`, `commands/`, `agents/`, `lib/`, and `fixtures/` directory skeleton, an `AGENTS.md` skeleton orienting the agent to the extension, `README.md`, `LICENSE` (MIT), this changelog, and a `.gitignore`. The skills, commands, agents, helpers, and fixtures are ported in subsequent tasks.
