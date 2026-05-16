---
name: pai-design
description: 需求讨论与设计 — 在任何编码前使用。通过一问一答澄清需求、探索方案、分节展示设计，用户确认后生成 proposal + design 文档。
triggers:
  - "new feature"
  - "add feature"
  - "implement"
  - "build"
  - "design"
  - "create"
  - "modify behavior"
  - "我要做"
  - "帮我设计"
  - "增加功能"
  - "新功能"
---

# Design (pai:design)

## 核心规则

<HARD-GATE>
在用户明确批准设计之前，不得调用任何实现技能（pai:spec, pai:build）、编写任何代码或采取任何实现行动。这适用于所有项目，无论多简单。
</HARD-GATE>

## 流程

使用 {task-manager} 创建以下任务并逐个完成：

### 阶段 1: 探索项目上下文
- 使用 {search-glob} 和 {file-read} 检查项目现有文件、文档
- 读取 `ai/` 目录下的当前状态和已有 specs
- 读取 `ai/config.yaml` 了解技术栈和规范
- 读取 `ai/rules/` 了解架构和风格约束

### 阶段 2: 需求澄清（一问一答）
- 一次只问一个问题
- 优先使用选择题，开放问题也可
- 每次一个话题——如需要深入，拆为多个问题
- 聚焦：目的、约束、成功标准
- 如果需求涉及多个独立子系统，先标记出来，帮助用户拆解为子项目

### 阶段 3: 方案探索
- 提出 2-3 种不同方案，含利弊对比
- 先展示推荐方案及其理由
- 让用户选择方向

### 阶段 4: 分节展示设计
- 每节 200-300 字
- 覆盖：架构、组件、数据流、错误处理、测试
- 每节确认："这部分看起来对吗？"
- 随时准备回头澄清

### 阶段 5: 写入设计文档
用户确认后，写入 `ai/changes/<change-name>/`：

**proposal.md**:
```markdown
# Proposal: <title>

## Intent
<为什么做这个>

## Scope
在范围内:
- <item>
不在范围内:
- <item>

## Approach
<技术方案概述>
```

**design.md**:
```markdown
# Design: <title>

## Technical Approach
<技术方案详情>

## Architecture Decisions
<关键决策及原因>

## Data Flow
<数据流描述>

## File Changes
- <受影响的文件列表>
```

### 阶段 6: 设计文档自检
写入后自查：
1. 是否有占位符(TBD/TODO)或未完成部分？
2. 是否有内部矛盾？
3. 范围是否在一个实现计划内？
4. 是否有模糊需求（两种不同解读）？

### 阶段 7: 用户审查
提示用户审查 `ai/changes/<change-name>/proposal.md` 和 `design.md`，确认后进入下一阶段。

## 设计原则

- **隔离与清晰**: 将系统拆为小单元，每个单元有明确目的、定义良好的接口、可独立测试
- **YAGNI**: 删除不必要的功能
- **在现有代码库中工作**: 探索现有结构后再提方案，遵循既有模式，不做无关重构
- **遵循配置**: 遵循 `ai/config.yaml` 中的 conventions（命名、代码风格等）

## 完成后

设计文档确认后，触发 `pai:spec` 生成 delta spec 和 tasks。
