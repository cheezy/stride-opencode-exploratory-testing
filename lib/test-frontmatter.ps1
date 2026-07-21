# Frontmatter smoke test for the stride-opencode-exploratory-testing bundle.
# PowerShell mirror of test-frontmatter.sh.
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
# Offline and read-only: it parses frontmatter with native cmdlets only — it
# never evals or executes file contents, and never depends on jq. Resolves the
# plugin root relative to this script's own location.
#
# Exit code: 0 when every file satisfies its contract; 1 on any violation.

Set-StrictMode -Version Latest

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginRoot  = Split-Path -Parent $ScriptDir

$script:PASS = 0
$script:FAIL = 0

function Pass([string]$message) { $script:PASS++; Write-Host "  $([char]0x2713)  $message" }
function Fail([string]$message) { $script:FAIL++; Write-Host "  $([char]0x2717)  $message" }

# Test-FmKey — true only when $key is a top-level frontmatter key with a
# non-empty value: an inline value, or (for a block scalar `key: |` or a `key:`
# map) at least one non-empty indented continuation line. A bare `key:` with
# nothing under it is false, so an empty description is caught.
function Test-FmKey([string[]]$lines, [string]$key) {
    # Extract the frontmatter block: content between the first '---' (line 0)
    # and the next '---'.
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return $false }
    $fm = New-Object System.Collections.Generic.List[string]
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { break }
        $fm.Add($lines[$i])
    }

    $seen = $false
    $nonempty = $false
    $capturing = $false
    foreach ($line in $fm) {
        if ($line -match "^$([regex]::Escape($key)):(.*)$") {
            $seen = $true
            $val = $Matches[1].Trim()
            if ($val -ne '' -and $val -notmatch '^[|>][+-]?$') {
                $nonempty = $true
                $capturing = $false
            } else {
                $capturing = $true   # block scalar or map — value is on following lines
            }
            continue
        }
        if ($capturing) {
            if ($line -match '^\s+\S')      { $nonempty = $true; $capturing = $false }  # indented content
            elseif ($line -match '^\S')     { $capturing = $false }                     # next top-level key
        }
    }
    return ($seen -and $nonempty)
}

function Check-Keys([string]$file, [string]$label, [string[]]$keys) {
    $lines = Get-Content -LiteralPath $file
    $missing = @()
    foreach ($k in $keys) {
        if (-not (Test-FmKey $lines $k)) { $missing += $k }
    }
    if ($missing.Count -eq 0) {
        Pass "$label — has: $($keys -join ' ')"
    } else {
        Fail "$label — missing/empty: $($missing -join ' ')"
    }
}

Write-Host 'stride-opencode-exploratory-testing: frontmatter check'
Write-Host "plugin root: $PluginRoot"
Write-Host ''

Write-Host 'Skills (require: name, description)'
$skillFiles = @(Get-ChildItem -LiteralPath (Join-Path $PluginRoot 'skills') -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { Join-Path $_.FullName 'SKILL.md' } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
if ($skillFiles.Count -eq 0) { Fail 'no skills/*/SKILL.md files found' }
foreach ($f in $skillFiles) {
    $name = Split-Path -Leaf (Split-Path -Parent $f)
    Check-Keys $f "skills/$name/SKILL.md" @('name','description')
}

Write-Host ''
Write-Host 'Commands (require: description)'
$cmdFiles = @(Get-ChildItem -LiteralPath (Join-Path $PluginRoot 'commands') -Filter '*.md' -File -ErrorAction SilentlyContinue)
if ($cmdFiles.Count -eq 0) { Fail 'no commands/*.md files found' }
foreach ($f in $cmdFiles) {
    Check-Keys $f.FullName "commands/$($f.Name)" @('description')
}

Write-Host ''
Write-Host 'Agents (require: description, mode, tools)'
$agentFiles = @(Get-ChildItem -LiteralPath (Join-Path $PluginRoot 'agents') -Filter '*.md' -File -ErrorAction SilentlyContinue)
if ($agentFiles.Count -eq 0) { Fail 'no agents/*.md files found' }
foreach ($f in $agentFiles) {
    Check-Keys $f.FullName "agents/$($f.Name)" @('description','mode','tools')
}

Write-Host ''
Write-Host "$($script:PASS) passed, $($script:FAIL) failed"
if ($script:FAIL -ne 0) { exit 1 }
exit 0
