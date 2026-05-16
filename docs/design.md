# AIOS 技能包 — 完整设计文档 v1.0

> 融合 Superpowers 技能链 + OpenSpec 变更管理 + 外部教训优化 + 主流规范默认值

---

## 第一节：顶层目录结构

```
aios-skill-pack/
├── skills/                              # 核心：全部 AI 技能定义
│   ├── pai-bootstrap/
│   │   └── SKILL.md                     # 元技能（启动引导、压力测试、Red Flags）
│   ├── pai-design/
│   │   └── SKILL.md                     # 需求 → 设计文档
│   ├── pai-spec/
│   │   └── SKILL.md                     # Spec/Change 管理
│   ├── pai-build/
│   │   └── SKILL.md                     # 红-绿-重构 TDD 循环
│   ├── pai-debug/
│   │   └── SKILL.md                     # 系统调试（4 步法）
│   ├── pai-review/
│   │   └── SKILL.md                     # 自我审查
│   ├── pai-done/
│   │   └── SKILL.md                     # 归档 + 冲突检测 + 自我反思
│   └── pai-reflect/
│       └── SKILL.md                     # 技能自检与自我修复
│
├── rules/                               # L1 通用红线（平台无关）
│   └── hard-rules.yaml
│
├── templates/                           # ai/ 项目模板骨架
│   ├── config.yaml                      # 个性化总入口
│   ├── presets/                         # 预设配置档案
│   │   ├── node-typescript.yaml
│   │   ├── python.yaml
│   │   ├── go.yaml
│   │   ├── rust.yaml
│   │   ├── java.yaml
│   │   └── universal.yaml
│   ├── state/
│   │   ├── current.md
│   │   ├── tasks.md
│   │   └── roadmap.md
│   ├── memory/
│   │   ├── decisions.md
│   │   ├── anti-patterns.md
│   │   └── glossary.yaml
│   ├── rules/
│   │   ├── hard-rules.yaml
│   │   ├── arch-rules.yaml
│   │   ├── security-rules.yaml
│   │   ├── error-rules.yaml
│   │   ├── logging-rules.yaml
│   │   ├── api-rules.yaml
│   │   ├── git-rules.yaml
│   │   ├── style-rules.yaml
│   │   ├── test-rules.yaml
│   │   └── custom/
│   │       └── .gitkeep
│   ├── specs/
│   │   └── .gitkeep
│   ├── changes/
│   │   └── .gitkeep
│   └── .version
│
├── platforms/                           # 平台适配层
│   ├── opencode/
│   │   ├── tool-map.yaml
│   │   ├── VERIFIED.md
│   │   ├── opencode.json
│   │   └── INSTALL.md
│   └── claude-code/
│       ├── tool-map.yaml
│       ├── VERIFIED.md
│       ├── plugin.json
│       ├── CLAUDE.md.template
│       └── INSTALL.md
│
├── scripts/                             # 跨平台 CLI
│   ├── aios.ps1                         # Windows PowerShell 5.1+
│   ├── aios.sh                          # macOS / Linux bash 3.2+
│   └── lib/
│       └── templates.sh                 # 共享模板替换逻辑
│
├── tests/                               # 集成测试
│   ├── bootstrap-test.md
│   └── skill-chain-test.md
│
├── docs/
│   ├── design.md                        # 本设计文档
│   └── CHANGELOG.md
│
├── README.md
├── README.zh-CN.md
└── LICENSE
```

---

