# Changelog

## [1.1.0] - 2026-05-20

### Added
### Added (P3)
- `pai:bootstrap` 瘦身 575→98 行 (26.7→2.3KB)，冲突检测抽出为独立 `pai:coexist` skill
- `pai:coexist` 新增 skill：多技能包共存管理（standalone/complementary/rules-only 三种模式）
- `pai:health` 新增 skill：项目健康度检查（配置完整性、规则一致性、state 时效性）
- 全 16 个 SKILL.md 补充英文触发词，中英双语触发
- 新增 `scripts/hooks/` git hooks 集成：pre-commit（密钥扫描+调试检查）+ commit-msg（Conventional Commits 校验）
- `docs/skill-standalone.md` 独立调用与降级规则文档
- `templates/prd-questions.md` PRD 问题框架模板
- `pai:init` 新增 git hooks 安装引导步骤

### Added
- `rules/` 补全 9 个缺失规则文件：arch-rules、module-rules、security-rules、error-rules、logging-rules、api-rules、git-rules、style-rules、test-rules
- 新增 Codex 平台适配（`platforms/codex/`），含 tool-map、INSTALL、plugin.json
- 新增 `.version` 版本文件，作为后续升级机制的参考锚点
- 新增 `scripts/validate.ps1` 完整性校验脚本（检查规则、frontmatter、平台、版本）
- 新增 `mcp/` MCP 服务器，支持通过 MCP 协议读取规则、预设、技能
- 新增 `docs/skill-interfaces.md` skill 间接口契约文档

### Changed
- `pai:story` 大幅精简：442 行 → 120 行（缩减 73%），移除冗余表格和重复门禁，保留核心 5 步流程
- `pai:init` 强化 preset 选择的交互提示
- `platforms/codex/INSTALL.md` 新增 MCP 安装方式

### Fixed
- `rules/` 目录仅有 hard-rules.yaml 一个文件的问题，规则体系不完整
- Codex 平台无适配支持，SKILL.md 中的工具映射在当前环境不可用
