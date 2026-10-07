#!/usr/bin/env bash
# Structure smoke test for the stride-opencode-exploratory-testing bundle.
#
# Asserts that every file the plugin needs to function is present:
# the six core skills, seven slash commands, two agents, three fixtures,
# and the top-level docs. This is a content bundle — there is intentionally
# NO package.json / plugin.json, and this test must never look for one.
# It also pins the explorer card in agents/explorer.md: its markers and
# position, a 4,096-byte cap, its severity tokens against bug-advocacy's
# four levels, its stop_reason values against the output contract, and the
# by-name form of the explorer's skill references.
#
# Offline and read-only: it stats files and reads agents/explorer.md and
# skills/bug-advocacy/SKILL.md as text with grep/awk — it never executes
# their contents and never makes a network call. Resolves the plugin root
# relative to this script's own location, so it works from any CWD.
#
# Exit code: 0 when every check passes; 1 on any failure.

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
for cmd in charter nightmare-headline explore recon debrief pair harden; do
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

# --- Explorer card ---------------------------------------------------------
#
# Every rule the explorer needs to label a bug and end a session lives on an
# inline card, so nothing depends on a skill load succeeding. These pins keep
# the card in place, under its size cap, in step with bug-advocacy's four
# levels and with the output contract's stop_reason values, and keep the
# optional skill references in OpenCode's by-name form.
printf '\nExplorer card\n'
EXPLORER="${PLUGIN_ROOT}/agents/explorer.md"
ADVOCACY="${PLUGIN_ROOT}/skills/bug-advocacy/SKILL.md"

