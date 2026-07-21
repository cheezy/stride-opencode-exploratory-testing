#!/usr/bin/env bash
# Top-level smoke-test runner for the stride-opencode-exploratory-testing bundle.
#
# Runs the structure check and the frontmatter check, and exits non-zero if
# EITHER fails — so it can gate a release. Offline and read-only. Resolves its
# sibling scripts relative to its own location, so it works from any CWD.
#
# Usage:  bash lib/test-all.sh
# Exit code: 0 only when every check in every sub-script passes; 1 otherwise.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FAIL=0

printf '=== structure ===\n'
bash "${SCRIPT_DIR}/test-structure.sh"   || FAIL=1

printf '\n=== frontmatter ===\n'
bash "${SCRIPT_DIR}/test-frontmatter.sh" || FAIL=1

printf '\n=========================\n'
if [ "$FAIL" -ne 0 ]; then
  printf 'SMOKE TEST FAILED\n'
  exit 1
fi
printf 'ALL SMOKE TESTS PASSED\n'
exit 0
