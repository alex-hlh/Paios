---
name: pai-amend
description: 需求变更入口 — 开发中途新增/修改需求时使用。检测当前 change 状态，根据变更规模推荐策略（追加/新建/延期），协调变更文档和相关技能。
triggers:
  - "scope change"
  - "amend"
  - "change scope"
  - "add requirement"
  - "追加需求"
  - "新增功能"
  - "改需求"
  - "需求变了"
  - "还要加"
  - "顺便做"
  - "也做一个"
  - "amendment"
---

# Amend (pai:amend)

## 触发场景

任何时候说以下类似语句都触发 `pai:amend`：
- "还要加个验证码"
- "顺便做个权限管理"
- "需求变了，改成 OAuth 登录"
- "这个功能也一起做了吧"
- "/pai:amend"

## 流程

### 步骤 1: 检测当前状态

使用 {file-read} 读取 `ai/state/current.md` 获取当前 change 和进度：

```
检测结果示例:
  Current change: add-user-login
  Phase: build
  Tasks: 3/8 complete
  TDD state: green (Task 2.2 in progress)
```

如果没有活跃 change（全新请求），自动跳转到 `pai:design`。

### 步骤 2: 分析变更关系

根据新需求与当前 change 的关系，用以下判断树分类：

```
新需求 ←→ 当前 change
     │
     ├── 同一领域/模块? (如: 登录 ←→ 验证码)
     │   └── 变更量 <2 个 task? → 策略 1: 追加到当前 change
     │
     ├── 当前 tasks 完成 <30%?
     │   └── 改动设计不大? → 策略 1: 追加
     │
     ├── 独立功能模块?
     │   └── 改动量 ≥3 个 task? → 策略 2: 新建并行 change
     │
     └── 规模过大 / 需求模糊?
         └── → 策略 3: 延期到 roadmap
```

### 步骤 3: 展示决策面板

```
+============================================+
|  SCOPE CHANGE ANALYSIS                      |
+============================================+
|                                            |
|  Current:   add-user-login                 |
|  Progress:  [###           ] 37%  (3/8)    |
|  Phase:     build (Task 2.3 login endpoint) |
|                                            |
|  New:       add-2fa                        |
|                                            |
|  Relationship: both in auth domain         |
|  Estimated impact: +2 tasks                |
|  Recommendation: APPEND to current change  |
|                                            |
|  A) Append to current  (recommended)       |
|  B) New parallel change                    |
|  C) Defer to roadmap                       |
|                                            |
+============================================+
```

### 步骤 4: 执行选择

**策略 A: 追加到当前 change**

```
1. 用 {file-read} 读取 ai/changes/<name>/proposal.md
2. 用 {file-edit} 追加新 scope 条目到 proposal.md
3. 用 {file-read} 读取 ai/changes/<name>/design.md
4. 用 {file-edit} 补充设计方案到 design.md
5. 询问用户: "需要新增 tasks 吗？"
   - 是 → 触发 pai:spec (增量模式，只追加新 task）
   - 否 → 手动在 tasks.md 添加 `- [ ] <新task>`
6. 继续 pai:build
```

**策略 B: 新建并行 change**

```
1. 用 {file-edit} 在 ai/state/current.md 标记当前进度:
   当前 change: add-user-login, add-2fa
   说明: "两个 change 并行, 先完成哪个?"
2. 触发 pai:design → 创建新 change 目录
3. 新 change 独立走完整流程
4. 归档时 pai:done 检测 spec 冲突
```

**策略 C: 延期**

```
1. 用 {file-read} 读取 ai/state/roadmap.md
2. 用 {file-edit} 追加到下一版本:
   ## v1.1 (规划中)
   - add-2fa  (依赖: add-user-login 完成)
3. 输出: "已记录到 roadmap v1.1，当前继续 pai:build"
```

### 步骤 5: 输出操作摘要

```
+============================================+
|  AMENDMENT APPLIED                          |
+============================================+
|  Strategy: APPEND to add-user-login        |
|                                            |
|  Updated:                                   |
|    ai/changes/add-login/proposal.md        |
|    ai/changes/add-login/design.md           |
|    ai/changes/add-login/tasks.md (+2 new)  |
|                                            |
|  Next: continue pai:build                  |
+============================================+
```

## 注意事项

- **不中断当前工作** — 如果是策略 A，直接在现有 change 中追加
- **不丢失进度** — 已完成 tasks 保持勾选状态
- **冲突防护** — 策略 B 时，pai:done 归档自动检测 spec 冲突
- **可多次调用** — 任何时候说"还要加"都可以触发
