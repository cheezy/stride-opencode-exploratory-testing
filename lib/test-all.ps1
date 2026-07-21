# Top-level smoke-test runner for the stride-opencode-exploratory-testing bundle.
# PowerShell mirror of test-all.sh.
#
# Runs the structure check and the frontmatter check, and exits non-zero if
# EITHER fails — so it can gate a release. Offline and read-only. Resolves its
# sibling scripts relative to its own location, so it works from any CWD.
#
# Usage:  pwsh -File lib/test-all.ps1
# Exit code: 0 only when every check in every sub-script passes; 1 otherwise.

Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Re-spawn the SAME interpreter that is running this runner, resolved by PID,
# rather than hardcoding `pwsh`. On a Windows host that only has Windows
# PowerShell 5.1 (powershell.exe, no pwsh on PATH) hardcoding `pwsh` would
# fail; both powershell.exe and pwsh.exe honor -NoProfile -File.
$Interpreter = (Get-Process -Id $PID).Path

$fail = 0

Write-Host '=== structure ==='
& $Interpreter -NoProfile -File (Join-Path $ScriptDir 'test-structure.ps1')
if ($LASTEXITCODE -ne 0) { $fail = 1 }

Write-Host ''
Write-Host '=== frontmatter ==='
& $Interpreter -NoProfile -File (Join-Path $ScriptDir 'test-frontmatter.ps1')
if ($LASTEXITCODE -ne 0) { $fail = 1 }

Write-Host ''
Write-Host '========================='
if ($fail -ne 0) {
    Write-Host 'SMOKE TEST FAILED'
    exit 1
}
Write-Host 'ALL SMOKE TESTS PASSED'
exit 0
