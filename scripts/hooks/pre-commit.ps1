# AIOS Pre-commit Hook
# 安装: 在项目根目录运行 scripts/hooks/install.ps1
# 功能: 提交前检查规则合规性、密钥扫描、state 更新

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$AiDir = Join-Path $RepoRoot "ai"
$ExitCode = 0

Write-Host "`n=== AIOS Pre-commit Check ===" -ForegroundColor Cyan

# 检查 1: ai/ 目录是否存在（已初始化 AIOS？）
if (-not (Test-Path $AiDir)) {
    Write-Host "[SKIP] 项目未初始化 AIOS，跳过 AIOS 检查" -ForegroundColor Yellow
    exit 0
}

# 检查 2: 是否有硬编码密钥（正则扫描）
Write-Host "[2/4] 扫描硬编码密钥..." -ForegroundColor Gray
$secretPatterns = @(
    '(?i)(?:api[_-]?key|apikey|secret|password|token|credential)\s*[:=]\s*["'']?(?:[A-Za-z0-9+/]{20,}|sk-[A-Za-z0-9]+)["'']?',
    '(?i)-----BEGIN (?:RSA |EC )?PRIVATE KEY-----',
    '(?i)ghp_[A-Za-z0-9]{36}',
    '(?i)gho_[A-Za-z0-9]{36}',
    '(?i)xox[pbarsa]-[A-Za-z0-9]{10,}'
)

$stagedFiles = @()
try {
    $stagedFiles = git diff --cached --name-only --diff-filter=ACMR
} catch {
    Write-Host "[WARN] git 不可用，跳过 staged 文件检查" -ForegroundColor Yellow
}

foreach ($file in $stagedFiles) {
    $fullPath = Join-Path $RepoRoot $file
    if (-not (Test-Path $fullPath)) { continue }
    foreach ($pattern in $secretPatterns) {
        $matches = Select-String -Path $fullPath -Pattern $pattern -CaseSensitive:$false
        if ($matches) {
            Write-Host "[FAIL] 在 $file 中发现可能的硬编码密钥：" -ForegroundColor Red
            $matches | ForEach-Object { Write-Host "       $($_.LineNumber): $($_.Line.Trim())" -ForegroundColor Red }
            $ExitCode = 1
        }
    }
}
if ($ExitCode -eq 0) { Write-Host "  ✅ 密钥扫描通过" -ForegroundColor Green }

# 检查 3: ai/state/ 是否有未提交的更改
Write-Host "[3/4] 检查 state 更新状态..." -ForegroundColor Gray
$stateChanges = git diff --name-only -- "ai/state/" 2>$null
if ($stateChanges) {
    Write-Host "  ⚠️  ai/state/ 中有未提交的更改：" -ForegroundColor Yellow
    $stateChanges | ForEach-Object { Write-Host "       $_" }
    Write-Host "  提示: 建议在提交前更新 ai/state/current.md" -ForegroundColor Yellow
}

# 检查 4: 检查是否有残留的调试代码
Write-Host "[4/4] 扫描调试代码..." -ForegroundColor Gray
$debugPatterns = @('console\.log\(', 'print\(', 'puts ', 'debugger', 'pdb\.set_trace\(\)', 'TODO', 'FIXME', 'HACK')
$debugFound = $false
foreach ($file in $stagedFiles) {
    $fullPath = Join-Path $RepoRoot $file
    if (-not (Test-Path $fullPath)) { continue }
    $ext = [System.IO.Path]::GetExtension($file)
    if ($ext -in '.md', '.txt', '.yaml', '.yml', '.json', '.toml') { continue }
    foreach ($pattern in $debugPatterns) {
        $matches = Select-String -Path $fullPath -Pattern $pattern -CaseSensitive:$false
        if ($matches) {
            Write-Host "  ⚠️  $file 包含可能的调试代码/TODO" -ForegroundColor Yellow
            $debugFound = $true
            break
        }
    }
}
if (-not $debugFound) { Write-Host "  ✅ 无残留调试代码" -ForegroundColor Green }

Write-Host "=== Pre-commit Check Complete ===" -ForegroundColor Cyan
if ($ExitCode -ne 0) {
    Write-Host "提交被 AIOS pre-commit hook 阻止。请修复上述问题后重试。" -ForegroundColor Red
}
exit $ExitCode
