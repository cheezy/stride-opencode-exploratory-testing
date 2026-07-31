# Structure smoke test for the stride-opencode-exploratory-testing bundle.
# PowerShell mirror of test-structure.sh.
#
# Asserts that every file the plugin needs to function is present: the six
# core skills, seven slash commands, two agents, three fixtures, and the
# top-level docs. This is a content bundle — there is intentionally NO
# package.json / plugin.json, and this test must never look for one.
#
# Offline and read-only: it tests file existence, never reads contents as code
# and never makes a network call. Resolves the plugin root relative to this
# script's own location, so it works from any CWD.
#
# Exit code: 0 when every required path exists; 1 on any missing path.

Set-StrictMode -Version Latest

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginRoot  = Split-Path -Parent $ScriptDir

$script:PASS = 0
$script:FAIL = 0

function Pass([string]$message) { $script:PASS++; Write-Host "  $([char]0x2713)  $message" }
function Fail([string]$message) { $script:FAIL++; Write-Host "  $([char]0x2717)  $message" }

function Require-File([string]$rel, [string]$label) {
    if (Test-Path -LiteralPath (Join-Path $PluginRoot $rel) -PathType Leaf) {
        Pass "$label ($rel)"
    } else {
        Fail "MISSING: $label ($rel)"
    }
}

Write-Host 'stride-opencode-exploratory-testing: structure check'
Write-Host "plugin root: $PluginRoot"
Write-Host ''

Write-Host 'Skills'
foreach ($skill in 'stride-exploratory-testing','chartering','heuristics','oracles','session','bug-advocacy') {
    Require-File "skills/$skill/SKILL.md" "skill $skill"
}

Write-Host ''
Write-Host 'Commands'
foreach ($cmd in 'charter','nightmare-headline','explore','recon','debrief','pair','harden') {
    Require-File "commands/$cmd.md" "command /$cmd"
}

Write-Host ''
Write-Host 'Agents'
foreach ($agent in 'charter-generator','explorer') {
    Require-File "agents/$agent.md" "agent $agent"
}

Write-Host ''
Write-Host 'Fixtures'
foreach ($fixture in 'example-charters','example-session-sheet','example-debrief') {
    Require-File "fixtures/$fixture.md" "fixture $fixture"
}

Write-Host ''
Write-Host 'Docs and metadata'
Require-File 'README.md'    'README'
Require-File 'AGENTS.md'    'AGENTS.md'
Require-File 'CHANGELOG.md' 'CHANGELOG'
Require-File 'LICENSE'      'LICENSE'

# This is a content bundle: assert there is NO package.json / plugin.json.
Write-Host ''
Write-Host 'Content-bundle invariant (no packaged-plugin manifest)'
$manifestFound = $false
foreach ($manifest in 'package.json','plugin.json') {
    if (Test-Path -LiteralPath (Join-Path $PluginRoot $manifest) -PathType Leaf) {
        Fail "unexpected $manifest present — this is a content bundle, not a packaged plugin"
        $manifestFound = $true
    }
}
if (-not $manifestFound) { Pass 'no package.json / plugin.json (correct for a content bundle)' }

Write-Host ''
Write-Host "$($script:PASS) passed, $($script:FAIL) failed"
if ($script:FAIL -ne 0) { exit 1 }
exit 0
