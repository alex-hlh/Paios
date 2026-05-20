#!/usr/bin/env bash
# AIOS Commit-msg Hook (macOS / Linux)
# 安装: bash scripts/hooks/install.sh
# 功能: 校验提交信息是否符合 Conventional Commits 格式

COMMIT_MSG_FILE="$1"
[ -z "$COMMIT_MSG_FILE" ] && exit 0

MSG=$(cat "$COMMIT_MSG_FILE" | tr -d '\n')

# Allow merge commits
echo "$MSG" | grep -qE '^Merge ' && exit 0

# Conventional Commits: <type>(<scope>): <description>
if ! echo "$MSG" | grep -qE '^(feat|fix|refactor|docs|test|chore|style|perf|ci|revert)(\([a-z0-9_-]+\))?!?: .+$'; then
    echo -e "\n=== AIOS Commit-msg Check ==="
    echo "[FAIL] Commit message does not follow Conventional Commits format"
    echo -e "\nFormat: <type>(<scope>): <description>"
    echo "Types: feat|fix|refactor|docs|test|chore|style|perf|ci|revert"
    echo "Example: feat(auth): add JWT authentication"
    exit 1
fi

# Check line length
LEN=${#MSG}
if [ "$LEN" -gt 72 ]; then
    echo "[WARN] Commit message exceeds 72 characters ($LEN)"
fi
