# AIOS —— 个人 AI 工程操作系统

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v1.3.2-green)]()
<br>[English](README.md)

AIOS 将你的 AI 编码助手从健忘的帮手升级为有纪律的工程协作伙伴。融合 [Superpowers](https://github.com/obra/superpowers) 的**技能链**模式、[OpenSpec](https://github.com/Fission-AI/OpenSpec) 的 **Spec/Change 管理**体系，并基于 OWASP、Google Code Review 和各语言社区标准内置了 **100 条可执行的工程规则**。

---

## 目录

- [为什么需要 AIOS](#为什么需要-aios)
- [快速开始](#快速开始)
- [工作方式](#工作方式)
- [技能详解](#技能详解)
- [项目结构](#项目结构)
- [规则体系（100 条）](#规则体系100条)
- [预设配置档案](#预设配置档案)
- [命令行](#命令行)
- [与其他技能包共存](#与其他技能包共存)
- [设计理念](#设计理念)
- [安装参考](#安装参考)
- [许可证](#许可证)

---

## 为什么需要 AIOS

AI 编码助手能写代码，但不可靠——它们会忘记项目上下文、跳过测试、生成不安全代码、缺乏一致的工程流程。

AIOS 通过在每个会话中注入**记忆、规则和流程**来解决：

- **记忆** — `ai/state/` 跨会话记住项目焦点、任务和路线图
- **规则** — 100 条强制执行规则（L1 红线、L2 架构、L3 风格）约束每次编码操作
- **流程** — 8 技能链强制执行"先设计再编码、先测试再实现、先审查再完成"
- **个性化** — `ai/config.yaml` 记录你的命名习惯、代码风格、commit 格式、测试框架
- **安全** — 8 条 L1 红线阻止危险操作（git push、破坏性命令、密钥泄露）
- **共存** — 检测其他技能包（Superpowers、OpenSpec 等），提供独占/互补模式选择

---

## 快速开始

### 1. 安装

**Claude Code 插件市场：**
```bash
/plugin marketplace add alex-hlh/aios-marketplace
/plugin install paios@aios-marketplace
```

**OpenCode 插件：**
```json
{ "plugin": ["paios@git+https://github.com/alex-hlh/Paios.git"] }
```

**npm（CLI 工具）：**
```bash
npm install -g @huahu/paios
paios install
```

### 2. 注册技能到 AI 工具

```bash
paios install
```

自动检测 Claude Code、OpenCode 等 AI 工具——一键注册所有技能，零手动配置。重启 AI 后技能即生效。

### 3. 初始化项目

**自动初始化（推荐）：** 安装插件后重启 AI 工具。`pai:bootstrap` 检测到缺少 `ai/` 目录，自动引导初始化——回答几个问题，AI 完成其余工作。

**手动初始化（CI/CD 或批量场景）：**

```bash
npx @huahu/paios init --defaults
```

### 4. 开始编码

重启 AI 工具。下次会话时，`pai:bootstrap` 自动激活，加载项目状态，注入 100 条规则，声明技能链。直接描述你想做什么即可。

```
你: "帮我做用户JWT登录"
AI:  [pai:bootstrap] AIOS就绪。平台: OpenCode, 模式: standalone, 规则: 100条已加载。
     [pai:design] Q1: 认证方式倾向于哪种？[JWT / Session / OAuth / 其他]
     ... 需求讨论 ...
     ✓ ai/changes/add-login/proposal.md
     ✓ ai/changes/add-login/design.md
     准备生成规格！

你: "可以，生成规格"
AI:  [pai:spec] Delta spec已生成: 3个新增需求, 0修改, 0移除。
     ✓ 8个任务 (1.1 - 3.2)
     准备实现！

你: "开始实现"
AI:  [pai:build] 任务1.1: 创建User模型测试
     [RED]    写测试 → 运行 → 失败 ✓
     [GREEN]  最小实现 → 运行 → 通过 ✓
     [REFACTOR] 重构 → 通过 ✓
     [pai:review] 完整性:通过 | 正确性:通过 | 合规性:通过
     ... (剩余7个任务) ...
     全部任务完成！

你: "归档这个change"
AI:  [pai:done] 全量测试: 23/23通过。无冲突。已合并specs ✓。
     Git提示: git commit -m "feat(auth): add JWT user login"
     [pai:reflect] 流程: 无偏差。技能建议: 无。
      变更已归档。下一个功能可以开始了！
```

也可以**单独使用某个技能**，不需要走完整链条：
```
你: "/pai:debug"
AI:  [pai:debug] 步骤1:复现 → 步骤2:定位 → 步骤3:修复 → 步骤4:验证

你: "/pai:review"
AI:  [pai:review] 审查当前改动... Critical:0, Warning:1, Pass:5
```

---

## 工作方式

```
pai:bootstrap → pai:design → pai:spec → pai:build → (pai:debug / pai:review) → pai:done → pai:reflect
```

每次会话启动时，`pai:bootstrap` 执行 10 步启动序列：

1. **环境扫描** — 检测技能包冲突（Superpowers、OpenSpec 等），让用户选择共存模式
2. **L1 红线** — 注入 8 条不可违抗的安全规则作为永久背景指令
3. **平台检测** — 根据当前环境（OpenCode/Claude Code）映射工具名
4. **Red Flags 表** — 注入 12 条防合理化模式（"太简单不需要技能" → "查了再说"）
5. **压力测试** — 注入对抗性场景强化流程纪律
6. **版本检查** — `ai/.version` 与技能包版本不一致时提醒升级
7. **项目状态** — 读取 `ai/state/`、`ai/config.yaml`、`ai/memory/glossary.yaml`
8. **规则注入** — 扫描 `ai/rules/*.yaml`（含 `custom/`）全部注入为背景约束
9. **配置注入** — 注入代码规范（缩进、引号、命名、测试框架、commit 风格）
10. **技能链声明** — 注册 8 技能的自动触发规则

三种共存模式：

| 模式 | 行为 |
|------|------|
| **standalone** | AIOS 完全接管。完整技能链 + 全部规则生效。 |
| **complementary** | AIOS 仅注入规则 + 状态 + 配置。其他技能包驱动工作流。 |
| **ask**（默认） | 检测到冲突时暂停，让你选择。选择持久化到 `ai/config.yaml`。 |

---

## 技能详解

| 技能 | 触发条件 | 做什么 |
|------|---------|--------|
| **pai:bootstrap** | 会话启动（自动） | 10 步启动：环境扫描、L1 红线、平台映射、Red Flags、压力测试、版本检查、**自动初始化（如需）**、状态加载、100 条规则注入、配置注入、技能链声明 |
| **pai:prd** | "帮我写 PRD" / "/pai:prd" | 7 阶段产品规划：问题陈述 → 用户画像 → 旅程图 → MoSCoW → NFR → 里程碑 → 风险。产出 `ai/prd.md` + `ai/personas.md`。 |
| **pai:story** | "出原型" / "/pai:story" | 5 步需求分析：ASCII 原型 → 数据流 → 后台流程 → 接口清单 → 功能点。产出 5 个 `ai/*.md` 文件。 |
| **pai:retro** | "aios retro" / "分析项目" | 对已有项目逆向分析。扫描代码/配置文件 → 自动检测技术栈、代码风格、commit 规范 → 生成 `ai/` 目录，不修改项目代码。 |
| **pai:init** | 手动触发 / bootstrap 重定向 | 交互式项目初始化。选择预设 → 确认默认配置 → 生成完整 `ai/` 目录。 |
| **pai:docs** | "生成文档" / "/pai:docs" | 从 `ai/` 文件和项目代码自动生成标准项目文档（README、架构、API、贡献指南、开发指南、变更日志）。支持增量更新，不覆盖手写内容。 |
| **pai:design** | 用户提出新功能/修改需求 | 探索项目上下文 → 一次一问澄清需求（5 个必问维度，详见 [pai-design](skills/pai-design/SKILL.md)）→ 提出 2-3 方案对比利弊 → 分节展示设计逐节确认 → 写入 `proposal.md` + `design.md`。**设计未确认前不写代码。** |
| **pai:amend** | "还要加" / "需求变了" / "/pai:amend" | 需求变更入口。检测当前 change 状态 → 分析变更关系 → 推荐策略（追加/新建/延期）→ 协调文档更新。 |
| **pai:spec** | 设计确认后 | 读当前 specs → 生成 delta spec（ADDED/MODIFIED/REMOVED + Given/When/Then 场景）→ 生成 `tasks.md`（2-5 分钟粒度）→ 写入变更时间戳 |
| **pai:build** | tasks 就绪 + 用户确认 | 严格红-绿-重构 TDD 循环，每个 task 独立。遵循项目规范（缩进/引号/命名/测试框架）。每个 task 完成后触发 `pai:review`。**必须先写测试，再写实现。** |
| **pai:debug** | 测试失败/运行时报错/用户报 bug | 4 步系统调试：复现 → 定位根因（二分法，不猜测）→ 提出修复 → 修复并验证。可选记录反模式到 `ai/memory/anti-patterns.md`。 |
| **pai:review** | 每个 task 完成后 | 三维代码审查：完整性（对照 spec 场景）、正确性（逻辑 + 边界 + 安全）、合规性（对照 100 条规则）。输出 Critical/Warning/OK 分级。Critical 阻断继续。 |
| **pai:done** | 全部 tasks 完成 | 全量测试 → 冲突检测（检查是否有其他未归档 change 修改了同一个 spec）→ 合并 delta spec → 归档 change → 更新状态 → 生成 git commit 建议（Conventional Commits 格式）→ 触发 `pai:reflect` |
| **pai:reflect** | 归档完成后 | 回顾本次 change 完整过程：流程有无走偏？有无意外情况？哪个技能指令需要改进？写入 `ai/memory/decisions.md`。 |

---

## 项目结构

```
your-project/
├── ai/                              # AI 上下文（由 aios init 创建）
│   ├── config.yaml                  # 个性化配置：规范、命名、测试、AIOS 行为
│   ├── .version                     # AIOS 版本标记（用于检测更新）
│   ├── state/                       # 当前工作上下文
│   │   ├── current.md               #   当前激活的 change、sprint、阻塞项、下一步
│   │   ├── tasks.md                 #   看板：IN_PROGRESS / TODO / DONE
│   │   └── roadmap.md              #   版本路线图
│   ├── memory/                      # 长期项目记忆
│   │   ├── decisions.md             #   技术决策 + pai:reflect 复盘记录
│   │   ├── anti-patterns.md         #   从 bug 中积累的禁止模式
│   │   └── glossary.yaml           #   项目统一术语表
│   ├── rules/                       # 100 条工程规则（pai:bootstrap 自动扫描）
│   │   ├── hard-rules.yaml          #   L1: 项目级安全红线
│   │   ├── arch-rules.yaml          #   L2: 架构约束（14 条）
│   │   ├── security-rules.yaml      #   L2: OWASP 安全规范（10 条）
│   │   ├── error-rules.yaml         #   L2: OWASP 错误处理规范（7 条）
│   │   ├── logging-rules.yaml       #   L2: OWASP 日志规范（9 条）
│   │   ├── api-rules.yaml           #   L2: REST API 设计规范（8 条）
│   │   ├── git-rules.yaml           #   L2: Git 与 Commit 规范（6 条）
│   │   ├── style-rules.yaml         #   L3: 代码风格（16 条）
│   │   ├── test-rules.yaml          #   L3: 测试规范（10 条）
│   │   └── custom/                  #   自有规则（任意 .yaml，自动扫描）
│   ├── specs/                       # 系统行为规格（真相源）
│   │   └── <domain>/spec.md         #   需求 + Given/When/Then 场景
│   ├── changes/                     # 活跃的变更提案
│   │   └── <change-name>/
│   │       ├── proposal.md          #   意图 + 范围 + 方案
│   │       ├── design.md            #   技术方案 + 架构决策
│   │       ├── tasks.md             #   实施清单
│   │       ├── .openspec.yaml       #   变更时间戳（用于冲突检测）
│   │       └── specs/<domain>/      #   Delta spec（ADDED/MODIFIED/REMOVED）
│   └── changes/archive/             # 已完成的变更（保留完整审计记录）
│       └── <date>-<change-name>/
```

### `ai/config.yaml` 参考

```yaml
project:
  name: "MyApp"
  description: "在线协作平台"
  preset: "node-typescript"

conventions:
  git:
    commit_style: conventional      # Conventional Commits 1.0.0
    branch_naming: "feature/<name>"
  code:
    indent: 2                       # 空格数
    quotes: double
    semicolons: true
    trailing_commas: all
    max_line_length: 80
  naming:
    files: kebab-case
    functions: camelCase
    classes: PascalCase
    constants: UPPER_SNAKE_CASE
    variables: camelCase

testing:
  framework: vitest
  coverage_threshold: 80

aios:
  strict_mode: true                 # L1/L2 违规时拒绝执行
  coexistence_mode: ask             # ask | standalone | complementary
  language: zh-CN
```

---

## 规则体系（100 条）

所有规则由 `pai:bootstrap` 自动加载，由 `pai:review` 强制执行。`ai/rules/custom/` 中的规则自动扫描——添加任意 `.yaml` 文件即可。

### L1 — 红线（8 条，全局生效）
*不可违抗。违规 = BLOCK_AND_WARN。*

| ID | 规则 |
|----|------|
| H001 | 禁止 AI 自主执行 git push/merge/rebase/deploy，必须人类确认 |
| H002 | 禁止执行破坏性命令（DROP TABLE、rm -rf、DEL /F） |
| H003 | 禁止在代码/配置/日志/注释中硬编码密钥、密码或令牌 |
| H004 | 所有 AI 生成代码需人类 Code Review 后方可合并 |
| H005 | 禁止访问与当前任务无关的文件 |
| H006 | 禁止安装系统级软件包，除非用户明确确认 |
| H007 | 只使用经过审计的密码学库（bcrypt/scrypt/argon2、AES-GCM） |
| H008 | 服务端输入验证为强制性要求；白名单（allowlist）优先于黑名单（denylist） |

### L2 — 架构与领域（54 条）
*设计和结构约束。根据项目范围自动适用（backend/api/web）。*

| 文件 | 条数 | 适用范围 | 来源 |
|------|------|---------|------|
| `arch-rules.yaml` | 14 | backend/api/web/all | 分层架构、事务、断路器、RESTful 设计、分页、速率限制、幂等、权限 |
| `security-rules.yaml` | 10 | backend/web/all | OWASP：输入验证、XSS、SQL 注入、密码哈希、反序列化、文件上传、重定向、CSRF、依赖、客户端存储 |
| `error-rules.yaml` | 7 | backend/api | OWASP：全局异常处理、状态码、消息脱敏、RFC 7807、具体异常、异步错误 |
| `logging-rules.yaml` | 9 | backend/all | OWASP：安全事件日志、日志格式（ISO 8601）、敏感数据排除、日志注入防护、日志级别、链路追踪 ID |
| `api-rules.yaml` | 8 | api | RESTful：名词资源、kebab-case 路径、版本控制、分页、信封格式、状态码、速率限制、字段筛选 |
| `git-rules.yaml` | 6 | all | Conventional Commits 格式、破坏性变更标记、分支命名、单次 commit 单一逻辑单元 |

### L3 — 风格与测试（26 条）
*代码质量和测试标准。警告级别，REVIEW_BLOCK 项除外。*

| 文件 | 条数 | 关注点 |
|------|------|--------|
| `style-rules.yaml` | 16 | 注释（解释 why）、类型（禁止 any/Object）、结构化日志（禁止 print）、异常处理（禁止空 catch）、命名规范、函数长度（≤50 行）、嵌套深度（≤3 层）、禁止魔法数字、参数个数（≤5 个）、布尔参数、提前返回、不可变性、DRY 原则、配置提取 |
| `test-rules.yaml` | 10 | 覆盖率阈值、API 集成测试、AAA 模式、mock 外部服务、TDD 循环强制执行、测试命名规范、回归测试、测试隔离、禁止 flaky test、行为验证优先于实现验证 |

### 强制执行级别

| 级别 | 行为 | 使用场景 |
|------|------|---------|
| **BLOCK_AND_WARN** | 拒绝执行并警告用户 | L1 红线、关键 L2 规则 |
| **REVIEW_BLOCK** | 审查中必须修复才能继续 | commit 格式、覆盖率、日志合规 |
| **REFACTOR_SUGGESTION** | 强烈建议，记录警告 | 架构偏差 |
| **REVIEW_SUGGESTION** | 审查中记录，允许继续 | 锦上添花的改进 |
| **WARN** | 警告但不阻断 | 代码风格偏差 |
| **STYLE** | 仅建议 | 命名、格式化偏好 |
| **AUDIT_ONLY** | 记录供人类审查 | 流程合规（如 merge 前需 Code Review） |

---

## 预设配置档案

`aios init` 根据技术栈自动匹配预设。每个预设基于该语言社区的**事实标准工具默认值**：

| 预设 | 缩进 | 引号 | 分号 | 行宽 | 文件命名 | 函数命名 | 测试 | 来源 |
|------|------|------|------|------|---------|---------|------|------|
| **node-typescript** | 2 空格 | 双引号 | 是 | 80 | kebab-case | camelCase | vitest | [Prettier 3.x](https://prettier.io/docs/en/options.html) |
| **python** | 4 空格 | 双引号 | — | 88 | snake_case | snake_case | pytest | [PEP 8](https://peps.python.org/pep-0008/) + [black](https://black.readthedocs.io/) |
| **go** | Tab | 双引号 | — | 无限制 | snake_case | camelCase | go test | [Effective Go](https://go.dev/doc/effective_go) + `gofmt` |
| **rust** | 4 空格 | 双引号 | 是 | 100 | snake_case | snake_case | cargo test | [Rust Style Guide](https://doc.rust-lang.org/nightly/style-guide/) + `rustfmt` |
| **java** | 4 空格 | 双引号 | 是 | 120 | PascalCase | camelCase | junit | Google Java Style + Checkstyle |
| **universal** | 2 空格 | 双引号 | 否 | 100 | kebab-case | camelCase | 通用 | （合理默认值） |

自定义：`aios init` 后编辑 `ai/config.yaml`，或在交互式提示时输入自定义值。

---

## 命令行

```bash
# 交互式初始化（一键确认默认值）
aios init

# 全默认不提问
aios init --defaults
aios init --defaults --tech node,react

# 指定预设
aios init --preset python --name "MyAPI"

# 查看项目状态
aios status

# 检查并更新
aios update
```

### `aios init` 交互流程

```
$ aios init

  项目主要语言 [node/python/go/rust/java/universal]: node
  预设档案: node-typescript

  项目名称 [my-project]:
  一句话描述:

  --- 以下配置可直接按 Enter 跳过 ---
  Commit 风格 [conventional]:
  分支命名模板 [feature/<name>]:
  缩进空格数 [2]:
  引号风格 [double/single]: double
  使用分号 [true/false]: true
  最大行宽 [80]:
  文件命名风格 [kebab-case]:
  函数命名风格 [camelCase]:
  测试框架 [vitest]:
  AI 输出语言 [zh-CN/en]: zh-CN
  严格模式 [true/false]: true

  生成配置文件中...
    ai/config.yaml
    ai/.version
    ai/state/ (3 个文件)
    ai/memory/ (3 个文件)
    ai/rules/ (10 个文件)
    ai/specs/, ai/changes/ (已创建)

  AIOS 初始化完成！
```

### `aios status` 输出

```
======== AIOS 项目状态 ========
  AIOS 版本: v1.0.0 (当前: v1.0.0)
  项目: MyApp
  预设: node-typescript
  当前 Change: add-user-login
  最后更新: 2026-05-16

  活跃 Changes:
    - add-user-login
```

---

## 与其他技能包共存

AIOS 设计为可与其他技能包/IDE 工具和平共处。启动时自动检测冲突，提供三种模式选择。

### 检测机制

会话启动时，`pai:bootstrap` 扫描：

1. **技能重叠** — 在 7 个领域中检测功能重叠：需求设计、任务规划、TDD 测试、调试、代码审查、收尾归档、Git 工作流
2. **项目痕迹** — 如 `openspec/`、`docs/superpowers/specs/` 等目录

### 冲突解决

如果检测到冲突且 `coexistence_mode = ask`（默认），会看到：

```
[AIOS] 检测到以下可能冲突的技能包:

  技能重叠: brainstorming (Superpowers) ←→ pai-design (AIOS)
  项目痕迹: openspec/ 目录存在

请选择共存模式:
  A) AIOS 独占模式 (忽略其他技能包)
  B) 互补模式 (AIOS 仅提供规则，其他技能包驱动工作流)
  C) 本会话禁用 AIOS 技能链 (仅注入规则)

你的选择: _
```

选择会持久化到 `ai/config.yaml`。

### 互补模式详解

互补模式下，AIOS 作为**后台规则引擎**运行：

- 100 条规则全部注入并强制生效
- 代码规范（缩进/引号/命名）应用到每次编码操作
- L1 红线保护阻止危险操作
- **不注入**技能链触发规则——你的其他技能包驱动工作流

---

## 设计理念

| 理念 | 实现 |
|------|------|
| **技能链优先于随意行动** | 每次变更遵循验证过的 8 技能流程 |
| **证据优先于断言** | 测试通过才算完成；审查通过才归档 |
| **红线永不下线** | L1 安全规则在**任何模式**下贯穿所有会话 |
| **先设计再编码** | 设计确认关防止过早实现 |
| **记忆优于遗忘** | `ai/state/` 和 `ai/memory/` 跨会话保持项目上下文 |
| **约束即护栏** | 100 条规则防止常见错误；严格模式阻断违规 |
| **个性化优先于教条** | `ai/config.yaml` 记录你自己的习惯，不是别人的 |
| **共存优先于锁定** | 检测其他工具，提供互补模式，不强制选择 |
| **平台无关** | 相同技能通过 `tool-map.yaml` 在 OpenCode/Claude Code/未来平台上运行 |
| **持续改进** | `pai:reflect` 捕获经验教训；`aios update` 随时间添加新规则 |

---

## 安装参考

### 快速安装

```bash
# CLI 工具
npm install -g @huahu/paios

# 注册到 OpenCode（自动检测）
paios install

# Claude Code（插件市场）
/plugin marketplace add alex-hlh/aios-marketplace
/plugin install paios@aios-marketplace
```

### OpenCode

OpenCode 由 `paios install` 自动配置。手动配置则编辑 `opencode.json`：

```json
{ "plugin": ["paios@git+https://github.com/alex-hlh/Paios.git"] }
```

### Claude Code

```bash
/plugin marketplace add alex-hlh/aios-marketplace
/plugin install paios@aios-marketplace
```
```bash
/plugin marketplace add alex-hlh/aios-marketplace
/plugin install paios@aios-marketplace
```

### 手动安装（CI/CD 或批量场景）

```bash
npx @huahu/paios init --defaults
```

---

## 致谢

AIOS 建立在以下先驱项目的基础之上：

- **[Superpowers](https://github.com/obra/superpowers)** by Jesse Vincent — 技能链模式（brainstorm → plan → build → review → finish）启发了我们的 8 技能工作流。Red Flags 防合理化表、对抗性压力测试、"技能即强制"理念均直接来自 Superpowers 的实战验证。

- **[OpenSpec](https://github.com/Fission-AI/OpenSpec)** by Fission AI — Spec/Change 管理模型（spec 为真相源、change 为 delta 提案、归档工作流）和 OPSX 流体操作范式塑造了我们的 `pai:spec` 和 `pai:done` 技能。

- **[OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)** — 我们的安全、错误处理和日志规范（27 条规则）源自 OWASP 在输入验证、XSS 防护、SQL 注入、密码存储、错误处理、日志记录、文件上传安全方面的权威指南。

- **[Google Code Review Standards](https://google.github.io/eng-practices/)** — 三维审查模型（完整性、正确性、一致性）和风格指南（函数长度、命名、注释）借鉴自 Google 工程实践。

- **[Conventional Commits](https://www.conventionalcommits.org/)** — 结构化提交信息的 v1.0.0 规范。

- **[Prettier](https://prettier.io/)** / **[PEP 8](https://peps.python.org/pep-0008/)** / **[Effective Go](https://go.dev/doc/effective_go)** / **[Rust Style Guide](https://doc.rust-lang.org/nightly/style-guide/)** — 每个预设档案均基于该语言社区的事实标准格式化工具或风格指南。

## 许可证

MIT © 2026 Paios

基于 [Superpowers](https://github.com/obra/superpowers) (MIT) 和 [OpenSpec](https://github.com/Fission-AI/OpenSpec) (MIT) 的模式，安全规则源自 [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/) (CC BY-SA 4.0)。