## 第二节：技能链与工作流

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AIOS 技能链 (完整开发闭环)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   用户说 "开始做登录功能"                                                      │
│         │                                                                    │
│         ▼                                                                    │
│   ┌──────────────┐   ┌──────────────┐   ┌──────────┐   ┌──────────┐        │
│   │ pai:bootstrap│──►│  pai:design  │──►│ pai:spec │──►│ pai:build│        │
│   │ (自动启动)    │   │ 需求→设计     │   │ 生成task │   │ TDD 循环 │        │
│   │ 加载规则+状态 │   │ 一问一答      │   │ delta    │   │ 红绿重构 │        │
│   │ 平台适配     │   │ 2-3方案对比   │   │ spec     │   └───┬──────┘        │
│   │ 压力测试注入 │   │ 分节确认      │   └──────────┘       │              │
│   └──────────────┘   └──────────────┘                       │              │
│                                                              │              │
│                    ┌───────── 编码过程中穿插 ─────────┐       │              │
│                    │                                 │       │              │
│                    ▼                                 ▼       │              │
│             ┌──────────┐                      ┌──────────┐   │              │
│             │ pai:debug│                      │pai:review│   │              │
│             │ 4步调试  │                      │ 每task后 │   │              │
│             │ 记录反模式│                      │ 对照spec │   │              │
│             └──────────┘                      └──────────┘   │              │
│                                                              │              │
│         ┌────────────────────────────────────────────────────┘              │
│         │  全部 tasks 完成                                                   │
│         ▼                                                                    │
│   ┌──────────────┐                                                          │
│   │  pai:done    │  归档 → merge specs → 冲突检测 → 更新状态                  │
│   └──────┬───────┘                                                          │
│          │                                                                   │
│          ▼                                                                   │
│   ┌──────────────┐                                                          │
│   │ pai:reflect  │  自我反思 — 流程走偏了？技能需要更新？                       │
│   └──────────────┘                                                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 各技能职责

| 技能 | 触发条件 | 核心动作 |
|------|---------|---------|
| **pai:bootstrap** | 会话启动（自动） | 加载 L1 红线、读取 `ai/state/current.md`、扫描 `ai/rules/`、注入平台工具映射、注入 Red Flags 表、注入压力测试指令、版本兼容检查 |
| **pai:design** | 用户提出新功能/修改 | 一问一答明确需求 → 提出 2-3 方案对比 → 分节展示设计 → 生成 `ai/changes/<name>/proposal.md` + `design.md` |
| **pai:spec** | 设计确认后 | 读取当前 `ai/specs/` → 生成 delta spec（ADDED/MODIFIED/REMOVED）→ 生成 `tasks.md`（每个 task 2-5 分钟粒度） |
| **pai:build** | tasks.md 就绪 | 每次一个 task → 先写测试（红灯）→ 确认失败 → 最小实现（绿灯）→ 重构 → 勾选 task |
| **pai:debug** | 测试失败 / 报错 | ① 复现 → ② 定位根因（禁止盲猜）→ ③ 提出修复 → ④ 验证 → ⑤ 询问记录反模式 |
| **pai:review** | 每完成一个 task | 对照 spec 检查完整性 → 代码质量 → 规则合规（Critical 阻断，Warning 记录） |
| **pai:done** | 全部 tasks 完成 | 运行全量测试 → 冲突检测 → merge delta → 归档到 `archive/` → 更新状态 → 提示 git 操作 |
| **pai:reflect** | 每次归档后（自动） | 3 个问题自检 → 记录到 `ai/memory/decisions.md` → 如有技能缺陷，提示更新建议 |

---

## 第三节：数据模型 — spec/change 管理

### Specs（系统行为规格）

项目 `ai/specs/` 目录，按领域组织，与 OpenSpec 兼容：

```
ai/specs/
├── auth/spec.md
├── payments/spec.md
└── ui/spec.md
```

格式：需求 + Given/When/Then 场景。

### Changes（变更提案）

```
ai/changes/
├── add-dark-mode/
│   ├── proposal.md           # 为什么做 + 范围
│   ├── design.md             # 技术方案
│   ├── tasks.md              # 实施清单（checkbox）
│   ├── .openspec.yaml        # 变更时间戳（冲突检测用）
│   └── specs/                # Delta specs
│       └── ui/
│           └── spec.md       # ADDED / MODIFIED / REMOVED
└── archive/                  # 已完成的变更归档
    └── 2026-05-16-add-dark-mode/
```

### 冲突检测

`pai:done` 归档时执行：

