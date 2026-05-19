#!/usr/bin/env bash
# AIOS CLI — macOS / Linux bash 3.2+
# Usage:
#   ./aios.sh init [--defaults] [--preset <name>] [--name <name>] [--tech <list>]
#   ./aios.sh status
#   ./aios.sh update

set -euo pipefail

COMMAND="${1:-status}"
PRESET=""
NAME=""
TECH=""
DESCRIPTION=""
DEFAULTS=false

# Parse args
shift_args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --preset) PRESET="$2"; shift 2 ;;
        --name)   NAME="$2"; shift 2 ;;
        --tech)   TECH="$2"; shift 2 ;;
        --desc)   DESCRIPTION="$2"; shift 2 ;;
        --defaults) DEFAULTS=true; shift ;;
        *) COMMAND="$1"; shift ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$ROOT_DIR/templates"
VERSION="v1.2.0"

# Colors
C_RESET="\033[0m"
C_CYAN="\033[36m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"
C_GRAY="\033[90m"

step()  { echo -e "  ${C_GRAY}$1${C_RESET}"; }
ok()    { echo -e "  ${C_GREEN}$1${C_RESET}"; }
warn()  { echo -e "  ${C_YELLOW}$1${C_RESET}"; }
err()   { echo -e "  ${C_RED}$1${C_RESET}"; }

current_date() { date "+%Y-%m-%d"; }
iso8601() { date -u "+%Y-%m-%dT%H:%M:%SZ"; }

# ─── Detect preset from tech keywords ───
get_preset() {
    local tech_str="${1:-}"
    if [[ -z "$tech_str" ]]; then
        echo "universal"
        return
    fi

    local tech_lower=$(echo "$tech_str" | tr '[:upper:]' '[:lower:]' | tr ',' ' ')
    local presets=("node-typescript" "python" "go" "rust" "java")

    for preset in "${presets[@]}"; do
        local preset_file="$TEMPLATES_DIR/presets/$preset.yaml"
        if [[ ! -f "$preset_file" ]]; then continue; fi

        local keywords=$(grep -A 20 '^match:' "$preset_file" | grep '^\s*- ' | sed 's/.*- *//' | tr '[:upper:]' '[:lower:]')

        for kw in $tech_lower; do
            if echo "$keywords" | grep -qx "$kw"; then
                echo "$preset"
                return
            fi
        done
    done

    echo "universal"
}

