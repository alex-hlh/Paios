---
name: pai-story
description: 需求分析与原型设计 — 从 PRD 或用户描述出发，输出界面原型图、数据流图、后台流程、接口清单和功能点。产出供 pai:design 和 pai:spec 直接使用。
triggers:
  - "user story"
  - "requirement analysis"
  - "需求调研"
  - "功能规划"
  - "原型"
  - "story"
  - "prototype"
  - "product design"
  - "需求分析"
  - "画原型"
  - "功能点"
  - "原型图"
  - "需求文档"
---

# Story (pai:story)

**目的**：将 PRD 或用户需求转化为可执行的工程输入。输出 5 个产物供下游 skill 使用。

**定位**：`pai:prd`（产品规划）→ **`pai:story`（需求分析+原型）** → `pai:design`（技术设计）→ `pai:spec`（变更管理）

**不替代 pai:design** — Story 产出业务需求和原型，Design 产出技术方案。不生成代码。

---

## 流程（5 步）

### 第一步：理解 PRD / 需求范围

**输入**：`ai/prd.md`（如有）或用户口头描述

- 如果 `ai/prd.md` 存在，先读取它
- 输出需求范围确认表，让用户确认后进入下一步

```
需求范围: 用户认证
  ├─ 登录 (邮箱/密码 + 第三方 OAuth)
  ├─ 注册 (邮箱 + 密码验证)
  └─ 密码重置 (邮件链接)
范围正确吗？[Y/n]
```

> 如果用户想跳过此步直接给需求，进入第二步。

---

### 第二步：界面原型（页面与交互）

**目标**：用 ASCII 原型图描述关键页面布局和交互流程。

- 基于需求范围，画出每个页面的线框图
- 标注核心交互路径（按钮 → 弹窗 → 跳转）
- 每个原型图应有简短说明

```
┌────────────────────────────────┐
│  登录页                         │
│                                │
│  [邮箱输入框]                   │
│  [密码输入框]                   │
│  [记住我] [忘记密码?]            │
│                                │
│  [      登  录      ]          │
│  ─── or ───                    │
│  [Google] [GitHub] [微信]      │
│                                │
│  没有账号? [注册]               │
└────────────────────────────────┘
→ 登录成功 → 首页
→ 忘记密码 → 密码重置页
→ 三方登录 → OAuth 回调处理
```

**产出**：写入 `ai/prototype.md`

---

### 第三步：数据流与 API 接口

**目标**：从原型图中提取前端数据流和后端 API 接口。

- 分析每个页面的数据需求，画出数据流向
- 列出所有 API 接口（方法、路径、参数、响应）

```
[登录页]
  ├─ POST /api/auth/login          { email, password }    → { token, user }
  ├─ GET  /api/auth/oauth/{provider}                     → redirect to provider
  └─ POST /api/auth/oauth/callback { code }              → { token, user }

[注册页]
  └─ POST /api/auth/register       { nickname, email, password } → { token, user }
```

**产出**：数据流写入 `ai/data-flows.md`，API 清单写入 `ai/api-list.md`

---

### 第四步：后台业务流程

**目标**：描述每个 API 背后完整的业务逻辑和数据处理流程。

```
POST /api/auth/login:
  1. 验证参数 (email+password 非空)
  2. 查询 User by email
  3. bcrypt 比对密码
  4. 检查登录失败次数 (超过 5 次锁定 15min)
  5. 生成 JWT (HS256, 24h)
  6. 返回 { token, user }

POST /api/auth/register:
  1. 验证参数 (昵称/邮箱/密码格式)
  2. 检查邮箱是否已注册 (冲突 → 409)
  3. bcrypt 哈希密码
  4. 创建 User 记录
  5. 生成 JWT
  6. 返回 { token, user }
```

**产出**：写入 `ai/backend-flows.md`

---

### 第五步：汇总功能点

**目标**：生成可供 `pai:spec` 和 `pai:design` 直接使用的功能清单。

- 自动从前面 4 步提取，无需额外提问
- 逐类展示并让用户确认

```
前端功能点:
├─ 页面: 登录页 (邮箱/密码/记住我/提交/OAuth)、注册页
├─ 交互: 表单校验、API 调用、状态处理（成功跳转/失败提示）
└─ 存储: token → localStorage

后端功能点:
├─ API: POST /api/auth/login, POST /api/auth/register, GET /api/auth/oauth/{provider}
├─ 业务: bcrypt 验证、JWT 生成、登录失败限制
├─ 数据: User { id, nickname, email, password_hash, login_attempts... }
└─ 安全: 密码强度、频率限制

功能点正确完整吗？[Y/n]
```

**产出**：功能追溯表写入 `ai/feature-points.md`

```
| 功能点 | 来源 PRD | MoSCoW | 关联 Story |
|--------|---------|:-----:|:----------:|
| 登录页 UI | 用户认证 | Must | US-01 |
| 注册页 UI | 用户认证 | Must | US-02 |
| JWT 认证 | 用户认证 | Must | US-03 |
| 登录失败限制 | 安全性 | Should | US-04 |
```

---

## 完成输出

```
+============================================+
|  pai:story 完成 — 需求分析与原型设计         |
+============================================+
|                                            |
|  产出物:                                    |
|    ai/prototype.md       ✅                 |
|    ai/data-flows.md      ✅                 |
|    ai/backend-flows.md   ✅                 |
|    ai/api-list.md        ✅                 |
|    ai/feature-points.md  ✅                 |
|                                            |
+============================================+
|  下一步: /pai:design — 自动读取功能点开始设计 |
+============================================+
```

## 与 pai:design / pai:spec 的衔接

`pai:story` 完成后，`pai:design` 自动读取 `ai/feature-points.md`（导入功能点列表，跳过发现式提问）和 `ai/api-list.md`（作为 Spec 的 API 层输入）。

## 局部迭代

如需修改某一步（如仅更新原型图），通过 `/pai:amend` 管理变更范围。可以指定步骤编号重新运行（如"重新做第三步"）。