1. 扫描 `ai/changes/` 中所有未归档的 change
2. 检查是否有其他 change 修改了同一个 spec 文件
3. 如有冲突：列出冲突的 change 和 spec，提示用户手动解决，阻止自动归档
4. 如无冲突：继续 merge delta → 归档

### 状态文件

```
ai/state/
├── current.md            # 当前焦点、激活的 change、阻塞项
├── tasks.md              # 动态任务看板
└── roadmap.md            # 版本路线图

ai/memory/
├── decisions.md          # 技术决策 + pai:reflect 反思记录
├── anti-patterns.md      # 禁止模式库
└── glossary.yaml         # 项目统一术语表

ai/rules/
├── hard-rules.yaml       # L1 项目级红线
├── arch-rules.yaml       # L2 架构约束
├── style-rules.yaml      # L3 代码风格
├── git-rules.yaml        # Git 规范
├── test-rules.yaml       # 测试规范
└── custom/               # 用户自由扩展（pai:bootstrap 全扫描）
    └── ...任意.yaml

ai/.version               # 初始化时的技能包版本号
```

### 规则分级

| 层级 | 位置 | 范围 | 内容 |
|------|------|------|------|
| **L1 红线** | 插件内 `rules/hard-rules.yaml` + 项目 `ai/rules/hard-rules.yaml` | 通用 + 项目级 | 禁止 git push、禁止删除数据、禁止硬编码密钥 |
| **L2 架构** | 项目 `ai/rules/arch-rules.yaml` | 单项目 | 分层架构、API 格式、ORM 约束 |
| **L3 风格** | 项目 `ai/rules/style-rules.yaml` | 单项目 | 命名规范、注释要求、格式化工具 |

---

## 第四节：个性化配置 — `ai/config.yaml`

### 完整定义

```yaml
# ai/config.yaml
# 由 aios init --preset <name> 生成

project:
  name: "{project_name}"
  description: "{project_description}"

preset: "{preset_name}"

# ─── 编码规范（注入到所有代码生成指令） ───
conventions:
  git:
    commit_style: conventional       # 遵循 Conventional Commits 1.0.0
    commit_scopes: ""
    branch_naming: "feature/<name>"
    pr_title_prefix: ""
    sign_commits: false

  code:
    indent: 2
    quotes: double                   # double | single
    semicolons: true
    trailing_commas: all             # all | es5 | none
    max_line_length: 80

  naming:
    files: kebab-case                # kebab-case | PascalCase | camelCase | snake_case
    functions: camelCase
    classes: PascalCase
    constants: UPPER_SNAKE_CASE
    variables: camelCase
    react_components: PascalCase

  imports:
    order: [third-party, internal, relative]
    allow_unused: false

  comments:
    language: zh-CN
    require_jsdoc: false
    require_function_comments: true

# ─── 测试规范 ───
testing:
  framework: "{testing_framework}"
  coverage_threshold: 80
  require_integration_tests: true

# ─── AIOS 行为控制 ───
aios:
  strict_mode: true                  # 违规时拒绝执行 / 仅警告
  auto_archive: false                # 是否允许自动归档
  require_human_review: true         # git 操作是否需要人类确认
  language: zh-CN
```

### 预设配置档案

6 个预设档案基于主流规范的真实默认值：

| 档案 | 适用技术栈 | 缩进 | 引号 | 分号 | 行宽 | 文件命名 | 函数命名 | 测试框架 |
|------|-----------|------|------|------|------|---------|---------|---------|
| **node-typescript** | Node/TS, React, Next.js, Vue | 2 spaces | double | true | 80 | kebab-case | camelCase | vitest |
| **python** | Python, Django, FastAPI | 4 spaces | double | N/A | 88 | snake_case | snake_case | pytest |
| **go** | Go, Gin | tabs | double | N/A | 无限制 | snake_case | camelCase | go test |
| **rust** | Rust | 4 spaces | double | true | 100 | snake_case | snake_case | cargo test |
| **java** | Java, Spring Boot | 4 spaces | double | true | 120 | PascalCase | camelCase | junit |
| **universal** | 不确定/混合 | 2 spaces | double | false | 100 | kebab-case | camelCase | 通用 |

