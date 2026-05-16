# AIOS CLI - Windows PowerShell 5.1+
# Usage:
#   .\aios.ps1 init [--defaults] [--preset <name>] [--name <name>] [--tech <list>]
#   .\aios.ps1 status
#   .\aios.ps1 update

param(
    [Parameter(Position=0)]
    [string]$Command = "status",

    [string]$Preset = "",
    [string]$Name = "",
    [string]$Tech = "",
    [string]$Description = "",
    [switch]$Defaults
)

$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplatesDir = Join-Path (Split-Path -Parent $ScriptRoot) "templates"
$Version = "v1.0.0"
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

# Validate template directory exists
if (-not (Test-Path $TemplatesDir)) {
    Write-Error "Templates directory not found: $TemplatesDir"
    Write-Host "Please ensure AIOS is installed correctly."
    exit 1
}

function Get-CurrentDate { return (Get-Date -Format "yyyy-MM-dd") }
function Get-ISO8601 { return (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK") }

function Write-Step([string]$Msg) { Write-Host "  $Msg" -ForegroundColor Gray }
function Write-Success([string]$Msg) { Write-Host "  $Msg" -ForegroundColor Green }
function Write-Warn([string]$Msg) { Write-Host "  $Msg" -ForegroundColor Yellow }
function Write-Err([string]$Msg) { Write-Host "  $Msg" -ForegroundColor Red }

# Detect preset from tech keywords
function Get-Preset([string]$TechStr) {
    if (-not $TechStr) { return "universal" }
    $lower = $TechStr.ToLower() -split '[, ]+' | Where-Object { $_ }
    $order = @("node-typescript", "python", "go", "rust", "java")
    foreach ($p in $order) {
        $pf = Join-Path $TemplatesDir "presets\$p.yaml"
        if (-not (Test-Path $pf)) { continue }
        $raw = Get-Content $pf -Raw
        if ($raw -match "match:\s*\n((?:\s*-.*\n)*)") {
            $kws = $Matches[1] -split '\n' | Where-Object { $_ -match '\s*-\s*(\S+)' } | ForEach-Object { $Matches[1].ToLower() }
            foreach ($kw in $lower) { if ($kws -contains $kw) { return $p } }
        }
    }
    return "universal"
}

# Load preset YAML
function Load-Preset([string]$PresetName) {
    $pf = Join-Path $TemplatesDir "presets\$PresetName.yaml"
    if (-not (Test-Path $pf)) {
        Write-Warn "Preset '$PresetName' not found, using universal"
        $pf = Join-Path $TemplatesDir "presets\universal.yaml"
    }
    $cfg = @{}
    Get-Content $pf | ForEach-Object {
        if ($_ -match '^\s+(\w+):\s*(.*)') {
            $cfg[$Matches[1]] = $Matches[2].Trim('"').Trim("'")
        }
    }
    $cfg['preset_name'] = $PresetName
    return $cfg
}

# Apply template variable substitution
function Apply-Template([string]$Content, [hashtable]$Vars) {
    $r = $Content
    foreach ($k in $Vars.Keys) {
        $r = $r -replace "\{$k\}", $Vars[$k]
    }
    if ($Vars.ContainsKey('indent_style_line') -and $Vars['indent_style_line']) {
        $r = $r -replace '\{indent_style_line\}', $Vars['indent_style_line']
    } else {
        $r = $r -replace ".*\{indent_style_line\}.*\r?\n", ''
    }
    if ($Vars.ContainsKey('naming_react_line') -and $Vars['naming_react_line']) {
        $r = $r -replace '\{naming_react_line\}', $Vars['naming_react_line']
    } else {
        $r = $r -replace ".*\{naming_react_line\}.*\r?\n", ''
    }
    $r = $r -replace ".*\{unknown_token\}.*\r?\n", ''
    return $r
}

# Read user input with default value
function Read-Default([string]$Prompt, [string]$Default) {
    if ($Default) { $d = " [$Default]" } else { $d = "" }
    $inp = Read-Host "$Prompt$d"
    if (-not $inp) { return $Default }
    return $inp
}

# ================================================
# COMMAND: init
# ================================================
function Invoke-Init {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  AIOS Init" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    if (Test-Path "ai") {
        Write-Warn "Found existing ai/ directory"
        $ow = Read-Host "  Overwrite/merge? [y/N]"
        if ($ow -ne 'y' -and $ow -ne 'Y') {
            Write-Host "  Cancelled." -ForegroundColor Yellow
            return
        }
    }

    if (-not $Preset) {
        if ($Tech) { $Preset = Get-Preset -TechStr $Tech }
        elseif (-not $Defaults) {
            $li = Read-Host "  Primary language [node/python/go/rust/java/universal]"
            $Preset = Get-Preset -TechStr $li
        }
        else { $Preset = "universal" }
    }
    Write-Success "Preset: $Preset"
    $cfg = Load-Preset -PresetName $Preset

    $vars = @{
        project_name = $Name
        project_description = $Description
        date = Get-CurrentDate
        iso8601 = Get-ISO8601
        preset_name = $cfg['preset_name']
        git_commit_style = $cfg['commit_style']
        git_branch_naming = $cfg['branch_naming']
        git_sign_commits = $cfg['sign_commits']
        code_indent = $cfg['indent']
        code_quotes = $cfg['quotes']
        code_semicolons = $cfg['semicolons']
        code_trailing_commas = $cfg['trailing_commas']
        code_max_line_length = $cfg['max_line_length']
        naming_files = $cfg['files']
        naming_functions = $cfg['functions']
        naming_classes = $cfg['classes']
        naming_constants = $cfg['constants']
        naming_variables = $cfg['variables']
        comments_language = $cfg['language']
        comments_require_jsdoc = $cfg['require_jsdoc']
        comments_require_function_comments = $cfg['require_function_comments']
        testing_framework = $cfg['framework']
        testing_coverage_threshold = $cfg['coverage_threshold']
        testing_require_integration = $cfg['require_integration_tests']
        aios_language = $cfg['language']
        coexistence_mode = if ($cfg.ContainsKey('coexistence_mode')) { $cfg['coexistence_mode'] } else { 'ask' }
        current_change = "None"
        current_phase = "None"
        current_task = "None"
        tdd_state = "None"
        current_sprint = "Project init"
        blockers = "None"
        next_actions = "Complete project setup"
        tech_stack = $Preset
        task_summary = "Project init"
        date_range = (Get-CurrentDate)
        aios_strict_mode = "true"
    }

    if ($cfg['indent'] -eq '0') {
        $vars['indent_style_line'] = "indent_style: tabs"
        $vars['code_indent'] = '0'
    }
    if ($cfg.ContainsKey('react_components') -and $cfg['react_components']) {
        $vars['naming_react_line'] = "react_components: $($cfg['react_components'])"
        $vars['naming_react'] = $cfg['react_components']
    }

    if (-not $Defaults) {
        Write-Host ""
        Write-Host "--- Press Enter to accept defaults ---" -ForegroundColor DarkGray
        $dn = Split-Path -Leaf (Get-Location)
        $vars['project_name'] = Read-Default "  Project name" $dn
        $vars['project_description'] = Read-Default "  Description" $vars['project_description']
        $vars['git_commit_style'] = Read-Default "  Commit style" $vars['git_commit_style']
        $vars['git_branch_naming'] = Read-Default "  Branch naming" $vars['git_branch_naming']
        $vars['code_indent'] = Read-Default "  Indent size" $vars['code_indent']
        $vars['code_quotes'] = Read-Default "  Quote style [double/single]" $vars['code_quotes']
        $vars['code_semicolons'] = Read-Default "  Semicolons [true/false]" $vars['code_semicolons']
        $vars['code_max_line_length'] = Read-Default "  Max line length" $vars['code_max_line_length']
        $vars['naming_files'] = Read-Default "  File naming" $vars['naming_files']
        $vars['naming_functions'] = Read-Default "  Function naming" $vars['naming_functions']
        $vars['testing_framework'] = Read-Default "  Test framework" $vars['testing_framework']
        $vars['aios_language'] = Read-Default "  AI output language [zh-CN/en]" $vars['aios_language']
        $si = Read-Default "  Strict mode [true/false]" $vars['aios_strict_mode']
        $vars['aios_strict_mode'] = $si
    }

    Write-Host ""

    if ($vars['code_semicolons'] -eq 'true' -or $vars['code_semicolons'] -eq 'y' -or $vars['code_semicolons'] -eq 'Y') {
        $vars['code_semicolons'] = 'true'
    } elseif ($vars['code_semicolons'] -eq 'false' -or $vars['code_semicolons'] -eq 'n' -or $vars['code_semicolons'] -eq 'N') {
        $vars['code_semicolons'] = 'false'
    }

    $dirs = @("ai\state", "ai\memory", "ai\rules\custom", "ai\specs", "ai\changes")
    foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

    Write-Step "Generating config files..."

    $t = Get-Content (Join-Path $TemplatesDir "config.yaml") -Raw
    $r = Apply-Template $t $vars
    [System.IO.File]::WriteAllText("$PWD\ai\config.yaml", $r, $Utf8NoBom)
    Write-Success "  ai/config.yaml"

    [System.IO.File]::WriteAllText("$PWD\ai\.version", $Version, $Utf8NoBom)
    Write-Success "  ai/.version"

    foreach ($f in @("current.md", "tasks.md", "roadmap.md")) {
        $t = Get-Content (Join-Path $TemplatesDir "state\$f") -Raw
        $r = Apply-Template $t $vars
        [System.IO.File]::WriteAllText("$PWD\ai\state\$f", $r, $Utf8NoBom)
    }
    Write-Success "  ai/state/ (3 files)"

    foreach ($f in @("decisions.md", "anti-patterns.md")) {
        $t = Get-Content (Join-Path $TemplatesDir "memory\$f") -Raw
        $r = Apply-Template $t $vars
        [System.IO.File]::WriteAllText("$PWD\ai\memory\$f", $r, $Utf8NoBom)
    }
    Copy-Item (Join-Path $TemplatesDir "memory\glossary.yaml") "ai\memory\glossary.yaml"
    Write-Success "  ai/memory/ (3 files)"

    foreach ($f in @("hard-rules.yaml", "arch-rules.yaml", "module-rules.yaml", "style-rules.yaml", "git-rules.yaml", "test-rules.yaml", "security-rules.yaml", "error-rules.yaml", "logging-rules.yaml", "api-rules.yaml")) {
        $t = Get-Content (Join-Path $TemplatesDir "rules\$f") -Raw
        $r = Apply-Template $t $vars
        [System.IO.File]::WriteAllText("$PWD\ai\rules\$f", $r, $Utf8NoBom)
    }
    Copy-Item (Join-Path $TemplatesDir "rules\custom\.gitkeep") "ai\rules\custom\.gitkeep"
    Write-Success "  ai/rules/ (11 files)"

    Copy-Item (Join-Path $TemplatesDir "specs\.gitkeep") "ai\specs\.gitkeep"
    Copy-Item (Join-Path $TemplatesDir "changes\.gitkeep") "ai\changes\.gitkeep"
    Write-Success "  ai/specs/, ai/changes/ (created)"

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  AIOS init complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  pai:bootstrap will auto-load on next AI session."
    Write-Host "  Use 'aios init --defaults' to skip prompts."
    Write-Host ""
}

# ================================================
# COMMAND: status
# ================================================
function Invoke-Status {
    Write-Host ""
    Write-Host "======== AIOS Project Status ========" -ForegroundColor Cyan

    if (-not (Test-Path "ai")) {
        Write-Warn "Project not initialized. Run 'aios init'."
        return
    }

    if (Test-Path "ai\.version") {
        $pv = (Get-Content "ai\.version" -Raw).Trim()
        Write-Host "  AIOS version: $pv (current: $Version)"
        if ($pv -ne $Version) { Write-Warn "    Version mismatch, run 'aios update'" }
    }

    if (Test-Path "ai\config.yaml") {
        $cc = Get-Content "ai\config.yaml" -Raw
        if ($cc -match 'project:\s*\n\s+name:\s*"([^"]+)"') { Write-Host "  Project: $($Matches[1])" }
        if ($cc -match 'preset:\s*"([^"]+)"') { Write-Host "  Preset: $($Matches[1])" }
    }

    if (Test-Path "ai\state\current.md") {
        $sc = Get-Content "ai\state\current.md" -Raw
        if ($sc -match '## Current Change\s*\n(.+)') { Write-Host "  Current Change: $($Matches[1].Trim())" }
        if ($sc -match '\*Last updated: (.+)') { Write-Host "  Last updated: $($Matches[1])" }
    }

    if (Test-Path "ai\changes") {
        $chs = Get-ChildItem "ai\changes" -Directory -Exclude "archive" | ForEach-Object { $_.Name }
        if ($chs) {
            Write-Host ""
            Write-Host "  Active Changes:" -ForegroundColor Yellow
            foreach ($c in $chs) { Write-Host "    - $c" }
        }
    }

    Write-Host ""
}

# ================================================
# COMMAND: update
# ================================================
function Invoke-Update {
    Write-Host ""
    Write-Host "======== AIOS Update ========" -ForegroundColor Cyan

    if (-not (Test-Path "ai\.version")) {
        Write-Err "No ai/.version found. Run 'aios init' first."
        return
    }

    $pv = (Get-Content "ai\.version" -Raw).Trim()
    if ($pv -eq $Version) {
        Write-Success "Project AIOS ($pv) is up to date."
        return
    }

    Write-Host "  Project version: $pv"
    Write-Host "  Latest version: $Version"
    Write-Host ""

    $tr = Get-ChildItem (Join-Path $TemplatesDir "rules") -File | Where-Object { $_.Name -ne ".gitkeep" } | ForEach-Object { $_.Name }
    $pr = Get-ChildItem "ai\rules" -File | Where-Object { $_.Name -ne ".gitkeep" } | ForEach-Object { $_.Name }
    $nr = $tr | Where-Object { $_ -notin $pr }

    if ($nr) {
        Write-Host "  New rule templates available:" -ForegroundColor Yellow
        foreach ($r in $nr) { Write-Host "    - $r" }
        $add = Read-Host "  Add them? [Y/n]"
        if ($add -ne 'n') {
            foreach ($r in $nr) {
                Copy-Item (Join-Path $TemplatesDir "rules\$r") "ai\rules\$r"
                Write-Success "    Added $r"
            }
        }
    }

    [System.IO.File]::WriteAllText("$PWD\ai\.version", $Version, $Utf8NoBom)
    Write-Success "  Version updated to $Version"
    Write-Host ""
}

# ================================================
# MAIN
# ================================================
switch ($Command.ToLower()) {
    "init"   { Invoke-Init }
    "status" { Invoke-Status }
    "update" { Invoke-Update }
    default {
        Write-Host "AIOS CLI v$Version" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage:"
        Write-Host "  aios init [--defaults] [--preset name] [--name name] [--tech list]"
        Write-Host "  aios status"
        Write-Host "  aios update"
        Write-Host ""
        Write-Host "Presets: node-typescript, python, go, rust, java, universal"
    }
}
