#!/usr/bin/env bash
# AIOS Pre-commit Hook (macOS / Linux)
# 安装: bash scripts/hooks/install.sh
# 功能: 提交前检查规则合规性、密钥扫描、state 更新

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AI_DIR="$REPO_ROOT/ai"
EXIT_CODE=0

echo -e "\n=== AIOS Pre-commit Check ==="

# Check 1: Is AIOS initialized?
if [ ! -d "$AI_DIR" ]; then
    echo "[SKIP] Project not AIOS-initialized"
    exit 0
fi

# Check 2: Scan for hardcoded secrets
echo "[2/4] Scanning for hardcoded secrets..."
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || echo "")

if [ -n "$STAGED_FILES" ]; then
    echo "$STAGED_FILES" | while read -r file; do
        full="$REPO_ROOT/$file"
        [ ! -f "$full" ] && continue

        # Skip binary files
        if file "$full" | grep -q "binary"; then continue; fi

        # Secret patterns
        if grep -En '(?i)(api[_-]?key|apikey|secret|password|token|credential)\s*[:=]\s*["'"'"']?(sk-[A-Za-z0-9]+|[A-Za-z0-9+/]{20,})["'"'"']?' "$full" 2>/dev/null; then
            echo "[FAIL] Possible secret in $file" >&2
            EXIT_CODE=1
        fi
    done
fi
if [ $EXIT_CODE -eq 0 ]; then echo "  + Secret scan passed"; fi

# Check 3: Debug code scan
echo "[3/4] Scanning for debug code..."
DEBUG_FOUND=false
if [ -n "$STAGED_FILES" ]; then
    echo "$STAGED_FILES" | while read -r file; do
        full="$REPO_ROOT/$file"
        [ ! -f "$full" ] && continue
        ext="${file##*.}"
        case "$ext" in md|txt|yaml|yml|json|toml) continue;; esac

        for pattern in 'console\.log(' 'print(' 'debugger' 'pdb\.set_trace' 'TODO' 'FIXME' 'HACK'; do
            if grep -Eq "$pattern" "$full" 2>/dev/null; then
                echo "  ! $file: contains debug code/TODO"
                DEBUG_FOUND=true
                break
            fi
        done
    done
fi
if [ "$DEBUG_FOUND" = false ]; then echo "  + No debug code found"; fi

echo "=== Pre-commit Complete ==="
exit $EXIT_CODE
