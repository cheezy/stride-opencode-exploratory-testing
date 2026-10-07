# Structure smoke test for the stride-opencode-exploratory-testing bundle.
# PowerShell mirror of test-structure.sh.
#
# Asserts that every file the plugin needs to function is present: the six
# core skills, seven slash commands, two agents, three fixtures, and the
# top-level docs. This is a content bundle — there is intentionally NO
# package.json / plugin.json, and this test must never look for one.
# It also pins the explorer card in agents/explorer.md: its markers and
# position, a 4,096-byte cap, its severity tokens against bug-advocacy's
# four levels, its stop_reason values against the output contract, and the
# by-name form of the explorer's skill references.
#
# Offline and read-only: it tests file existence and reads agents/explorer.md
# and skills/bug-advocacy/SKILL.md as text with .NET string and regex calls —
# it never executes their contents and never makes a network call. Resolves
# the plugin root relative to this script's own location, so it works from
# any CWD.
#
# Exit code: 0 when every check passes; 1 on any failure.

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

# --- Explorer card ---------------------------------------------------------
#
# Every rule the explorer needs to label a bug and end a session lives on an
# inline card, so nothing depends on a skill load succeeding. These pins keep
# the card in place, under its size cap, in step with bug-advocacy's four
# levels and with the output contract's stop_reason values, and keep the
# optional skill references in OpenCode's by-name form. Comparisons are
# ordinal and case-sensitive, matching the bash checks.
Write-Host ''
Write-Host 'Explorer card'

function Read-Lines([string]$path) {
    # Split on LF only and keep any CR, so byte counts match awk | wc -c.
    $parts = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) -split "`n"
    $list = New-Object 'System.Collections.Generic.List[string]'
    foreach ($p in $parts) { $list.Add($p) }
    if ($list.Count -gt 0 -and $list[$list.Count - 1] -eq '') { $list.RemoveAt($list.Count - 1) }
    return ,$list
}

function Get-Ticked([string]$text, [string]$pattern) {
    $out = New-Object 'System.Collections.Generic.List[string]'
    foreach ($m in [regex]::Matches($text, $pattern)) { $out.Add($m.Groups[1].Value) }
    return ,$out
}

$Explorer = Join-Path $PluginRoot 'agents/explorer.md'
$Advocacy = Join-Path $PluginRoot 'skills/bug-advocacy/SKILL.md'