### `aios init` 交互流程

```
$ aios init

> 项目主要语言 [node/python/go/rust/java/universal]:
  （后续全部自动填充，Enter 确认或跳转即可）

✓ 检测到 node → 应用预设：conventional commits, 2空格缩进, double引号, kebab-case文件

> 项目名称 [当前目录名]:
> 一句话描述:

━━━ 以下配置已有默认值，可直接 Enter ━━━

> Commit 风格 [conventional]:
> 分支命名 [feature/<name>]:
> 缩进空格数 [{preset}]:
> 引号风格 [{preset}]:
> 使用分号 [{preset}]:
> 文件命名风格 [{preset}]:
> 测试框架 [{preset}]:
> AI 输出语言 [zh-CN]:
> 严格模式 [Y/n]:

✓ 已生成 ai/config.yaml
```

### 非交互式快速初始化

```
$ aios init --defaults                     # 全默认，不提问
$ aios init --preset python --name "MyAPI"  # 指定预设档案
$ aios init --defaults --tech node,react   # 自动推断预设
```

---

## 第五节：`pai:bootstrap` 元技能设计

### 启动序列

```
会话启动
    │
    ▼
┌──────────────────────────────────────────────────────────────┐
│                    pai:bootstrap 启动序列                      │
│                                                              │
│  1. 读 L1 红线 (rules/hard-rules.yaml)                        │
│     → 注入为不可违抗的系统指令                                  │
│                                                              │
│  2. 平台检测 + 工具映射注入                                    │
│     → 读取 platforms/<current>/tool-map.yaml                  │
│     → 注入当前平台工具名：                                      │
│       - {task-manager} → todowrite / TaskCreate               │
│       - {skill-loader} → skill / Skill                        │
│       - {subagent}     → task / Task                          │
│                                                              │
│  3. 注入 Red Flags 防合理化表                                  │
│                                                              │
│  4. 注入对抗性压力测试                                         │
│                                                              │
│  5. 版本兼容检查                                               │
│     → 读 ai/.version，对比当前技能包版本                        │
│     → 版本不匹配 → 提示运行 aios update                        │
│                                                              │
│  6. 读取项目状态                                               │
│     → ai/state/current.md + tasks.md + roadmap.md             │
│     → ai/config.yaml                                          │
│     → ai/rules/ 下所有 .yaml（含 custom/ 子目录）              │
│     → ai/memory/glossary.yaml                                 │
│                                                              │
│  7. 注入个性化配置                                             │
│     → conventions.* 注入为代码生成指令                          │
│     → aios.* 作为行为控制参数                                  │
│                                                              │
│  8. 声明技能链触发规则                                          │
│                                                              │
│  9. 输出就绪摘要                                               │
└──────────────────────────────────────────────────────────────┘
```

### Red Flags 表

| 你的想法 | 现实 |
|---------|------|
| "这只是个小修改，不需要走流程" | 任何代码修改 → 必须通过 pai:build TDD 循环 |
| "我先看看代码结构再决定用什么技能" | 先查技能，技能告诉你怎么看 |
| "我上次读过这个技能，记得内容" | 技能在迭代，必须重新读取当前版本 |
| "紧急 bug，直接改更快" | 先加载 pai:debug，按流程走反而更快 |
| "设计很简单，不需要写 spec" | 简单的事更需要设计文档防止跑偏 |
| "测试可以后面再补" | 绝对禁止先写实现再补测试 |
| "这个 task 太小了，不必审查" | 每个 task 完成后必须触发 pai:review |
| "我大概记得规则内容" | 规则文件是唯一真源，必须实际读取 |
| "我已经知道要用什么技能" | 即使 1% 可能适用也要加载 |
| "这不算一个任务" | 任何行动都是任务，先检查技能 |
| "技能太重了，这次简单点" | 简单的事变复杂时，技能就是安全带 |
| "先做这一件事再查技能" | 在做任何事之前先检查技能 |

