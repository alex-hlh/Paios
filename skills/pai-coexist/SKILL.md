---
name: pai-coexist
description: 多技能包共存管理 — 检测到其他 AI skill pack（如 Superpowers、OpenSpec）时，协商共存策略。提供 standalone / complementary / rules-only 三种模式。
triggers:
  - "共存管理"
  - "manage conflicts"
  - "mode select"
  - "compatibility mode"
  - "conflict"
  - "coexist"
  - "skill pack conflict"
  - "共存"
  - "冲突检测"
  - "other skills"
  - "multiple skills"
  - "技能包冲突"
---

# Coexist (pai:coexist)

**目的**：当环境中存在多个 AI skill pack 时，避免指令冲突。

## 触发条件

`pai:bootstrap` 在步骤 3 中检测以下任一条件时，自动触发此技能：

1. 注册技能列表中包含其他 skill pack 的技能名（如 `brainstorming`、`spec-driven`、`opsx:*`、`writing-plans`）
2. 项目目录中存在其他 skill pack 的痕迹（`docs/superpowers/`、`openspec/`、`.claude-plugin/`、`.cursor-plugin/`、`.codex-plugin/`）

## 重叠领域检测表

| 领域 | 检测关键词 | 冲突对手 |
|------|-----------|---------|
| 需求/设计 | brainstorming, spec-driven, prd-writer, opsx:propose/explore | pai:design / pai:prd |
| 任务/计划 | writing-plans, executing-plans, opsx:new/ff/continue | pai:spec / pai:build |
| 测试/TDD | test-driven-development, tdd, red-green-refactor | pai:build |
| 调试 | systematic-debugging, debugging | pai:debug |
| 代码审查 | requesting-code-review, receiving-code-review | pai:review |
| 收尾/归档 | finishing-a-development-branch, opsx:archive/verify | pai:done |
| Git 工作流 | using-git-worktrees, git-worktree | pai:done |
| 元技能/引导 | using-superpowers, bootstrap, init | pai:bootstrap / pai:init |

## 流程

### 1. 读取共存配置

读取 `ai/config.yaml` 中的 `aios.coexistence_mode`：
- `ask`（默认）→ 检测到冲突时暂停，展示结果让用户选择
- `standalone` → AIOS 完全接管，忽略其他 skill pack
- `complementary` → AIOS 退化为\"上下文注入器\"，仍加载规则和状态，但不触发技能链
- `rules-only` → 最轻量，只注入 L1 红线 + 规则

### 2. 展示选择面板

```
[AIOS] 检测到以下可能冲突的技能包/工具:

  技能重叠: brainstorming (Superpowers) ↔ pai:design (AIOS)
  ...
  项目痕迹: openspec/ 目录存在

请选择共存模式:

  A) AIOS 完全接管（忽略其他技能包）
  B) 互补模式（AIOS 仅提供规则和状态，工作流由其他技能包驱动）
  C) 仅注入规则（无技能链提示，规则作为背景约束）

你的选择: _
```

### 3. 持久化选择

写入 `ai/config.yaml`：
```yaml
aios:
  coexistence_mode: "standalone"  # 或 complementary / rules-only
  coexistence_detected: ["superpowers", "openspec"]
```

### 4. 按模式执行

| 模式 | 行为 |
|------|------|
| standalone | 忽略其他技能包，完整 AIOS 技能链生效 |
| complementary | 加载 L1 红线 + 规则 + 状态 + 配置，不注入技能链触发规则 |
| rules-only | 仅注入 L1 红线 + 规则，无状态读取，无技能链 |
