# AIOS Commit-msg Hook
# 安装: 在项目根目录运行 scripts/hooks/install.ps1
# 功能: 校验提交信息是否符合 Conventional Commits 格式

$commitMsgFile = $args[0]
if (-not $commitMsgFile) { exit 0 }

$msg = Get-Content $commitMsgFile -Raw
$msg = $msg.Trim()

# 允许 merge commit (Git 自动生成的)
if ($msg -match '^Merge ') { exit 0 }

# Conventional Commits 格式:
# <type>(<scope>): <description>
# type: feat|fix|refactor|docs|test|chore|style|perf|ci|revert
$pattern = '^(feat|fix|refactor|docs|test|chore|style|perf|ci|revert)(\([a-z0-9_-]+\))?!?: .+$'

if ($msg -notmatch $pattern) {
    Write-Host "`n=== AIOS Commit-msg Check ===" -ForegroundColor Cyan
    Write-Host "[FAIL] 提交信息不符合 Conventional Commits 格式" -ForegroundColor Red
    Write-Host "`n格式: <type>(<scope>): <description>" -ForegroundColor Yellow
    Write-Host "类型: feat|fix|refactor|docs|test|chore|style|perf|ci|revert" -ForegroundColor Yellow
    Write-Host "示例: feat(auth): add JWT authentication" -ForegroundColor Yellow
    Write-Host "     fix(api): handle null response in login endpoint`n" -ForegroundColor Yellow
    exit 1
}

# 检查描述长度
if ($msg.Length -gt 72) {
    Write-Host "[WARN] 提交信息超过 72 字符 ($($msg.Length))" -ForegroundColor Yellow
}
