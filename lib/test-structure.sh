#!/usr/bin/env bash
# Structure smoke test for the stride-opencode-exploratory-testing bundle.
#
# Asserts that every file the plugin needs to function is present:
# the six core skills, five slash commands, two agents, three fixtures,
# and the top-level docs. This is a content bundle — there is intentionally
# NO package.json / plugin.json, and this test must never look for one.
#
# Offline and read-only: it stats files, it never reads their contents as
# code and never makes a network call. Resolves the plugin root relative to
# this script's own location, so it works from any CWD.
#
# Exit code: 0 when every required path exists; 1 on any missing path.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS=0
FAIL=0

ok()   { PASS=$(( PASS + 1 )); printf '  \xE2\x9C\x93  %s\n' "$1"; }
nope() { FAIL=$(( FAIL + 1 )); printf '  \xE2\x9C\x97  %s\n' "$1"; }

require_file() {
  # $1 = path relative to PLUGIN_ROOT, $2 = human label
  if [ -f "${PLUGIN_ROOT}/$1" ]; then
    ok "$2 ($1)"
  else
    nope "MISSING: $2 ($1)"
  fi
}

printf 'stride-opencode-exploratory-testing: structure check\n'
printf 'plugin root: %s\n\n' "$PLUGIN_ROOT"

printf 'Skills\n'
for skill in stride-exploratory-testing chartering heuristics oracles session bug-advocacy; do
  require_file "skills/${skill}/SKILL.md" "skill ${skill}"
done

printf '\nCommands\n'
for cmd in charter nightmare-headline explore recon debrief; do
  require_file "commands/${cmd}.md" "command /${cmd}"
done

printf '\nAgents\n'
for agent in charter-generator explorer; do
  require_file "agents/${agent}.md" "agent ${agent}"
done

printf '\nFixtures\n'
for fixture in example-charters example-session-sheet example-debrief; do
  require_file "fixtures/${fixture}.md" "fixture ${fixture}"
done

printf '\nDocs and metadata\n'
require_file "README.md"    "README"
require_file "AGENTS.md"    "AGENTS.md"
require_file "CHANGELOG.md" "CHANGELOG"
require_file "LICENSE"      "LICENSE"

# This is a content bundle: assert there is NO package.json / plugin.json.
printf '\nContent-bundle invariant (no packaged-plugin manifest)\n'
manifest_found=0
for manifest in package.json plugin.json; do
  if [ -f "${PLUGIN_ROOT}/${manifest}" ]; then
    nope "unexpected ${manifest} present — this is a content bundle, not a packaged plugin"
    manifest_found=1
  fi
done
[ "$manifest_found" -eq 0 ] && ok "no package.json / plugin.json (correct for a content bundle)"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
