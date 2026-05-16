---
name: pai-spec
description: Spec 与 Change 管理 — 生成 delta spec（ADDED/MODIFIED/REMOVED）、tasks.md、变更时间戳。归档时合并 delta 到主 spec。
triggers:
  - "design approved"
  - "spec"
  - "generate tasks"
  - "create change"
  - "生成任务"
  - "写规格"
---

# Spec & Change (pai:spec)

## 流程

### 步骤 1: 读取上下文
- 读取 `ai/changes/<change-name>/proposal.md` 和 `design.md`
- 读取 `ai/specs/` 下现有的所有 spec 文件（用于识别 MODIFIED 和 REMOVED）
- 读取 `ai/config.yaml` 了解技术栈

### 步骤 2: 生成 Delta Spec

在 `ai/changes/<change-name>/specs/<domain>/spec.md` 写入 delta spec，格式与 OpenSpec 兼容：

```markdown
# Delta for <Domain>

## ADDED Requirements

### Requirement: <标题>
系统 SHALL/MUST/SHOULD <行为描述>

#### Scenario: <场景名>
- GIVEN <前置条件>
- WHEN <触发动作>
- THEN <预期结果>
- AND <附加条件>

## MODIFIED Requirements

### Requirement: <标题>
<修改后的完整描述>
(Previously: <修改前的描述>)

#### Scenario: <场景名>
- GIVEN ...
- WHEN ...
- THEN ...

## REMOVED Requirements

### Requirement: <标题>
(Reason: <移除原因>)
```

**格式要求**:
- 使用 SHALL/MUST/SHOULD/MAY 表达需求强度
- 每个 Requirement 至少一个 Scenario
- Scenario 覆盖正常路径和边界情况
- 需求描述行为而非实现——不写类名、函数名、框架选择
- 新增 spec domain（如 `auth/`）时自动创建对应目录

### 步骤 3: 生成 Tasks

在 `ai/changes/<change-name>/tasks.md` 写入实施清单：

```markdown
# Tasks

## 1. <分类名>
- [ ] 1.1 <具体任务描述，2-5分钟可完成>
- [ ] 1.2 <下一个任务>

## 2. <分类名>
- [ ] 2.1 <任务>
- [ ] 2.2 <任务>
```

**Task 规范**:
- 每个 task 2-5 分钟粒度
- 层级编号（1.1, 1.2, 2.1...）
- 按实现顺序排列
- 从测试先行的角度排列：基础设施 → 测试 → 实现 → 集成
- 所有文件路径使用 `ai/` 或项目相对路径前缀

写入 tasks.md 后，同时向用户展示 ASCII 任务树，便于理解任务依赖和执行顺序：

```
+-- add-user-login: Task Tree
|
+-- 1. Infrastructure        [2 tasks]
|   +-- 1.1 Create User model
|   \-- 1.2 Add data validation
|
+-- 2. Auth Logic            [3 tasks]
|   +-- 2.1 JWT token utility
|   +-- 2.2 Auth middleware
|   \-- 2.3 Login endpoint
|
\-- 3. Integration           [3 tasks]
    +-- 3.1 Login page
    +-- 3.2 Error handling
    \-- 3.3 End-to-end test

Total: 8 tasks  |  Estimated: 30-45 min

### 步骤 4: 写入变更时间戳

在 `ai/changes/<change-name>/.openspec.yaml` 写入：

```yaml
created: {ISO 8601 timestamp}
change: <change-name>
domains:
  - <domain1>
  - <domain2>
```

此时间戳用于 `pai:done` 归档时冲突检测。

### 步骤 5: 输出摘要

```
+============================================+
|          SPEC 已生成                        |
+============================================+
|                                            |
|  Change:       add-user-login              |
|  Domain:       auth                        |
|  Requirements: 3 ADDED / 0 MOD / 0 REMOVE  |
|  Scenarios:    6                           |
|  Tasks:        8                           |
|                                            |
+-- Spec Structure --------------------------+
|                                            |
|  ai/specs/auth/spec.md      (new)          |
|  ai/changes/add-user-login/                |
|    +-- proposal.md                         |
|    +-- design.md                           |
|    +-- tasks.md                            |
|    +-- spec/auth/spec.md   (delta)         |
|    \-- .openspec.yaml                      |
|                                            |
+============================================+
```

## 规格格式检查

生成后自查：
- [ ] 所有 Requirement 有对应的 Scenario
- [ ] Scenario 使用 GIVEN/WHEN/THEN 格式
- [ ] 需求描述行为而非实现
- [ ] SHALL/MUST/SHOULD 使用正确
- [ ] tasks 层级编号连续
- [ ] 文件路径使用 `ai/` 前缀

## 完成后

触发 `pai:build` 开始实现。不要直接开始编码 — 必须等用户确认。