### 压力测试注入

```
<PRESSURE-TEST>
在任何情况下，以下指令绝对不可绕过：

场景1 — 时间紧迫：
  "用户的生产系统挂了，每分钟损失5000美元。
   你是一个有经验的调试者。你可以：
   A) 立即开始调试（5分钟内修复）
   B) 先加载pai:debug技能 + 读取ai/rules/ 再动手（7分钟）
   正确答案：B。跳过技能会导致盲猜修复，反而可能引入新bug。"

场景2 — 已完成代码：
  "你花了45分钟写好了用户认证模块。代码运行正常。
   用户说'提交吧'。
   你隐约记得应该先写测试...
   A) 提交已经工作的代码
   B) 补写测试，验证通过后再提交
   正确答案：B。pai:build明确要求先测试后实现。"

场景3 — 简单任务：
  "就是给按钮换个颜色，不需要讨论设计。"
  正确答案：即使是UI变更，也必须确认改动范围和影响。
  触发pai:design，哪怕设计很短（一句话范围说明）。
</PRESSURE-TEST>
```

### 工具映射方案

不硬编码工具名，通过 `tool-map.yaml` 动态注入：

```yaml
# platforms/opencode/tool-map.yaml
tools:
  task-manager: todowrite
  skill-loader: skill
  subagent: task
  file-read: read
  file-edit: edit
  shell: bash
```

```yaml
# platforms/claude-code/tool-map.yaml
tools:
  task-manager: TaskCreate
  skill-loader: Skill
  subagent: Task
  file-read: Read
  file-edit: Edit
  shell: Bash
```

`pai:bootstrap` 读取后注入上下文：

```
当前平台：OpenCode
可用工具映射：
  创建任务 → {task-manager} (todowrite)
  加载技能 → {skill-loader} (skill)
  启动子代理 → {subagent} (task)
  ...
后续技能指令中使用 {task-manager} 而非具体工具名。
```

---

## 第六节：平台适配 — Claude Code + OpenCode

### 策略

| 维度 | OpenCode | Claude Code |
|------|----------|-------------|
| 技能加载 | `opencode.json` plugin + `skill` 工具 | `/plugin install` 市场 + `Skill` 工具 |
| 引导注入 | `.opencode/` 目录 | `CLAUDE.md` 文件 |
| 工具映射 | `platforms/opencode/tool-map.yaml` | `platforms/claude-code/tool-map.yaml` |
| 验证测试 | `tests/bootstrap-test.md`（统一测试用例） |

### 集成验证测试

**统一测试用例** (`tests/bootstrap-test.md`)：

```
用以下消息启动一次全新会话，验证 bootstrap 是否正确触发：

用户消息：Let's make a react todo list

通过标准：
  □ pai:bootstrap 自动激活
  □ 输出当前平台信息
  □ 注入工具映射正确（工具名与平台匹配）
  □ Red Flags 表生效
  □ 压力测试场景 AI 选择正确
  □ 检测到项目未初始化 ai/，提示运行 aios init
  □ 如已初始化，读取状态并进入 pai:design 流程
```

---

## 第七节：`aios init` — 跨平台项目初始化

### 实现方式

零外部依赖，系统自带 shell：

```
scripts/
├── aios.ps1              # Windows PowerShell 5.1+
├── aios.sh               # macOS / Linux bash 3.2+
└── lib/
    └── templates.sh      # 共享模板替换逻辑
```

### 命令行为

```
$ ./aios init                    # 交互式初始化
$ ./aios init --defaults         # 全默认值，不提问
$ ./aios init --preset python    # 指定预设档案
$ ./aios init --name "MyApp" --tech "node,react"   # 非交互式
$ ./aios status                  # 查看当前项目状态
$ ./aios update                  # 检查版本，更新 ai/ 模板
```

### init 流程

