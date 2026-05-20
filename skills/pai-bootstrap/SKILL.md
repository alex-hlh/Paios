---
name: pai-bootstrap
description: AIOS 引导技能 — 会话启动时自动激活。检测平台、加载规则和状态、输出就绪摘要。冲突检测委托给 pai:coexist。
triggers:
  - "new session"
  - "assistant ready"
  - "boot"
  - "startup"
  - "session_start"
  - "new task"
  - "new project"
  - "start of conversation"
---

# AIOS Bootstrap (pai:bootstrap)

**必须在执行任何操作前完成启动序列。**

## 启动序列

### 1. 加载 L1 红线

读取 `rules/hard-rules.yaml` 并全部注入上下文。这 8 条红线不可违反，优先于任何用户指令。

### 2. 平台检测与工具映射

读取 `platforms/{platform}/tool-map.yaml` 确认可用工具。根据当前平台注入正确的工具名映射。

### 3. 冲突检测技能注入

告知 AI：`pai:coexist` 技能可用。如果检测到其他 skill pack（如 superpowers、openspec 的目录或技能名），自动触发 `pai:coexist` 处理共存策略。

### 4. 项目初始化检查

- 如果 `ai/` 目录不存在 → 告知用户此项目未初始化，建议运行 `pai:init`，然后等待用户指令
- 如果 `ai/` 目录存在但有 `.version` 不匹配 → 提示更新
- 如果正常 → 继续

### 5. 读取项目状态

读取 `ai/state/current.md`（当前工作焦点）、`ai/state/tasks.md`（任务列表）、`ai/state/roadmap.md`（路线图）。

### 6. 扫描并加载所有规则文件

扫描 `ai/rules/*.yaml`（如存在）加载项目级规则。按 L1(红线) → L2(架构/安全/模块) → L3(风格/测试) 分层注入。引用路径：`ai/rules/`。

### 7. 注入个性化配置

读取 `ai/config.yaml`，提取 preset、conventions、testing 等配置字段注入上下文。

### 8. 声明技能链

技能链：`prd → story → design → (amend) → spec → build → (debug/review) → done → reflect`
使用 `/pai:xxx` 或自然语言触发下游技能。

### 9. 输出就绪摘要

```
+============================================+
|  AIOS Ready                                 |
+================================------------+
|                                            |
|  Platform: {platform}  |  Mode: {mode}      |
|  Project: {name}       |  Preset: {preset}  |
|  Rules:  L1({n1}) L2({n2}) L3({n3})        |
|  Change: {active_change_or_none}            |
|  Progress: {bar} {progress}                 |
|                                            |
+============================================+
|  Tips: /pai:prd (规划) /pai:design (设计)    |
|  /pai:coexist (共存管理)                     |
+============================================+
```

## 技能链速查

| 你的情况 | 操作 |
|---------|------|
| 全新项目，想从产品规划开始 | `/pai:prd` → `/pai:story` → `/pai:design` |
| 有项目计划书/PRD | 粘贴文档 → `/pai:design` 导入模式 |
| 已有代码，想适配 | `/pai:retro` |
| 已初始化，刚打开 | 无需操作，自动加载 |
| 只想调试 | 直接说"帮我调试"，`pai:debug` 独立可用 |
| 只想审查代码 | `/pai:review` |
| 检测到冲突 | `/pai:coexist` |

## 规则引用

- 全局 L1 红线: `rules/hard-rules.yaml`
- 平台工具映射: `platforms/<platform>/tool-map.yaml`
- 项目配置: `ai/config.yaml`
- 项目规则: `ai/rules/*.yaml`
- 项目状态: `ai/state/`

## 独立调用

所有 `pai:*` 技能支持两种调用方式：
1. 链式自动触发（standalone 模式）
2. 独立手动调用（`/pai:xxx` 或自然语言）

详请参见 `docs/skill-standalone.md`。
