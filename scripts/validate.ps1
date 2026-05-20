function Pass { param($m) Write-Host ("  + " + $m); $script:Pass++ }
function Fail { param($m) Write-Host ("  x " + $m); $script:Fail++ }
function Warn { param($m) Write-Host ("  ! " + $m); $script:Warn++ }
function Section { param($s) Write-Host ("`n" + $s); Write-Host ("=" * 50) }

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Pass = 0; $Fail = 0; $Warn = 0

Section '1. Rules completeness'
$templates = Get-ChildItem "$Root\templates\rules\*.yaml" | Where-Object { $_.Name -ne "custom" } | Select-Object -ExpandProperty Name
$published = Get-ChildItem "$Root\rules\*.yaml" | Select-Object -ExpandProperty Name
foreach ($r in $templates) { if ($r -in $published) { Pass "rules/$r" } else { Fail "rules/$r MISSING" } }

Section '2. SKILL.md frontmatter'
$skills = Get-ChildItem "$Root\skills\pai-*" -Directory
foreach ($dir in $skills) {
  $f = Join-Path $dir.FullName "SKILL.md"
  $sn = $dir.Name
  if (!(Test-Path $f)) { Fail "$sn no SKILL.md"; continue }
  $raw = [System.IO.File]::ReadAllText($f)
  if ($raw.Length -eq 0) { Fail "$sn empty"; continue }
  # Check first line starts with ---
  if ($raw -match "^---") {
    Pass "$sn frontmatter"
    if ($raw -match "name:\s*\S") { Pass "$sn name" } else { Fail "$sn MISSING name" }
    if ($raw -match "description:\s*\S") { Pass "$sn desc" } else { Fail "$sn MISSING desc" }
    if ($raw -match "triggers:") { Pass "$sn triggers" } else { Warn "$sn no triggers" }
  } else { Fail "$sn bad frontmatter" }
}

Section '3. Platform completeness'
$platforms = Get-ChildItem "$Root\platforms" -Directory
foreach ($pf in $platforms) {
  $pn = $pf.Name
  if (Test-Path (Join-Path $pf.FullName "tool-map.yaml")) { Pass "$pn tool-map.yaml" } else { Warn "$pn MISSING" }
  if (Test-Path (Join-Path $pf.FullName "INSTALL.md")) { Pass "$pn INSTALL.md" } else { Warn "$pn MISSING" }
  if (Test-Path (Join-Path $pf.FullName "plugin.json")) { Pass "$pn plugin.json" } else { Warn "$pn MISSING" }
}

Section '4. Version'
$rvf = "$Root\.version"
$tvf = "$Root\templates\.version"
if (Test-Path $rvf) { $rv = (Get-Content $rvf).Trim(); Pass ".version: $rv" } else { Fail ".version MISSING" }
if (Test-Path $tvf) { $tv = (Get-Content $tvf).Trim(); if ($rv -eq $tv) { Pass "versions consistent" } else { Fail "mismatch: $tv vs $rv" } } else { Fail "templates/.version MISSING" }
if (Test-Path "$Root\CHANGELOG.md") { if (Select-String -Path "$Root\CHANGELOG.md" -Pattern "^## \[$rv\]" -Quiet) { Pass "CHANGELOG current" } else { Warn "CHANGELOG no entry" } } else { Fail "CHANGELOG.md MISSING" }

Section 'Summary'
Write-Host "Pass: $Pass  Fail: $Fail  Warn: $Warn"
if ($Fail -gt 0) { Write-Host "FAILURES" -ForegroundColor Red; exit 1 }
elseif ($Warn -gt 0) { Write-Host "WARNINGS" -ForegroundColor Yellow; exit 0 }
else { Write-Host "ALL GOOD" -ForegroundColor Green; exit 0 }