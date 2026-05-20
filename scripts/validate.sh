#!/usr/bin/env bash
# AIOS 完整性校验脚本 (macOS / Linux)
# 用法: bash scripts/validate.sh
# 检查: 规则文件完整性、SKILL.md frontmatter、平台适配完整性、版本一致性

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
WARN=0

pass() { echo "  + $1"; PASS=$((PASS+1)); }
fail() { echo "  x $1"; FAIL=$((FAIL+1)); }
warn() { echo "  ! $1"; WARN=$((WARN+1)); }
section() { echo -e "\n$1"; echo "=================================================="; }

section "1. Rules completeness"
for f in "$ROOT/templates/rules/"*.yaml; do
  name="$(basename "$f")"
  [ "$name" = "custom" ] && continue
  if [ -f "$ROOT/rules/$name" ]; then
    pass "rules/$name"
  else
    fail "rules/$name MISSING"
  fi
done

section "2. SKILL.md frontmatter"
for dir in "$ROOT/skills"/pai-*/; do
  sn="$(basename "$dir")"
  f="$dir/SKILL.md"
  if [ ! -f "$f" ]; then fail "$sn no SKILL.md"; continue; fi
  # Check first line is ---
  if head -1 "$f" | grep -q '^---'; then
    pass "$sn frontmatter"
    if grep -q '^name:' "$f"; then pass "$sn name"; else fail "$sn MISSING name"; fi
    if grep -q '^description:' "$f"; then pass "$sn desc"; else fail "$sn MISSING desc"; fi
    if grep -q '^triggers:' "$f"; then pass "$sn triggers"; else warn "$sn no triggers"; fi
  else
    fail "$sn bad frontmatter"
  fi
done

section "3. Platform completeness"
for pf in "$ROOT/platforms"/*/; do
  pn="$(basename "$pf")"
  [ -f "$pf/tool-map.yaml" ] && pass "$pn tool-map.yaml" || warn "$pn tool-map.yaml MISSING"
  [ -f "$pf/INSTALL.md" ] && pass "$pn INSTALL.md" || warn "$pn INSTALL.md MISSING"
  [ -f "$pf/plugin.json" ] && pass "$pn plugin.json" || warn "$pn plugin.json MISSING"
done

section "4. Version"
if [ -f "$ROOT/.version" ]; then
  rv="$(cat "$ROOT/.version" | tr -d ' \t\n')"
  pass ".version: $rv"
else
  fail ".version MISSING"; rv=""
fi
if [ -f "$ROOT/templates/.version" ]; then
  tv="$(cat "$ROOT/templates/.version" | tr -d ' \t\n')"
  if [ "$rv" = "$tv" ]; then pass "versions consistent"
  else fail "version mismatch: $tv vs $rv"; fi
else
  fail "templates/.version MISSING"
fi
if grep -q "^## \[$rv\]" "$ROOT/CHANGELOG.md" 2>/dev/null; then
  pass "CHANGELOG current"
else
  warn "CHANGELOG no entry for [$rv]"
fi

section "Summary"
echo "Pass: $PASS  Fail: $FAIL  Warn: $WARN"
if [ $FAIL -gt 0 ]; then echo "FAILURES"; exit 1
elif [ $WARN -gt 0 ]; then echo "WARNINGS"; exit 0
else echo "ALL GOOD"; exit 0; fi