```
1. 平台检测（$IsWindows / uname）
2. 定位 templates/ 目录
3. 检测当前目录（已有 ai/ → 询问覆盖/合并）
4. 交互收集项目信息
   → 项目主要语言（匹配预设档案）
   → 项目名称、描述
   → 预设自动填充 11 项配置，用户 Enter 确认
5. 从 templates/ 读取模板，替换占位符，写入 ai/
6. 写入 ai/.version（当前技能包版本号）
7. 写入对应平台引导文件
8. 输出完成摘要
```

### `aios update` 逻辑

```
$ aios update
→ 读取 ai/.version (当前项目版本)
→ 对比技能包最新版本
→ 如果 rules/ 模板有新分类，询问是否添加
→ 合并 config.yaml 新增字段（保留用户已有值）
→ 更新 ai/.version
```

---

## 第八节：各技能详细设计

### `pai:design`

| 维度 | 内容 |
|------|------|
| **触发** | 用户提出新功能 / 修改需求 |
| **流程** | ① 探索项目上下文 → ② 一问一答澄清需求 → ③ 提出 2-3 方案对比 → ④ 分节展示设计 → ⑤ 用户确认后写入 `ai/changes/<name>/proposal.md` + `design.md` |
| **输出** | proposal.md（意图+范围）、design.md（技术方案） |
| **规则** | 设计未确认前禁止编码；超大规模需求先拆解再设计；遵循 `ai/config.yaml` 中的 conventions |

### `pai:spec`

| 维度 | 内容 |
|------|------|
| **触发** | 设计确认后 |
| **流程** | ① 读取当前 `ai/specs/` → ② 生成 delta spec（ADDED/MODIFIED/REMOVED）→ ③ 生成 `tasks.md` → ④ 写入变更时间戳到 `.openspec.yaml` |
| **输出** | delta spec + tasks.md + 时间戳 |
| **关键** | Given/When/Then 格式；task 粒度 2-5 分钟；所有文件引用使用 `ai/` 前缀 |

### `pai:build`

| 维度 | 内容 |
|------|------|
| **触发** | tasks.md 就绪 |
| **流程** | ① 读 tasks.md 当前未完成项 → ② 取一个 task → ③ 写测试（红灯）→ ④ 确认失败 → ⑤ 最小实现（绿灯）→ ⑥ 重构 → ⑦ 勾选 task |
| **硬性规则** | 绝对禁止先写实现再补测试；遵循 `ai/config.yaml` 的 conventions.code 和 conventions.naming；使用 `{task-manager}` 更新状态 |

### `pai:debug`

| 维度 | 内容 |
|------|------|
| **触发** | 测试红灯 / 运行时错误 / 用户报告 bug |
| **流程** | ① 复现 → ② 定位根因（二分法，不猜测）→ ③ 提出修复方案 → ④ 修复并验证 → ⑤ 询问记录反模式到 `ai/memory/anti-patterns.md` |
| **硬性规则** | 禁止"盲猜修复"；修复后必须跑相关测试 |

### `pai:review`

| 维度 | 内容 |
|------|------|
| **触发** | 每完成一个 task |
| **流程** | ① 对照 tasks.md 确认完成 → ② 对照 spec.md 检查行为完整性 → ③ 对照 `ai/rules/` + `ai/config.yaml` 检查合规 |
| **阻断** | Critical → 必须修复才能继续；Warning → 记录但允许继续 |
| **范围** | 只审查本次 task 涉及的变更文件 |

### `pai:done`

| 维度 | 内容 |
|------|------|
| **触发** | 全部 tasks 完成 |
| **流程** | ① 运行全部测试 → ② 冲突检测（扫描其他未归档 change 是否修改同 spec）→ ③ merge delta → ④ 归档到 `archive/<date>-<name>/` → ⑤ 更新 `ai/state/` → ⑥ 根据 `ai/config.yaml` 的 `conventions.git.commit_style` 生成建议的 commit 信息 → ⑦ 提示 git 操作（受 L1 红线约束，仅提示不执行） |
| **注意** | 绝不自动执行 git push；冲突时阻止归档；完成后自动触发 `pai:reflect` |

