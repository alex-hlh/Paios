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

## 独立调用检查

如果通过 `/pai:spec` 或自然语言直接调用（非链式触发），先检查依赖：

```
检查前置条件:
  [ ] ai/changes/<name>/proposal.md   → 必须。缺失则提示：请先完成 pai:design
  [ ] ai/changes/<name>/design.md     → 必须。缺失则提示：请先完成 pai:design
  [ ] ai/specs/                       → 可选。无则假设无现有 spec，只生成 ADDED
  [ ] ai/config.yaml                  → 可选。无则使用 universal 预设

依赖不满足时输出:
  "pai:spec 需要 design 阶段的输出。请先运行 pai:design 完成需求设计，
   或提供已有的 proposal + design 文件路径。"
```

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

### 步骤 2.5: 自动补全缺失需求类型

Delta spec 生成后，检查以下模式并自动追加需求。这些需求跨越单个 domain，确保系统完整性。

**检测 1：多 domain 集成需求**

如果 domains 数量 ≥ 3 或 requirement 数量 ≥ 6，追加：

```markdown
## ADDED Requirements

### Requirement: 跨模块流水线集成
系统 MUST 实现完整的端到端流水线，串联所有模块。
检测方式：如果存在 3 个以上 domains，必须生成一个集成 requirement。

#### Scenario: 端到端执行
- GIVEN 系统所有模块已实现
- WHEN 触发完整流水线
- THEN 数据按定义顺序流经每个模块
- AND 最终结果正确输出
```

**检测 2：配置持久化需求**

如果任何 spec 中出现 `apiKey`、`config`、`settings`、`budget`、`API Key` 等关键词，追加：

```markdown
### Requirement: 配置持久化
系统 MUST 将用户配置（API Key、预算、模式选择等）持久化到本地文件。
系统 MUST 启动时自动读取并恢复上一次的配置。

#### Scenario: 配置保存与恢复
- GIVEN 用户修改了配置项（如 API Key）
- WHEN 系统关闭或重启
- THEN 配置被正确保存并恢复

#### Scenario: 配置缺失
- GIVEN 首次启动，无配置文件
- WHEN 系统初始化配置模块
- THEN 使用默认值启动
- AND 提示用户补全必要配置
```

**检测 3：应用入口点需求**

如果 requirement 总数 ≥ 5，追加：

```markdown
### Requirement: 应用引导
系统 MUST 提供统一入口点（如 main.py），初始化所有组件、建立连接、启动生命周期。

#### Scenario: 正常启动
- GIVEN 所有模块已就绪
- WHEN 用户启动应用
- THEN 入口点装配所有组件
- AND 应用进入可用状态
```

**检测 4：资源文件需求**

如果任何 spec 中出现 `GIF`、`动画`、`图标`、`QLabel`、`QMovie`、`resources` 等关键词，追加：

```markdown
### Requirement: 资源文件
系统 MUST 包含运行时需要的资源文件（GIF、图标等），并正确加载。

#### Scenario: 资源加载
- GIVEN 资源文件存在于预期路径
- WHEN 应用加载资源
- THEN 所有资源正确显示
- AND 资源缺失时优雅降级
```

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
