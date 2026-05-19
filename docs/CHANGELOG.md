# Changelog

## v1.1.1 (2026-05-16)

### Added
- `pai:prd` skill — 7-stage product requirements document generation
- PRD outputs: `prd.md` + `personas.md` with ASCII user journey diagrams

### Fixed
- Cross-domain integration auto-detection in pai:spec (P0)
- Integration task generation for 3+ modules in pai:build (P0)
- 4-step review with import consistency and dead code detection
- Signal wiring diagrams in pai:design
- Soft-completion checks in pai:done
- Language-agnostic checks for Python/Node/Rust/Go/Java

## v1.0.0 (2026-05-16)

### Added
- 14 个核心技能：bootstrap / prd / init / retro / docs / design / amend / spec / build / debug / review / done / reflect / status
- 6 个预设配置档案：node-typescript / python / go / rust / java / universal
- 80 条项目规则（9 个文件）：hard / arch / security / error / logging / api / git / style / test
- 8 条全局 L1 红线
- 双平台适配：OpenCode + Claude Code
- 跨平台 CLI：PowerShell 5.1+ + bash 3.2+
- 个性化配置系统：ai/config.yaml + 预设档案
- 共存模式：standalone / complementary / ask
- 冲突检测：7 个重叠领域扫描
- Red Flags 防合理化表 + 压力测试机制
- 版本管理：ai/.version + aios update
- 集成测试用例：bootstrap + skill-chain

### Based on
- Superpowers 技能链模式
- OpenSpec spec/change 管理模式
- OWASP Cheat Sheet Series（安全/错误处理/日志）
- Google Code Review Standards
- Conventional Commits 1.0.0
- Prettier 3.x / PEP 8 / Effective Go / Rust Style Guide 默认值
