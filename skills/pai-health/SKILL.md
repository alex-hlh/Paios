---
name: pai-health
description: 项目健康度检查 — 验证 AIOS 配置完整性、规则一致性、state 时效性、版本滞后情况。发现异常输出修复建议。
triggers:
  - "health"
  - "health check"
  - "check status"
  - "verify project"
  - "project health"
  - "项目健康"
  - "检查状态"
  - "完整性检查"
  - "verify setup"
---

# Health (pai:health)

**目的**：定期检查项目 AIOS 配置是否完整、规则是否一致、状态是否过期。

## 检查项

| # | 检查项 | 方法 | 严重度 |
|:-:|-------|------|:----:|
| 1 | `ai/config.yaml` 完整性 | 检查必填字段是否存在 | 🔴 阻塞 |
| 2 | `ai/state/current.md` 更新时间 | 检查文件最后修改时间 | 🟡 警告（>7天） |
| 3 | `ai/state/roadmap.md` 更新时间 | 检查文件最后修改时间 | 🟢 提示（>30天） |
| 4 | `ai/rules/` 文件数量 vs 模板 | 检查 `templates/rules/*.yaml` 数量 | 🟡 警告 |
| 5 | `ai/memory/` 文件存在性 | `decisions.md`, `anti-patterns.md`, `glossary.yaml` | 🟡 警告 |
| 6 | `.version` vs 最新版 | 读取 `.version` 比较 | 🟢 提示 |
| 7 | `ai/specs/` 是否有未完成的 change | 检查 `ai/state/current.md` | 🟢 提示 |

## 流程

### 1. 检查 `ai/config.yaml`

必填字段：`project.name`, `preset`, `conventions.git.commit_style`, `conventions.code.indent`, `aios.strict_mode`

```
[config.yaml] project.name:           "MyApp"                ✅
[config.yaml] preset:                 "node-typescript"      ✅
[config.yaml] aios.strict_mode:       true                   ✅
[config.yaml] conventions.code:       indent=2, quotes="     ✅
```

### 2. 检查 state 时效性

```
[state/current.md]   last modified: 2026-05-19    ✅ (6h ago)
[state/roadmap.md]   last modified: 2026-04-01    ⚠️  (49 days ago, suggest review)
[state/tasks.md]     last modified: 2026-05-18    ✅ (2d ago)
```

### 3. 检查规则完整性

```
[rules check]  templates: 10 files  |  project: 10 files  ✅
```

### 4. 输出摘要

```
+============================================+
|  AIOS Health Report                        |
+============================================+
|                                            |
|  Overall: 🟡  Fair (1 warning, 0 critical) |
|                                            |
|  ✅ Config:             完整               |
|  ⚠️  Roadmap:           49天未更新          |
|  ✅ Rules:              10/10 一致          |
|  ✅ Memory:             3/3 完整            |
|  ✅ Version:            v1.1.0 (最新)      |
|                                            |
|  Suggestions:                              |
|  1. Review and update ai/state/roadmap.md   |
|                                            |
+============================================+
```

## 建议修复

| 问题 | 建议 |
|------|------|
| `ai/rules/` 文件数少于模板 | 运行 `pai:init` 或手动复制缺失规则 |
| `state/` 文件过期 | 询问用户是否有新进展，更新状态 |
| `.version` 落后 | 运行 `git pull` 更新技能包 |
| 缺少 `memory/` 文件 | 自动创建模板文件 |
