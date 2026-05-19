# Changelog

## v1.3.0 (2026-05-16)

### Added
- `pai:story` skill — 5-step requirements analysis and prototype design
- ASCII prototype wireframes (`docs/prototype.md`)
- Page element data flow diagrams (`docs/data-flows.md`)
- Backend business flow swimlane diagrams (`docs/backend-flows.md`)
- API endpoint list and backend module summary (`docs/api-list.md`)
- Full-stack feature point tracking with PRD traceability (`docs/feature-points.md`)
- Seamless handoff to pai:design and pai:spec via auto-read of feature-points.md

## v1.2.0 (2026-05-16)

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
