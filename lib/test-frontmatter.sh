#!/usr/bin/env bash
# Frontmatter smoke test for the stride-opencode-exploratory-testing bundle.
#
# Asserts the OpenCode frontmatter contract on every discovered file:
#   - skills/*/SKILL.md   -> name + description
#   - commands/*.md       -> description         (NOT allowed-tools/argument-hint)
#   - agents/*.md         -> description + mode + tools
#
# An OpenCode agent derives its name from the filename, so agents are NOT
# required to carry a `name` key. Commands carry only a description. The parser
# handles both the inline (`description: text`) and block-scalar
# (`description: |`) forms, and the `tools:` map form.
#
# Offline and read-only: it PARSES frontmatter with grep/awk only — it never
# evals or executes file contents, and never depends on jq. Resolves the plugin
# root relative to this script's own location.
#
# Exit code: 0 when every file satisfies its contract; 1 on any violation.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS=0
FAIL=0

ok()   { PASS=$(( PASS + 1 )); printf '  \xE2\x9C\x93  %s\n' "$1"; }
nope() { FAIL=$(( FAIL + 1 )); printf '  \xE2\x9C\x97  %s\n' "$1"; }

# fm_has_key <file> <key>
# Succeeds (exit 0) only when <key> is a top-level key in the YAML frontmatter
# block AND has a non-empty value — either an inline value, or, for a block
# scalar (`key: |`) or a map (`key:` followed by indented entries), at least
# one non-empty indented continuation line. A bare `key:` with nothing under it
# fails, so an empty description is caught.
fm_has_key() {
  awk -v key="$2" '
    BEGIN { infm = 0; started = 0; seen = 0; nonempty = 0; capturing = 0 }
    # Frontmatter opens on the first line when it is exactly ---
    NR == 1 { if ($0 == "---") { infm = 1; started = 1 } ; next }
    infm && $0 == "---" { infm = 0 ; next }
    !infm { next }
    {
      if ($0 ~ "^" key ":") {
        seen = 1
        val = $0
        sub("^" key ":[ \t]*", "", val)
        gsub(/[ \t]+$/, "", val)
        if (val != "" && val !~ /^[|>][+-]?$/) {
          nonempty = 1
          capturing = 0
        } else {
          capturing = 1   # block scalar or map — value is on the following lines
        }
        next
      }
      if (capturing) {
        if ($0 ~ /^[ \t]+[^ \t]/)      { nonempty = 1; capturing = 0 }  # indented content
        else if ($0 ~ /^[^ \t]/)       { capturing = 0 }               # next top-level key
      }
    }
    END { exit (started && seen && nonempty) ? 0 : 1 }
  ' "$1"
}

check_keys() {
  # $1 = file, $2 = label, remaining args = required keys
  local file="$1" label="$2"; shift 2
  local missing=""
  for k in "$@"; do
    fm_has_key "$file" "$k" || missing="${missing} ${k}"
  done
  if [ -z "$missing" ]; then
    ok "$label — has:$(printf ' %s' "$@")"
  else
    nope "$label — missing/empty:${missing}"
  fi
}

printf 'stride-opencode-exploratory-testing: frontmatter check\n'
printf 'plugin root: %s\n\n' "$PLUGIN_ROOT"

printf 'Skills (require: name, description)\n'
found_any=0
for f in "${PLUGIN_ROOT}"/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  found_any=1
  check_keys "$f" "skills/$(basename "$(dirname "$f")")/SKILL.md" name description
done
[ "$found_any" -eq 1 ] || nope "no skills/*/SKILL.md files found"

printf '\nCommands (require: description)\n'
found_any=0
for f in "${PLUGIN_ROOT}"/commands/*.md; do
  [ -f "$f" ] || continue
  found_any=1
  check_keys "$f" "commands/$(basename "$f")" description
done
[ "$found_any" -eq 1 ] || nope "no commands/*.md files found"

printf '\nAgents (require: description, mode, tools)\n'
found_any=0
for f in "${PLUGIN_ROOT}"/agents/*.md; do
  [ -f "$f" ] || continue
  found_any=1
  check_keys "$f" "agents/$(basename "$f")" description mode tools
done
[ "$found_any" -eq 1 ] || nope "no agents/*.md files found"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