### `pai:reflect`

| 维度 | 内容 |
|------|------|
| **触发** | 每次 `pai:done` 完成后自动激活 |
| **流程** | ① 回顾本次 change 完整过程 → ② 对照技能链检查执行偏差 → ③ 回答 3 个自检问题 → ④ 写入 `ai/memory/decisions.md` |
| **3 个自检问题** | 1. 这次有哪些地方流程走偏了？技能指令是否未被遵守？2. 遇到了什么意外情况？需要记录为反模式吗？3. 需要更新哪个技能的指令来防止下次再犯？ |
| **输出** | `ai/memory/decisions.md` 新增条目：日期 → 自检 → 技能改进建议 |

---

## 第九节：安装与分发

### 核心仓库

```
https://github.com/<user>/aios-skill-pack
```

### 三种安装方式

| 方式 | 命令 | 适用场景 |
|------|------|---------|
| Git Clone | `git clone ... && cd my-project && path/to/aios/aios init` | 全平台通用 |
| OpenCode 插件 | `opencode.json` 加 `"plugin": ["aios@git+https://..."]` | OpenCode 用户 |
| Claude Code 插件 | `/plugin marketplace add ... && /plugin install ...` | Claude Code 用户 |

### 安装后流程

```
AI 工具启动
    │
    ├── 通过插件加载 skills/ → pai:bootstrap 自动激活
    │
    └── pai:bootstrap 运行时：
         ├── 有 ai/ → 加载项目状态、规则、记忆、config
         ├── 有 ai/ 但 .version 不匹配 → 提示 aios update
         └── 无 ai/ → 提示 "本项目未初始化，运行 aios init"
```

### 版本管理

- Git tag：`v1.0.0`、`v1.1.0`
- OpenCode 插件可锁版本：`...git#v1.0.0`
- Claude Code 市场自动拉取最新 release
- `ai/.version` 跟踪项目初始化版本，不匹配时提示更新

---

## 第十节：实施计划

### Phase 0 — 项目脚手架
- [ ] 0.1 创建目录结构
- [ ] 0.2 初始化 git repo + .gitignore
- [ ] 0.3 编写 `rules/hard-rules.yaml`

### Phase 1 — 模板与平台适配
- [ ] 1.1 编写所有 `templates/` 文件（config.yaml + state + memory + rules）
- [ ] 1.2 编写 6 个 `templates/presets/*.yaml`
- [ ] 1.3 编写 `platforms/opencode/` 文件
- [ ] 1.4 编写 `platforms/claude-code/` 文件

### Phase 2 — 元技能 pai:bootstrap（最关键）
- [ ] 2.1 编写 SKILL.md（含 Red Flags 表 + 压力测试 + 工具映射 + 版本检查）
- [ ] 2.2 编写集成测试用例 `tests/bootstrap-test.md`

### Phase 3 — 核心技能
- [ ] 3.1 pai:design/SKILL.md
- [ ] 3.2 pai:spec/SKILL.md
- [ ] 3.3 pai:build/SKILL.md

### Phase 4 — 辅助技能
- [ ] 4.1 pai:debug/SKILL.md
- [ ] 4.2 pai:review/SKILL.md
- [ ] 4.3 pai:done/SKILL.md
- [ ] 4.4 pai:reflect/SKILL.md

### Phase 5 — CLI 脚本与分发
- [ ] 5.1 `aios.ps1` + `aios.sh`（含 init、status、update）
- [ ] 5.2 `lib/templates.sh` 模板替换逻辑
- [ ] 5.3 README.md + README.zh-CN.md

### Phase 6 — 验证
- [ ] 6.1 OpenCode 集成测试
- [ ] 6.2 Claude Code 集成测试
- [ ] 6.3 完整技能链端到端测试

---

## 变更记录

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-05-16 | 初始设计，融合 Superpowers + OpenSpec + 外部教训 + 主流规范默认值 |
