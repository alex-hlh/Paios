---
name: pai-reflect
description: 自我反思 — 每次 pai:done 完成后自动激活。回顾本次 change 的执行偏差、意外情况和技能改进机会。结果写入 ai/memory/decisions.md。
triggers:
  - "after archive"
  - "after pai:done"
  - "reflect"
  - "反思"
  - "复盘"
---

# Reflect (pai:reflect)

## Standalone Usage

`pai:reflect` 可以独立回顾任何阶段的工作，不要求已完成完整 change。

```
依赖检查 (独立调用):
  [ ] ai/memory/decisions.md  → 可选。有则追加记录，无则仅口头输出
  [ ] 回顾对象                  → 任意。一个 change / 一个 task / 一次调试 / 一次审查

降级行为:
  - 无 ai/memory/ → 复盘结果仅展示不持久化，建议运行 pai:init 初始化
  - 无 change 上下文 → 询问用户"你想复盘什么？" 支持任意主题

独立调用示例:
  - /pai:reflect → "回顾本次会话的工作"
  - "复盘一下刚才的调试经历"
  - "总结这个功能的设计决策"
```

## 流程

### 步骤 1: 回顾本次 Change 完整过程

在脑海中回溯本次开发闭环：

```
pai:design → pai:spec → pai:build → (pai:debug / pai:review) → pai:done
```

回顾以下维度：
- 设计阶段：是否充分讨论了需求和方案？
- Spec 阶段：delta spec 和 tasks 是否准确？
- 实现阶段：TDD 循环是否严格遵守？
- 调试阶段：是否遇到了 bug？为什么？
- 审查阶段：发现了哪些问题？
- 整体：有没有地方能做得更好？

### 步骤 2: 回答三个自检问题

逐一回答并记录答案：

**问题 1: 这次有哪些地方流程走偏了？技能指令是否未被遵守？**

如果是，为什么会跳过？是技能指令不够清晰，还是当时的情况特殊？

**问题 2: 遇到了什么意外情况？需要记录为反模式吗？**

例如：
- 某个设计假设一开始就是错的
- 遇到了意料之外的边界条件
- 某段代码反复修改多次才正确
- 某个测试场景容易被遗漏

如果是可复用的教训，建议添加到 `ai/memory/anti-patterns.md`。

**问题 3: 需要更新哪个技能的指令来防止下次再犯？**

如果某个技能指令不够清晰导致了本次偏差，提出具体的修改建议（哪个技能、哪个段落、如何修改）。

### 步骤 3: 写入 decisions.md

使用 {file-read} 读取 `ai/memory/decisions.md`，在文件顶部（标题之后）追加新条目：

```markdown
---

## {date}: {change-name} 复盘

### 流程执行
- 偏差: {流程走偏的描述 或 "无显著偏差"}
- 原因: {原因}

### 意外情况
- {意外情况及处理 或 "无"}

### 技能改进建议
- {建议 或 "无"}
```

## 输出摘要

向用户展示反思结果，使用 ASCII 复盘面板：

```
+============================================+
|          CHANGE RETROSPECTIVE               |
+============================================+
|                                            |
|  Change:    add-user-login                 |
|  Duration:  2h 15m (8 tasks)               |
|                                            |
+-- Process Adherence -----------------------+
|                                            |
|  design:    OK  |  spec:    OK             |
|  build:     OK  |  debug:   N/A            |
|  review:    OK  |  done:    OK             |
|                                            |
+-- Surprises -------------------------------+
|                                            |
|  1. JWT expiresIn default was unclear      |
|  2. TypeORM migration order needed tweak   |
|                                            |
+-- Improvement Suggestions -----------------+
|                                            |
|  - Add JWT expiry to spec template         |
|  - Improve pai:design database guidance    |
|                                            |
+============================================+
|  Recorded: ai/memory/decisions.md          |
+============================================+
```

**简单版（无意外情况时）：**
```
=== RETROSPECTIVE: add-user-login ===
Process:  OK (no deviations)
Surprises: 0
Improvements: none
Recorded: ai/memory/decisions.md
```

## 注意

- 反思是建设性的，目的是持续改善，不是自责
- 如果一切顺利，也值得记录——说明流程有效
- 如果提出了技能改进建议，提醒用户（或在下次更新技能包时考虑）