if [ -f "$EXPLORER" ] && [ -f "$ADVOCACY" ]; then
  # Marker lines: count, first line number, and whether each is exactly the
  # marker comment. Outputs: starts ends start_line end_line exact(0/1).
  set -- $(awk '
    { sub(/\r$/, "") }
    /explorer-card:start/ { s++; if (!sl) sl = NR; if ($0 != "<!-- explorer-card:start -->") bad = 1 }
    /explorer-card:end/   { e++; if (!el) el = NR; if ($0 != "<!-- explorer-card:end -->")   bad = 1 }
    END { print s+0, e+0, sl+0, el+0, (bad ? 0 : 1) }' "$EXPLORER")
  M_START=$1; M_END=$2; L_START=$3; L_END=$4; M_EXACT=$5
  if [ "$M_START" -eq 1 ] && [ "$M_END" -eq 1 ] && [ "$L_START" -lt "$L_END" ] && [ "$M_EXACT" -eq 1 ]; then
    CARD_OK=1
    ok "explorer card markers: exactly one start and one end, in order"
  else
    CARD_OK=0
    nope "explorer card markers invalid: start=${M_START} end=${M_END} (need exactly one of each, start before end, each alone on its line)"
  fi

  card_text() {
    [ "$CARD_OK" -eq 1 ] || return 0
    awk '/explorer-card:start/{f=1} f{print} /explorer-card:end/{f=0}' "$EXPLORER"
  }

  # Position: the card is the first section after the safety boundary.
  set -- $(awk '
    { sub(/\r$/, "") }
    /^## / && n < 3 { n++; h[n] = NR; t[n] = $0 }
    END {
      ok = (t[1] ~ /^## Safety boundary/ && t[2] ~ /^## Explorer card/)
      print (ok ? 1 : 0), h[2]+0, h[3]+0
    }' "$EXPLORER")
  if [ "$CARD_OK" -eq 1 ] && [ "$1" -eq 1 ] && [ "$2" -eq $(( L_START + 1 )) ] && [ "$L_END" -lt "$3" ]; then
    ok "explorer card sits right after the safety boundary"
  else
    nope "explorer card must be the first section after '## Safety boundary' (start marker, then its '## Explorer card' heading)"
  fi

  # Byte cap, measured exactly as: awk '/explorer-card:start/,/explorer-card:end/' | wc -c
  CARD_BYTES=$(card_text | wc -c | tr -d ' ')
  if [ "$CARD_BYTES" -ge 1 ] && [ "$CARD_BYTES" -le 4096 ]; then
    ok "explorer card is ${CARD_BYTES} bytes (limit 4096)"
  else
    nope "explorer card must be 1-4096 bytes, measured ${CARD_BYTES}"
  fi

  # Severity: the card's token line, rank line and ladder bullets must each
  # equal bug-advocacy's four-levels table, in order.
  TABLE=$(tr -d '\r' < "$ADVOCACY" | awk '
    /^### The four levels/ { f = 1; next }
    /^### / { f = 0 }
    f && /^\| \*\*[A-Za-z]+\*\* \|/ { s = $0; sub(/^\| \*\*/, "", s); sub(/\*\*.*/, "", s); o = o (o == "" ? "" : " ") s }
    END { print o }')
  RANK=$(tr -d '\r' < "$ADVOCACY" | awk '
    match($0, /Rank order is \*\*[A-Za-z >]+\*\*/) {
      s = substr($0, RSTART, RLENGTH); sub(/^Rank order is \*\*/, "", s); sub(/\*\*$/, "", s); gsub(/ > /, " ", s); print s; exit
    }')
  C_ENUM=$(card_text | tr -d '\r' | awk '
    /^Severity tokens: / { s = $0; while (match(s, /`[A-Za-z]+`/)) { o = o (o == "" ? "" : " ") substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) } }
    END { print o }')
  C_RANK=$(card_text | tr -d '\r' | awk '
    /^Severity rank: / { s = $0; sub(/^Severity rank: /, "", s); gsub(/ > /, " ", s); print s; exit }')
  C_LADDER=$(card_text | tr -d '\r' | awk '
    /^- \*\*[A-Za-z]+\*\*: / { s = $0; sub(/^- \*\*/, "", s); sub(/\*\*.*/, "", s); o = o (o == "" ? "" : " ") s }
    END { print o }')
  if [ "$(echo $TABLE | wc -w | tr -d ' ')" -eq 4 ] && [ "$RANK" = "$TABLE" ] && [ "$C_ENUM" = "$TABLE" ] \
     && [ "$C_RANK" = "$TABLE" ] && [ "$C_LADDER" = "$TABLE" ]; then
    ok "explorer card severity tokens, rank and ladder match bug-advocacy's four levels"
  else
    nope "explorer card severity drifted from bug-advocacy: table='${TABLE}' rank='${RANK}' card tokens='${C_ENUM}' card rank='${C_RANK}' card ladder='${C_LADDER}'"
  fi

  # stop_reason: the card's stop values and the output contract's must be the same set.
  C_STOPS=$(card_text | tr -d '\r' | awk '
    /^- Stop `[a-z_]+`:/ { s = $0; sub(/^- Stop `/, "", s); sub(/`.*/, "", s); print s }' | LC_ALL=C sort -u)
  K_STOPS=$(tr -d '\r' < "$EXPLORER" | awk '
    index($0, "| `stop_reason` |") == 1 {
      s = substr($0, length("| `stop_reason` |") + 1)
      while (match(s, /`[a-z_]+`/)) { print substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) }
    }' | LC_ALL=C sort -u)
  if [ -n "$C_STOPS" ] && [ "$C_STOPS" = "$K_STOPS" ]; then
    ok "explorer card stop rules name exactly the output contract's stop_reason values"
  else
    ONLY_CARD=$(LC_ALL=C comm -23 <(printf '%s\n' "$C_STOPS") <(printf '%s\n' "$K_STOPS") | paste -sd ' ' -)
    ONLY_CONTRACT=$(LC_ALL=C comm -13 <(printf '%s\n' "$C_STOPS") <(printf '%s\n' "$K_STOPS") | paste -sd ' ' -)
    nope "explorer card stop_reason values differ from the output contract: in card only: [${ONLY_CARD}] in contract only: [${ONLY_CONTRACT}]"
  fi

  # RIMGEA and oracle verdicts on the card.
  MISSING_MAP=""
  for needle in '- Isolate, into `minimal_repro`:' '- Maximize, into `worst_observed`:' \
                '- Generalize, into `generalization`:' '- Externalize, into `stakeholder_impact`:' \
                'Three verdicts: Defect; Known-bad-but-expected'; do
    card_text | grep -qF -e "$needle" || MISSING_MAP="${MISSING_MAP} [${needle}]"
  done
  if [ -z "$MISSING_MAP" ]; then
    ok "explorer card maps RIMGEA onto bugs[] fields and names the oracle verdicts"
  else
    nope "explorer card is missing:${MISSING_MAP}"
  fi

  # Severity edge rules and oracle kinds: the tie rule, the three modifiers and
  # their combination rule, the likelihood rule, the unknown-impact rule, and
  # the three kinds of oracle. Each phrase occurs once on the card.
  MISSING_RULES=""
  for needle in 'If two levels fit, take the upper one, provided you demonstrated it.' \
                'Aggravating modifiers: Reach (' 'Avoidability (' 'Persistence (' \
                'two or more lift the level one step and no further' 'never create Critical' \
                'Likelihood never feeds severity' 'never Critical or High' \
                'open `stakeholder_impact` with "Provisional"' \
                'Three kinds, in order: Never/Always invariants' '); consistency (' '); approximation ('; do
    card_text | grep -qF -e "$needle" || MISSING_RULES="${MISSING_RULES} [${needle}]"
  done
  if [ -z "$MISSING_RULES" ]; then
    ok "explorer card carries the tie, modifier, likelihood and unknown-impact rules and the three oracle kinds"
  else
    nope "explorer card is missing severity or oracle rule text:${MISSING_RULES}"
  fi

  # Skill references: OpenCode installs skills under .opencode/skills/ or
  # ~/.config/opencode/skills/, so a relative skills/<name>/SKILL.md path does
  # not resolve from the project directory. Refer to skills by name instead.
  REL_REFS=$(tr -d '\r' < "$EXPLORER" | awk '/skills\/[a-z-]+\/SKILL\.md/ { c++ } END { print c+0 }')
  if [ "$REL_REFS" -eq 0 ]; then
    ok "agents/explorer.md names no skill by a skills/<name>/SKILL.md path"
  else
    nope "agents/explorer.md names a skill by a skills/<name>/SKILL.md path on ${REL_REFS} line(s); use the skill name and the \`skill\` tool"
  fi

  MISSING_BY_NAME=""
  for skill in heuristics oracles bug-advocacy session; do
    pat='- **`'"$skill"'`** (load by name via the `skill` tool)'
    hits=$(tr -d '\r' < "$EXPLORER" | awk -v p="$pat" 'index($0, p) == 1 { c++ } END { print c+0 }')
    [ "$hits" -eq 1 ] || MISSING_BY_NAME="${MISSING_BY_NAME} ${skill}"
  done
  if [ -z "$MISSING_BY_NAME" ]; then
    ok "explorer skill references load by name via the skill tool"
  else
    nope "explorer skill reference not in by-name form for:${MISSING_BY_NAME}"
  fi
else
  nope "explorer card checks need agents/explorer.md and skills/bug-advocacy/SKILL.md"
fi

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