if ((Test-Path -LiteralPath $Explorer -PathType Leaf) -and (Test-Path -LiteralPath $Advocacy -PathType Leaf)) {
    $exLines  = Read-Lines $Explorer
    $advLines = Read-Lines $Advocacy

    # Markers: exactly one of each, start before end, each alone on its line.
    $mStart = 0; $mEnd = 0; $lStart = 0; $lEnd = 0; $exact = $true
    for ($i = 0; $i -lt $exLines.Count; $i++) {
        $line = $exLines[$i].TrimEnd([char]13)
        if ($line.Contains('explorer-card:start')) {
            $mStart++; if ($lStart -eq 0) { $lStart = $i + 1 }
            if ($line -cne '<!-- explorer-card:start -->') { $exact = $false }
        }
        if ($line.Contains('explorer-card:end')) {
            $mEnd++; if ($lEnd -eq 0) { $lEnd = $i + 1 }
            if ($line -cne '<!-- explorer-card:end -->') { $exact = $false }
        }
    }
    $cardOk = ($mStart -eq 1 -and $mEnd -eq 1 -and $lStart -lt $lEnd -and $exact)
    if ($cardOk) {
        Pass 'explorer card markers: exactly one start and one end, in order'
    } else {
        Fail "explorer card markers invalid: start=$mStart end=$mEnd (need exactly one of each, start before end, each alone on its line)"
    }

    $card = New-Object 'System.Collections.Generic.List[string]'
    if ($cardOk) { for ($i = $lStart - 1; $i -le $lEnd - 1; $i++) { $card.Add($exLines[$i]) } }
    $cardTrim = New-Object 'System.Collections.Generic.List[string]'
    foreach ($l in $card) { $cardTrim.Add($l.TrimEnd([char]13)) }

    # Position: the card is the first section after the safety boundary.
    $heads = New-Object 'System.Collections.Generic.List[object]'
    for ($i = 0; $i -lt $exLines.Count -and $heads.Count -lt 3; $i++) {
        $line = $exLines[$i].TrimEnd([char]13)
        if ($line.StartsWith('## ', [StringComparison]::Ordinal)) { $heads.Add(@(($i + 1), $line)) }
    }
    $posOk = $cardOk -and $heads.Count -eq 3 `
        -and $heads[0][1].StartsWith('## Safety boundary', [StringComparison]::Ordinal) `
        -and $heads[1][1].StartsWith('## Explorer card', [StringComparison]::Ordinal) `
        -and $heads[1][0] -eq ($lStart + 1) -and $lEnd -lt $heads[2][0]
    if ($posOk) {
        Pass 'explorer card sits right after the safety boundary'
    } else {
        Fail "explorer card must be the first section after '## Safety boundary' (start marker, then its '## Explorer card' heading)"
    }

    # Byte cap, measured as awk '/explorer-card:start/,/explorer-card:end/' | wc -c
    $cardBytes = 0
    foreach ($l in $card) { $cardBytes += [Text.Encoding]::UTF8.GetByteCount($l) + 1 }
    if ($cardBytes -ge 1 -and $cardBytes -le 4096) {
        Pass "explorer card is $cardBytes bytes (limit 4096)"
    } else {
        Fail "explorer card must be 1-4096 bytes, measured $cardBytes"
    }

    # Severity: token line, rank line and ladder bullets each equal
    # bug-advocacy's four-levels table, in order.
    $table = New-Object 'System.Collections.Generic.List[string]'
    $inTable = $false
    $rank = ''
    foreach ($raw in $advLines) {
        $line = $raw.TrimEnd([char]13)
        if ($line.StartsWith('### The four levels', [StringComparison]::Ordinal)) { $inTable = $true; continue }
        if ($line.StartsWith('### ', [StringComparison]::Ordinal)) { $inTable = $false }
        if ($inTable) {
            $m = [regex]::Match($line, '^\| \*\*([A-Za-z]+)\*\* \|')
            if ($m.Success) { $table.Add($m.Groups[1].Value) }
        }
        if ($rank -eq '') {
            $m = [regex]::Match($line, 'Rank order is \*\*([A-Za-z >]+)\*\*')
            if ($m.Success) { $rank = ($m.Groups[1].Value -split ' > ') -join ' ' }
        }
    }
    $tableStr = $table -join ' '
    $cEnum = ''; $cRank = ''
    $ladder = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in $cardTrim) {
        if ($line.StartsWith('Severity tokens: ', [StringComparison]::Ordinal) -and $cEnum -eq '') {
            $cEnum = (Get-Ticked $line '`([A-Za-z]+)`') -join ' '
        }
        if ($line.StartsWith('Severity rank: ', [StringComparison]::Ordinal) -and $cRank -eq '') {
            $cRank = ($line.Substring(15) -split ' > ') -join ' '
        }
        $m = [regex]::Match($line, '^- \*\*([A-Za-z]+)\*\*: ')
        if ($m.Success) { $ladder.Add($m.Groups[1].Value) }
    }
    $cLadder = $ladder -join ' '
    if ($table.Count -eq 4 -and $rank -ceq $tableStr -and $cEnum -ceq $tableStr -and $cRank -ceq $tableStr -and $cLadder -ceq $tableStr) {
        Pass "explorer card severity tokens, rank and ladder match bug-advocacy's four levels"
    } else {
        Fail "explorer card severity drifted from bug-advocacy: table='$tableStr' rank='$rank' card tokens='$cEnum' card rank='$cRank' card ladder='$cLadder'"
    }

    # stop_reason: the card's stop values and the output contract's must be the same set.
    $cStops = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($line in $cardTrim) {
        $m = [regex]::Match($line, '^- Stop `([a-z_]+)`:')
        if ($m.Success) { [void]$cStops.Add($m.Groups[1].Value) }
    }
    $kStops = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $rowPrefix = '| `stop_reason` |'
    foreach ($raw in $exLines) {
        $line = $raw.TrimEnd([char]13)
        if ($line.StartsWith($rowPrefix, [StringComparison]::Ordinal)) {
            foreach ($v in (Get-Ticked $line.Substring($rowPrefix.Length) '`([a-z_]+)`')) { [void]$kStops.Add($v) }
        }
    }
    if ($cStops.Count -gt 0 -and $cStops.SetEquals($kStops)) {
        Pass "explorer card stop rules name exactly the output contract's stop_reason values"
    } else {
        $onlyCard = @($cStops | Where-Object { -not $kStops.Contains($_) } | Sort-Object) -join ' '
        $onlyContract = @($kStops | Where-Object { -not $cStops.Contains($_) } | Sort-Object) -join ' '
        Fail "explorer card stop_reason values differ from the output contract: in card only: [$onlyCard] in contract only: [$onlyContract]"
    }

    # RIMGEA and oracle verdicts on the card.
    $cardText = $cardTrim -join "`n"
    $missingMap = ''
    foreach ($needle in @('- Isolate, into `minimal_repro`:', '- Maximize, into `worst_observed`:',
                          '- Generalize, into `generalization`:', '- Externalize, into `stakeholder_impact`:',
                          'Three verdicts: Defect; Known-bad-but-expected')) {
        if (-not $cardText.Contains($needle)) { $missingMap += " [$needle]" }
    }
    if ($missingMap -eq '') {
        Pass 'explorer card maps RIMGEA onto bugs[] fields and names the oracle verdicts'
    } else {
        Fail "explorer card is missing:$missingMap"
    }

    # Severity edge rules and oracle kinds: the tie rule, the three modifiers and
    # their combination rule, the likelihood rule, the unknown-impact rule, and
    # the three kinds of oracle. Each phrase occurs once on the card.
    $missingRules = ''
    foreach ($needle in @('If two levels fit, take the upper one, provided you demonstrated it.',
                          'Aggravating modifiers: Reach (', 'Avoidability (', 'Persistence (',
                          'two or more lift the level one step and no further', 'never create Critical',
                          'Likelihood never feeds severity', 'never Critical or High',
                          'open `stakeholder_impact` with "Provisional"',
                          'Three kinds, in order: Never/Always invariants', '); consistency (', '); approximation (')) {
        if (-not $cardText.Contains($needle)) { $missingRules += " [$needle]" }
    }
    if ($missingRules -eq '') {
        Pass 'explorer card carries the tie, modifier, likelihood and unknown-impact rules and the three oracle kinds'
    } else {
        Fail "explorer card is missing severity or oracle rule text:$missingRules"
    }

    # Skill references: OpenCode installs skills under .opencode/skills/ or
    # ~/.config/opencode/skills/, so a relative skills/<name>/SKILL.md path does
    # not resolve from the project directory. Refer to skills by name instead.
    $relRefs = 0
    foreach ($raw in $exLines) {
        if ([regex]::IsMatch($raw, 'skills/[a-z-]+/SKILL\.md')) { $relRefs++ }
    }
    if ($relRefs -eq 0) {
        Pass 'agents/explorer.md names no skill by a skills/<name>/SKILL.md path'
    } else {
        Fail "agents/explorer.md names a skill by a skills/<name>/SKILL.md path on $relRefs line(s); use the skill name and the ``skill`` tool"
    }

    $missingByName = ''
    foreach ($skill in 'heuristics','oracles','bug-advocacy','session') {
        $pat = '- **`' + $skill + '`** (load by name via the `skill` tool)'
        $hits = 0
        foreach ($raw in $exLines) {
            if ($raw.TrimEnd([char]13).StartsWith($pat, [StringComparison]::Ordinal)) { $hits++ }
        }
        if ($hits -ne 1) { $missingByName += " $skill" }
    }
    if ($missingByName -eq '') {
        Pass 'explorer skill references load by name via the skill tool'
    } else {
        Fail "explorer skill reference not in by-name form for:$missingByName"
    }
} else {
    Fail 'explorer card checks need agents/explorer.md and skills/bug-advocacy/SKILL.md'
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
