# Templates shared library — sourced by aios.sh and aios.ps1
# This file contains documentation for the template variable substitution system.
#
# Template Variables:
#
# Project info:
#   {project_name}              → 项目名称
#   {project_description}       → 项目描述
#   {date}                      → 当前日期
#   {preset_name}               → 预设档案名称
#
# Git:
#   {git_commit_style}          → conventional
#   {git_branch_naming}         → feature/<name>
#   {git_sign_commits}          → false
#
# Code style:
#   {code_indent}               → 2 | 4 | 0 (0 = tabs)
#   {code_quotes}               → double | single
#   {code_semicolons}           → true | false
#   {code_trailing_commas}      → all | es5 | none
#   {code_max_line_length}      → 80 | 88 | 100 | 120 | 0 (unlimited)
#
# Naming:
#   {naming_files}              → kebab-case | PascalCase | camelCase | snake_case
#   {naming_functions}          → camelCase | snake_case
#   {naming_classes}            → PascalCase
#   {naming_constants}          → UPPER_SNAKE_CASE | PascalCase
#   {naming_variables}          → camelCase | snake_case
#   {naming_react_line}         → react_components: PascalCase (conditional)
#
# Testing:
#   {testing_framework}         → vitest | pytest | go test | cargo test | junit
#   {testing_coverage_threshold} → 80
#   {testing_require_integration} → true | false
#
# AIOS:
#   {aios_language}             → zh-CN | en
#   {aios_strict_mode}          → true | false
#
# State:
#   {current_change}            → 当前激活的 Change
#   {current_sprint}            → 当前 Sprint
#   {blockers}                  → 阻塞项
#   {next_actions}              → 下一步行动
#   {task_summary}              → 任务摘要
#   {date_range}                → 日期范围
#   {tech_stack}                → 技术栈
#   {iso8601}                   → ISO 8601 时间戳
#
# Conditional lines:
#   {indent_style_line}         → indent_style: tabs (only for Go preset)
#   {naming_react_line}         → react_components: PascalCase (only for React presets)
#
# All conditional placeholders are removed from output if their value is empty.