# ─── Load preset YAML (simple parser) ───
load_preset() {
    local preset_name="$1"
    local preset_file="$TEMPLATES_DIR/presets/$preset_name.yaml"

    if [[ ! -f "$preset_file" ]]; then
        warn "Preset '$preset_name' not found, using universal"
        preset_file="$TEMPLATES_DIR/presets/universal.yaml"
    fi

    declare -gA PRESET_CFG

    # Parse simple key: value
    while IFS=':' read -r key val; do
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        val=$(echo "$val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//')
        if [[ -n "$key" && "$key" != "name" && "$key" != "description" && "$key" != "match" ]]; then
            PRESET_CFG["$key"]="$val"
        fi
    done < <(grep -E '^\s+[a-z_]+:' "$preset_file" | head -40)

    PRESET_CFG["preset_name"]="$preset_name"
}

# ─── Apply template variables ───
apply_template() {
    local content="$1"
    local result="$content"

    for key in "${!TEMPLATE_VARS[@]}"; do
        result="${result//\{$key\}/${TEMPLATE_VARS[$key]}}"
    done

    # Handle conditional lines
    if [[ -n "${TEMPLATE_VARS[indent_style_line]:-}" ]]; then
        result="${result//\{indent_style_line\}/${TEMPLATE_VARS[indent_style_line]}}"
    else
        result=$(echo "$result" | sed '/{indent_style_line}/d')
    fi

    if [[ -n "${TEMPLATE_VARS[naming_react_line]:-}" ]]; then
        result="${result//\{naming_react_line\}/${TEMPLATE_VARS[naming_react_line]}}"
    else
        result=$(echo "$result" | sed '/{naming_react_line}/d')
    fi

    # Remove remaining placeholders
    result=$(echo "$result" | sed '/{.*}/d')

    echo "$result"
}

# ─── Read user input with default ───
read_default() {
    local prompt="$1"
    local default="$2"
    local display=" [$default]"

    if [[ -z "$default" ]]; then
        display=""
    fi

    echo -n "  $prompt$display: " >&2
    read -r input

    if [[ -z "$input" ]]; then
        echo "$default"
    else
        echo "$input"
    fi
}

# ═══════════════════════════════════════════════
# COMMAND: init
# ═══════════════════════════════════════════════
cmd_init() {
    echo ""
    echo -e "${C_CYAN}════════════════════════════════════════════${C_RESET}"
    echo -e "${C_CYAN}  AIOS Init — 初始化项目 AI 工程环境${C_RESET}"
    echo -e "${C_CYAN}════════════════════════════════════════════${C_RESET}"
    echo ""

    # Check for existing ai/
    if [[ -d "ai" ]]; then
        warn "检测到现有 ai/ 目录"
        echo -n "  覆盖/合并？[y/N]: "
        read -r overwrite
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            echo -e "  ${C_YELLOW}已取消。${C_RESET}"
            return
        fi
    fi

    # Determine preset
    if [[ -z "$PRESET" ]]; then
        if [[ -n "$TECH" ]]; then
            PRESET=$(get_preset "$TECH")
        elif $DEFAULTS; then
            PRESET="universal"
        else
            echo -n "  项目主要语言 [node/python/go/rust/java/universal]: "
            read -r lang_input
            PRESET=$(get_preset "$lang_input")
        fi
    fi
    ok "预设档案: $PRESET"

    # Load preset
    load_preset "$PRESET"

    # Build template variables
    declare -gA TEMPLATE_VARS
    TEMPLATE_VARS=(
        [project_name]="$NAME"
        [project_description]="$DESCRIPTION"
        [date]="$(current_date)"
        [iso8601]="$(iso8601)"
        [preset_name]="${PRESET_CFG[preset_name]}"
        [git_commit_style]="${PRESET_CFG[commit_style]:-conventional}"
        [git_branch_naming]="${PRESET_CFG[branch_naming]:-feature/<name>}"
        [git_sign_commits]="${PRESET_CFG[sign_commits]:-false}"
        [code_indent]="${PRESET_CFG[indent]:-2}"
        [code_quotes]="${PRESET_CFG[quotes]:-double}"
        [code_semicolons]="${PRESET_CFG[semicolons]:-true}"
        [code_trailing_commas]="${PRESET_CFG[trailing_commas]:-all}"
        [code_max_line_length]="${PRESET_CFG[max_line_length]:-100}"
        [naming_files]="${PRESET_CFG[files]:-kebab-case}"
        [naming_functions]="${PRESET_CFG[functions]:-camelCase}"
        [naming_classes]="${PRESET_CFG[classes]:-PascalCase}"
        [naming_constants]="${PRESET_CFG[constants]:-UPPER_SNAKE_CASE}"
        [naming_variables]="${PRESET_CFG[variables]:-camelCase}"
        [comments_language]="${PRESET_CFG[language]:-zh-CN}"
        [comments_require_jsdoc]="${PRESET_CFG[require_jsdoc]:-false}"
        [comments_require_function_comments]="${PRESET_CFG[require_function_comments]:-true}"
        [testing_framework]="${PRESET_CFG[framework]:-通用}"
        [testing_coverage_threshold]="${PRESET_CFG[coverage_threshold]:-80}"
        [testing_require_integration]="${PRESET_CFG[require_integration_tests]:-true}"
        [aios_language]="${PRESET_CFG[language]:-zh-CN}"
        [aios_strict_mode]="true"
        [current_change]="无（新项目）"
        [current_phase]="无"
        [current_task]="无"
        [tdd_state]="无"
        [current_sprint]="项目初始化"
        [blockers]="无"
        [next_actions]="完成项目初始化配置"
        [tech_stack]="$PRESET"
        [task_summary]="项目初始化"
        [date_range]="$(current_date)"
    )

    # Handle indent style (Go uses tabs)
    if [[ "${PRESET_CFG[indent]:-2}" == "0" ]]; then
        TEMPLATE_VARS[indent_style_line]="indent_style: tabs"
        TEMPLATE_VARS[code_indent]="0"
    fi

    # Handle React components
    if [[ -n "${PRESET_CFG[react_components]:-}" ]]; then
        TEMPLATE_VARS[naming_react_line]="react_components: ${PRESET_CFG[react_components]}"
        TEMPLATE_VARS[naming_react]="${PRESET_CFG[react_components]}"
    fi

    # Interactive customization
    if ! $DEFAULTS; then
        echo ""
        echo -e "${C_GRAY}━━━ 以下配置可 Enter 跳过 ━━━${C_RESET}"

        TEMPLATE_VARS[project_name]=$(read_default "  项目名称" "$(basename "$(pwd)")")
        TEMPLATE_VARS[project_description]=$(read_default "  一句话描述" "${TEMPLATE_VARS[project_description]}")
        TEMPLATE_VARS[git_commit_style]=$(read_default "  Commit 风格" "${TEMPLATE_VARS[git_commit_style]}")
        TEMPLATE_VARS[git_branch_naming]=$(read_default "  分支命名模板" "${TEMPLATE_VARS[git_branch_naming]}")
        TEMPLATE_VARS[code_indent]=$(read_default "  缩进空格数" "${TEMPLATE_VARS[code_indent]}")
        TEMPLATE_VARS[code_quotes]=$(read_default "  引号风格 [double/single]" "${TEMPLATE_VARS[code_quotes]}")
        TEMPLATE_VARS[code_semicolons]=$(read_default "  使用分号 [true/false]" "${TEMPLATE_VARS[code_semicolons]}")
        TEMPLATE_VARS[code_max_line_length]=$(read_default "  最大行宽" "${TEMPLATE_VARS[code_max_line_length]}")
        TEMPLATE_VARS[naming_files]=$(read_default "  文件命名风格" "${TEMPLATE_VARS[naming_files]}")
        TEMPLATE_VARS[naming_functions]=$(read_default "  函数命名风格" "${TEMPLATE_VARS[naming_functions]}")
        TEMPLATE_VARS[testing_framework]=$(read_default "  测试框架" "${TEMPLATE_VARS[testing_framework]}")
        TEMPLATE_VARS[aios_language]=$(read_default "  AI 输出语言 [zh-CN/en]" "${TEMPLATE_VARS[aios_language]}")

        local strict_input=$(read_default "  严格模式 [true/false]" "${TEMPLATE_VARS[aios_strict_mode]}")
        TEMPLATE_VARS[aios_strict_mode]="$strict_input"
    fi

    echo ""

    # Create directories
    local dirs=("ai/state" "ai/memory" "ai/rules/custom" "ai/specs" "ai/changes")
    for d in "${dirs[@]}"; do
        mkdir -p "$d"
    done

    # Process templates
    step "生成配置文件..."

    # config.yaml
    local config_tmpl=$(cat "$TEMPLATES_DIR/config.yaml")
    apply_template "$config_tmpl" > "ai/config.yaml"
    ok "  ai/config.yaml"

    # .version
    echo "$VERSION" > "ai/.version"
    ok "  ai/.version"

    # state files
    for f in current.md tasks.md roadmap.md; do
        local tmpl=$(cat "$TEMPLATES_DIR/state/$f")
        apply_template "$tmpl" > "ai/state/$f"
    done
    ok "  ai/state/* (3 个文件)"

    # memory files
    for f in decisions.md anti-patterns.md; do
        local tmpl=$(cat "$TEMPLATES_DIR/memory/$f")
        apply_template "$tmpl" > "ai/memory/$f"
    done
    cp "$TEMPLATES_DIR/memory/glossary.yaml" "ai/memory/glossary.yaml"
    ok "  ai/memory/* (3 个文件)"

    # rules files
    for f in hard-rules.yaml arch-rules.yaml module-rules.yaml style-rules.yaml git-rules.yaml test-rules.yaml security-rules.yaml error-rules.yaml logging-rules.yaml api-rules.yaml; do
        local tmpl=$(cat "$TEMPLATES_DIR/rules/$f")
        apply_template "$tmpl" > "ai/rules/$f"
    done
    cp "$TEMPLATES_DIR/rules/custom/.gitkeep" "ai/rules/custom/.gitkeep"
    ok "  ai/rules/* (10 files)"

    # specs and changes
    cp "$TEMPLATES_DIR/specs/.gitkeep" "ai/specs/.gitkeep"
    cp "$TEMPLATES_DIR/changes/.gitkeep" "ai/changes/.gitkeep"
    ok "  ai/specs/, ai/changes/ (已创建)"

    echo ""
    echo -e "${C_GREEN}════════════════════════════════════════════${C_RESET}"
    echo -e "${C_GREEN}  AIOS 初始化完成！${C_RESET}"
    echo -e "${C_GREEN}════════════════════════════════════════════${C_RESET}"
    echo ""
    echo "  下次启动 AI 工具时，pai:bootstrap 会自动加载项目配置。"
    echo "  如需跳过交互，使用: aios init --defaults"
    echo ""
}

# ═══════════════════════════════════════════════
# COMMAND: status
# ═══════════════════════════════════════════════
cmd_status() {
    echo ""
    echo -e "${C_CYAN}══════════ AIOS 项目状态 ══════════${C_RESET}"

    if [[ ! -d "ai" ]]; then
        warn "本项目未初始化 AIOS。"
        echo "  运行 aios init 初始化。"
        return
    fi

    # Version
    if [[ -f "ai/.version" ]]; then
        local proj_ver=$(cat "ai/.version")
        echo "  AIOS 版本: $proj_ver (当前: $VERSION)"
        if [[ "$proj_ver" != "$VERSION" ]]; then
            warn "    版本不一致，建议运行 aios update"
        fi
    fi

    # Config
    if [[ -f "ai/config.yaml" ]]; then
        local cfg_name=$(grep -m1 'name:' "ai/config.yaml" | grep -v 'preset' | sed 's/.*"\(.*\)".*/\1/')
        local cfg_preset=$(grep 'preset:' "ai/config.yaml" | sed 's/.*"\(.*\)".*/\1/')
        [[ -n "$cfg_name" ]] && echo "  项目: $cfg_name"
        [[ -n "$cfg_preset" ]] && echo "  预设: $cfg_preset"
    fi

    # State
    if [[ -f "ai/state/current.md" ]]; then
        local change=$(grep -A1 '当前激活的 Change' "ai/state/current.md" | tail -1 | sed 's/^[[:space:]]*//')
        [[ -n "$change" ]] && echo "  当前 Change: $change"
    fi

    # Active changes
    if [[ -d "ai/changes" ]]; then
        local changes=$(find "ai/changes" -maxdepth 1 -type d ! -name "changes" ! -name "archive" -exec basename {} \; 2>/dev/null)
        if [[ -n "$changes" ]]; then
            echo ""
            echo -e "  ${C_YELLOW}活跃 Changes:${C_RESET}"
            echo "$changes" | while read -r c; do
                echo "    - $c"
            done
        fi
    fi

    echo ""
}

# ═══════════════════════════════════════════════
# COMMAND: update
# ═══════════════════════════════════════════════
cmd_update() {
    echo ""
    echo -e "${C_CYAN}══════════ AIOS Update ══════════${C_RESET}"

    if [[ ! -f "ai/.version" ]]; then
        err "未找到 ai/.version，请先运行 aios init"
        return
    fi

    local proj_ver=$(cat "ai/.version")

    if [[ "$proj_ver" == "$VERSION" ]]; then
        ok "项目 AIOS 版本 ($proj_ver) 已是最新。"
        return
    fi

    echo "  当前项目版本: $proj_ver"
    echo "  最新版本: $VERSION"
    echo ""

    # Check for new rule templates
    local template_rules=$(find "$TEMPLATES_DIR/rules" -maxdepth 1 -type f ! -name ".gitkeep" -exec basename {} \; | sort)
    local project_rules=$(find "ai/rules" -maxdepth 1 -type f ! -name ".gitkeep" ! -path "*/custom/*" -exec basename {} \; | sort)

    local new_rules=$(comm -23 <(echo "$template_rules") <(echo "$project_rules"))
    if [[ -n "$new_rules" ]]; then
        echo -e "  ${C_YELLOW}新规则模板可用:${C_RESET}"
        echo "$new_rules" | while read -r rule; do
            echo "    - $rule"
        done
        echo -n "  是否添加？[Y/n]: "
        read -r add
        if [[ "$add" != "n" && "$add" != "N" ]]; then
            echo "$new_rules" | while read -r rule; do
                cp "$TEMPLATES_DIR/rules/$rule" "ai/rules/$rule"
                ok "    已添加 $rule"
            done
        fi
    fi

    # Update .version
    echo "$VERSION" > "ai/.version"
    ok "  版本已更新为 $VERSION"
    echo ""
}

# ═══════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════
case "$COMMAND" in
    init)   cmd_init ;;
    status) cmd_status ;;
    update) cmd_update ;;
    *)
        echo -e "${C_CYAN}AIOS CLI $VERSION${C_RESET}"
        echo ""
        echo "Usage:"
        echo "  aios init [--defaults] [--preset <name>] [--name <name>] [--tech <list>]"
        echo "  aios status"
        echo "  aios update"
        echo ""
        echo "Presets: node-typescript, python, go, rust, java, universal"
        ;;
esac
