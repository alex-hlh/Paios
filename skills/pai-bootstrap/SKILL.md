---
name: pai-bootstrap
description: AIOS 引导技能 — 会话启动时自动激活。加载L1红线、平台适配、项目状态、规则、Red Flags和压力测试。使用该技能后声明技能链触发规则。
triggers:
  - session_start
  - new task
  - new project
  - start of conversation
---

# AIOS Bootstrap (pai:bootstrap)

<CRITICAL>
你必须在执行任何操作前完成以下启动序列。这不是可选步骤。
</CRITICAL>

## 启动序列

### 步骤 0: 技能环境扫描与冲突检测

在执行任何 AIOS 流程之前，必须先检测当前环境中是否存在其他技能包，避免指令冲突。

**0.1 扫描已注册的技能**

使用 `{skill-loader}` 获取当前会话中所有可用技能列表。对照以下"重叠技能"清单：

```
重叠领域检测表 (任一命中即为潜在冲突):

领域: 需求/设计
  检测: brainstorming, spec-driven, prd-writer, opsx:propose, opsx:explore

领域: 任务/计划
  检测: writing-plans, executing-plans, opsx:new, opsx:ff, opsx:continue

领域: 测试/TDD
  检测: test-driven-development, tdd, red-green-refactor

领域: 调试
  检测: systematic-debugging, debugging, debug

领域: 代码审查
  检测: requesting-code-review, receiving-code-review, code-review

领域: 收尾/归档
  检测: finishing-a-development-branch, opsx:archive, opsx:verify

领域: Git 工作流
  检测: using-git-worktrees, git-worktree

领域: 元技能/引导
  检测: using-superpowers, bootstrap, init
```

**0.2 检测项目中的其他技能包痕迹**

检查项目根目录是否存在以下目录或文件：
- `docs/superpowers/specs/` — Superpowers 设计文档
- `openspec/` — OpenSpec 变更管理
- `.claude-plugin/` — Claude Code 插件
- `.cursor-plugin/` — Cursor 插件
- `.codex-plugin/` — Codex 插件

**0.3 读取共存配置**

读取 `ai/config.yaml` 中的 `aios.coexistence_mode` 字段：

```
coexistence_mode 行为:
  ask (默认)        → 检测到冲突时，暂停启动序列，向用户展示检测结果，
                       询问选择模式。将用户选择写入 ai/config.yaml 以记住偏好。
  standalone         → AIOS 完全接管。忽略其他技能包的技能链。
                       仅 AIOS 的 Red Flags 和规则生效。强制执行 AIOS 技能链。
  complementary      → AIOS 退化为"上下文注入器"模式：
                       - 仍然加载 L1 红线 + 项目规则 + 状态 + 配置
                       - 仍然注入 Red Flags 表和压力测试
                       - **不注入** AIOS 技能链触发规则
                       - 不覆盖或干扰其他技能包的工作流
  rules-only         → 最轻模式：
                       - 仅注入 L1 红线 + 项目规则 + 配置
                       - 不注入 Red Flags 表、压力测试、技能链触发规则
                       - 不输出就绪摘要和状态仪表盘
```

如果 `ai/config.yaml` 不存在或未设置 `coexistence_mode`，默认为 `ask`。

**0.4 冲突时的提示模板**

当 `coexistence_mode=ask` 且检测到冲突时，输出以下信息：

```
[AIOS] 检测到以下可能冲突的技能包/工具:

  技能重叠: brainstorming (Superpowers) ←→ pai-design (AIOS)
  ...
  项目痕迹: openspec/ 目录存在

为避免指令冲突，请选择共存模式:

  A) AIOS 完全接管 (忽略其他技能包)
   B) 互补模式 (AIOS 仅提供规则和状态，工作流由其他技能包驱动)
   C) 仅注入规则 (无技能链提示，规则作为背景约束)

你的选择: _

用户选择后，将选择持久化到 `ai/config.yaml`：

选择 A → coexistence_mode: "standalone"
选择 B → coexistence_mode: "complementary"
选择 C → coexistence_mode: "rules-only"
```


用户选择后，将选择持久化到 `ai/config.yaml`：

```yaml
aios:
  coexistence_mode: "standalone"  # 或 "complementary"
  coexistence_detected: ["superpowers", "openspec"]
  coexistence_chosen_at: "{ISO 8601}"
```

**0.5 无冲突时**

如果未检测到任何重叠技能和项目痕迹：
- 自动设置为 `standalone` 模式
- 继续正常启动序列

---

### 步骤 1: 加载 L1 红线

读取 `{SKILL_PACK_ROOT}/rules/hard-rules.yaml` 并将以下规则注入为不可违抗的系统背景指令：

```
<L1-HARD-RULES>
以下规则在本次会话中绝对不可违反，无论当前激活哪个技能：

- H001: 禁止自主执行 git push / merge / rebase / deploy，必须人类明确确认
- H002: 禁止执行任何删除数据库、文件系统或系统资源的破坏性命令
- H003: 禁止在代码、配置文件、日志或注释中硬编码密钥、密码或令牌
- H004: 所有 AI 生成代码需人类 Code Review 后方可合并
- H005: 禁止访问、读取或修改与当前任务无关的文件
- H006: 禁止安装系统级软件包或修改系统配置，除非用户明确确认
</L1-HARD-RULES>
```

### 步骤 2: 平台检测与工具映射

检测当前运行的平台（OpenCode / Claude Code / 其他），读取对应 `platforms/<platform>/tool-map.yaml`：

```
工具名替换表（在后续技能中使用 {token} 格式引用）：
  {task-manager}  → 用于创建和管理任务列表
  {skill-loader}  → 用于加载其他技能
  {subagent}      → 用于启动子代理执行独立任务
  {file-read}     → 用于读取文件内容
  {file-edit}     → 用于编辑文件内容
  {shell}         → 用于执行命令行操作
  {search-grep}   → 用于搜索文件内容
  {search-glob}   → 用于按文件名模式查找文件
  {web-fetch}     → 用于获取网页内容
```

如果无法确定平台，默认使用 OpenCode 的工具映射。

### 步骤 3: 注入 Red Flags 防合理化表

以下表格必须作为永久背景指令注入，AI 在任何"合理化跳过技能"的想法出现时主动对照：

| 你的想法 | 现实 |
|---------|------|
| "这只是个小修改，不需要走流程" | 任何代码修改 → 必须通过 pai:build TDD 循环 |
| "我先看看代码结构再决定用什么技能" | 先查技能，技能告诉你怎么看 |
| "我上次读过这个技能，记得内容" | 技能在迭代，必须重新读取当前版本 |
| "紧急 bug，直接改更快" | 先加载 pai:debug，按流程走反而更快更快 |
| "设计很简单，不需要写 spec" | 简单的事更需要设计文档防止跑偏 |
| "测试可以后面再补" | 绝对禁止先写实现再补测试 |
| "这个 task 太小了，不必审查" | 每个 task 完成后必须触发 pai:review |
| "我大概记得规则内容" | 规则文件是唯一真源，必须实际读取 |
| "我已经知道要用什么技能" | 即使 1% 可能适用也要加载 |
| "这不算一个任务" | 任何行动都是任务，先检查技能 |
| "技能太重了，这次简单点" | 简单的事变复杂时，技能就是安全带 |
| "先做这一件事再查技能" | 在做任何事之前先检查技能 |

### 步骤 4: 注入对抗性压力测试

```
<PRESSURE-TEST>
以下场景训练你在极端情况下仍然遵守技能链：

场景1 — 时间紧迫:
  用户说：生产系统挂了，每分钟损失5000美元。
  选项A：立即调试（5分钟）  选项B：先加载pai:debug技能再调试（7分钟）
  → 正确答案永远是 B。跳过技能会导致盲猜修复，引入新bug，最终反而更慢。

场景2 — 已完成工作:
  你写了45分钟代码，运行正常。用户说"提交吧"。
  选项A：提交  选项B：检查测试覆盖（pai:build要求）后再提交
  → 正确答案是 B。测试是强制要求，不是"有时间就做"。

场景3 — 看似简单:
  用户说：就是给按钮换个颜色，不需要设计讨论。
  → 即使是UI变更也必须：确认改动范围 → 确认影响 → 触发pai:design（设计可以很短）
</PRESSURE-TEST>
```

### 步骤 5: 项目初始化检查与自动初始化

检查项目根目录是否存在 `ai/` 目录：

#### 5A. 如果 `ai/` 目录不存在 → 自动初始化

不要简单地提示用户运行脚本。按以下流程**使用 AI 自身的工具完成初始化**：

1. 询问用户预设语言/技术栈：

```
本项目尚未初始化 AIOS 工程环境。

选择预设技术栈即可自动完成初始化（默认可直接 Enter）:

  A) node-typescript (Node.js / TypeScript / React / Vue)
  B) python (Python / Django / FastAPI)
  C) go (Go / Gin)
  D) rust (Rust / Cargo)
  E) java (Java / Spring Boot)
  F) universal (通用 / 不确定)

你的选择 [F]: _
```

2. 询问项目名称（默认为当前目录名）：

```
项目名称 [{dirname}]: _
一句话描述: _
```

3. 根据所选预设，向用户展示默认配置并确认（一行展示全部关键配置）：

```
检测到 {preset_name} 预设，默认配置:
  缩进: {indent} | 引号: {quotes} | 分号: {semicolons} | 行宽: {line_length}
  文件命名: {file_naming} | 测试框架: {test_framework}
  commit 风格: conventional | 分支命名: feature/<name>
  AI 输出语言: zh-CN | 严格模式: 开启

确认以上默认配置？[Y/n]: _
```

用户确认后，直接创建文件（跳过再次确认）。如用户选择 `n`，针对需要修改的项逐一询问。

4. **创建目录结构**：使用 `{shell}` 或 AI 自身的文件系统工具创建：

```
ai/state/  ai/memory/  ai/rules/custom/  ai/specs/  ai/changes/
```

5. **生成文件**：从技能包 `templates/` 目录读取模板，替换以下占位符后写入项目：

| 模板文件 | 输出路径 | 关键占位符 |
|---------|---------|-----------|
| `templates/config.yaml` | `ai/config.yaml` | `{project_name}, {preset_name}, {code_indent}, {code_quotes}, ...` |
| `templates/.version` | `ai/.version` | 直接写入 `v1.0.0`（当前版本号） |
| `templates/state/*.md` | `ai/state/` (3 个文件) | `{date}, {current_change}, {next_actions}, ...` |
| `templates/memory/*.{md,yaml}` | `ai/memory/` (3 个文件) | `{date}, {tech_stack}` |
| `templates/rules/*.yaml` | `ai/rules/` (10 个文件) | `{testing_coverage_threshold}, {git_branch_naming}` |
| `templates/specs/.gitkeep` | `ai/specs/.gitkeep` | — |
| `templates/changes/.gitkeep` | `ai/changes/.gitkeep` | — |

**占位符值对照表（从预设档案和用户输入获取）：**

| 占位符 | 来源 | node-typescript 示例值 |
|--------|------|----------------------|
| `{project_name}` | 用户输入 / 目录名 | "my-app" |
| `{project_description}` | 用户输入 | "在线协作平台" |
| `{preset_name}` | 用户选择的预设 | "node-typescript" |
| `{code_indent}` | 预设档案 | 2 |
| `{code_quotes}` | 预设档案 | double |
| `{code_semicolons}` | 预设档案 | true |
| `{code_trailing_commas}` | 预设档案 | all |
| `{code_max_line_length}` | 预设档案 | 80 |
| `{naming_files}` | 预设档案 | kebab-case |
| `{naming_functions}` | 预设档案 | camelCase |
| `{naming_classes}` | 预设档案 | PascalCase |
| `{naming_constants}` | 预设档案 | UPPER_SNAKE_CASE |
| `{naming_variables}` | 预设档案 | camelCase |
| `{git_commit_style}` | 预设档案 | conventional |
| `{git_branch_naming}` | 预设档案 | feature/<name> |
| `{git_sign_commits}` | 预设档案 | false |
| `{testing_framework}` | 预设档案 | vitest |
| `{testing_coverage_threshold}` | 预设档案 | 80 |
| `{testing_require_integration}` | 预设档案 | true |
| `{comments_language}` | 预设档案 | zh-CN |
| `{aios_language}` | 预设档案 | zh-CN |
| `{aios_strict_mode}` | 用户选择 (默认 true) | true |
| `{current_change}` | 固定值 | None |
| `{current_sprint}` | 固定值 | Project init |
| `{blockers}` | 固定值 | None |
| `{next_actions}` | 固定值 | Complete project setup |
| `{task_summary}` | 固定值 | Project init |
| `{date_range}` | 固定值 | (当前日期) |
| `{tech_stack}` | 用户选择的预设 | node-typescript |
| `{date}` | 当前日期 | 2026-05-16 |
| `{iso8601}` | 当前时间戳 | 2026-05-16T... |

**条件占位符**（仅特定预设产生）：

| 占位符 | 触发条件 | 值 |
|--------|---------|---|
| `{indent_style_line}` | Go 预设 (indent=0) | `indent_style: tabs` |
| `{naming_react_line}` | 预设含 react_components 字段 | `react_components: PascalCase` |

6. 输出完成摘要，然后**自动继续步骤 6**（读取刚刚生成的 `ai/state/` 和 `ai/config.yaml`）。

#### 5B. 如果 `ai/` 目录存在但无 `.version` → 补充版本文件

使用 `{file-read}` 检查 `ai/.version` 是否存在：
- 如果不存在 → 提示："检测到旧版 ai/ 目录（缺少 .version），是否补充？[Y/n]"
- 用户确认后写入当前版本号

#### 5C. 版本不匹配 → 提示更新

- 如果 `ai/.version` 版本与 `{SKILL_PACK_VERSION}` 不匹配 → 提示："项目 AIOS 版本 (X) 与当前技能包版本 (Y) 不一致，建议运行 `aios update` 或让我帮你更新"
- 用户可选择让 AI 执行更新（添加新规则模板，不覆盖用户已有文件）

#### 5D. 版本一致 → 正常继续

### 步骤 6: 读取项目状态

如果 `ai/` 目录存在，依次读取：

1. `ai/config.yaml` → 提取 conventions 和 aios 配置
2. `ai/state/current.md` → 当前工作焦点和阻塞项
3. `ai/state/tasks.md` → 任务看板
4. `ai/state/roadmap.md` → 版本路线图
5. `ai/memory/glossary.yaml` → 项目统一术语表

**中断恢复检测：**

读取 `ai/state/current.md` 后，如果发现存在"进行中"的 change 且 tasks.md 有未完成的 task，输出中断恢复提示：

```
+============================================+
|  INTERRUPTION DETECTED                      |
+============================================+
|                                            |
|  Previous session was interrupted during:  |
|    Change:  add-user-login                 |
|    Phase:   pai:build (TDD cycle)          |
|    Task:    2.2 Auth middleware ← was ON   |
|                                            |
|  Resume options:                           |
|                                            |
|  A) Continue where I left off (recommended)|
|     → pai:build resumes from Task 2.2     |
|                                            |
|  B) Review what was completed              |
|     → pai:review checks all done tasks     |
|                                            |
|  C) Start fresh (archive current change)   |
|     → pai:done archives as-is              |
|                                            |
+============================================+

你的选择 [A]: _
```

**中断恢复时各技能行为：**

| 中断于 | 恢复技能 | 恢复行为 |
|--------|---------|---------|
| pai:design 中 | pai:design | 读已有 proposal/design，从上次确认的节继续 |
| pai:spec 中 | pai:spec | 读已有 proposal/design，继续生成剩余 artifact |
| pai:build 中 | pai:build | 读 tasks.md，从第一个未勾选 task 继续 TDD |
| pai:debug 中 | pai:debug | 重新复现问题，定位状态从上次记录恢复 |
| pai:review 中 | pai:review | 重新审查当前 task，上次结果仅供参考 |
| pai:done 中 | pai:done | 检查是否所有步骤已完成，继续未完成的步骤 |

### 步骤 7: 扫描并加载所有规则文件

<RULE-MODE-AWARE>
读取 `ai/config.yaml` 中的 `aios.rule_mode` 字段，决定规则的注入方式：

**full 模式（默认）：**
扫描 `ai/rules/` 下所有 `.yaml` 文件（包括 `custom/` 子目录），注入全部规则全文：

```
规则优先级（full 模式，~21KB）：
  ai/rules/hard-rules.yaml      → L1 项目级红线（不可违抗）
  ai/rules/arch-rules.yaml      → L2 架构约束
  ai/rules/module-rules.yaml    → L2 模块边界与依赖规则
  ai/rules/security-rules.yaml  → L2 安全规范 (OWASP)
  ai/rules/error-rules.yaml     → L2 错误处理规范 (OWASP)
  ai/rules/logging-rules.yaml   → L2 日志规范 (OWASP)
  ai/rules/api-rules.yaml       → L2 API 设计规范
  ai/rules/git-rules.yaml       → Git 规范
  ai/rules/style-rules.yaml     → L3 代码风格
  ai/rules/test-rules.yaml      → L3 测试规范
  ai/rules/custom/*.yaml        → 用户自定义规则
```

**summary 模式（上下文紧张时推荐，~2KB）：**
只注入规则摘要——ID + 一句话描述。当 `pai:review` 检测到违规时，再从对应文件读取完整规则：

```
规则摘要（summary 模式）：
  H001-H008: L1 红线 — 禁止自主 git push / 禁止破坏性命令 / 禁止硬编码密钥 / ...
  A001-A014: L2 架构 — 分层架构 / 统一响应格式 / 参数化查询 / 事务边界 / ...
  M001-M012: L2 模块 — 依赖方向内指 / 禁止循环依赖 / 接口隔离 / 框架隔离 / ...
  SEC001-SEC010: L2 安全 — 输入验证 / XSS防护 / SQL注入 / 密码哈希 / 文件上传 / ...
  E001-E007: L2 错误 — 全局异常处理 / 状态码 / 消息脱敏 / RFC 7807 / 异步错误 / ...
  LOG001-LOG009: L2 日志 — 安全事件 / 日志格式 / 敏感排除 / 注入防护 / traceId / ...
  API001-API008: L2 API — 名词资源 / kebab路径 / 版本控制 / 分页 / 信封格式 / ...
  G001-G006: L2 Git — Conventional Commits / 破坏性标记 / 分支命名 / ...
  S001-S016: L3 风格 — 注释 / 禁止any / 结构化日志 / 函数长度≤50 / 嵌套≤3 / ...
  T001-T010: L3 测试 — 覆盖率≥80% / 集成测试 / AAA / mock / TDD / 测试隔离 / ...
```

如果 `ai/config.yaml` 未设置 `rule_mode`，默认为 `full`。

当上下文窗口剩余 <30% 时，优先建议用户切换为 `summary` 模式：
```
+--------------------------------------------+
|  Context usage: 72% (144K/200K)             |
|  Rule mode: full (21KB)                     |
|  Suggestion: switch to summary mode (~2KB)  |
|  Run: edit ai/config.yaml, set rule_mode    |
+--------------------------------------------+
```
</RULE-MODE-AWARE>
规则优先级：
  ai/rules/hard-rules.yaml      → L1 项目级红线（不可违抗）
  ai/rules/arch-rules.yaml      → L2 架构约束
  ai/rules/module-rules.yaml    → L2 模块边界与依赖规则
  ai/rules/security-rules.yaml  → L2 安全规范 (OWASP)
  ai/rules/error-rules.yaml    → L2 错误处理规范 (OWASP)
  ai/rules/logging-rules.yaml  → L2 日志规范 (OWASP)
  ai/rules/api-rules.yaml      → L2 API 设计规范
  ai/rules/git-rules.yaml      → Git 规范
  ai/rules/style-rules.yaml    → L3 代码风格
  ai/rules/test-rules.yaml     → L3 测试规范
  ai/rules/custom/*.yaml       → 用户自定义规则
```

### 步骤 8: 注入个性化配置

从 `ai/config.yaml` 读取并注入到代码生成背景指令：

```
<PROJECT-CONFIG>
项目: {project.name} — {project.description}
预设档案: {preset}
技术栈: (从 preset 推断)

代码规范:
  缩进: {conventions.code.indent} 空格
  引号: {conventions.code.quotes}
  分号: {conventions.code.semicolons}
  尾逗号: {conventions.code.trailing_commas}
  最大行宽: {conventions.code.max_line_length}

命名规范:
  文件: {conventions.naming.files}
  函数: {conventions.naming.functions}
  类: {conventions.naming.classes}
  常量: {conventions.naming.constants}
  变量: {conventions.naming.variables}

测试框架: {testing.framework}

Git规范: {conventions.git.commit_style} 格式 commit
AIOS控制: strict_mode={aios.strict_mode}, auto_archive={aios.auto_archive}, language={aios.language}
</PROJECT-CONFIG>
```

如果 `ai/config.yaml` 不存在，使用 universal 预设的默认值。

### 步骤 9: 声明技能链触发规则

<MODE-AWARE>
根据步骤 0 确定的 coexistence_mode：

**standalone 模式（默认，无冲突时）：**

注入以下触发规则：

```
技能链触发规则（本次会话中始终生效）:

| 当前状态 | 自动触发技能 |
|---------|-------------|
| 用户提出新功能/修改需求 | → pai:design |
| 设计文档已确认 | → pai:spec |
| tasks.md 就绪，用户确认开始编码 | → pai:build |
| 测试失败 / 运行时错误 / 用户报告bug | → pai:debug |
| 每个 task 勾选完成后 | → pai:review |
| 全部 tasks 完成 | → pai:done |
| pai:done 完成后 | → pai:reflect |
```

**complementary 模式（检测到其他技能包时用户选择）：**

不注入技能链触发规则。改为注入以下说明：

```
AIOS 当前运行在互补模式 (complementary)。
已注入: L1 红线、项目规则 (ai/rules/)、代码规范 (ai/config.yaml)、Red Flags 表。
技能链由其他技能包驱动。AIOS 规则作为背景约束在所有操作中生效。
如需切换为 standalone 模式，修改 ai/config.yaml 中 aios.coexistence_mode 为 "standalone"。
```
</MODE-AWARE>

### 步骤 10: 输出就绪摘要（ASCII 仪表盘）

如果项目有当前活跃的 change，输出详细仪表盘：

```
+============================================+
|          AIOS 就绪                          |
+============================================+
|                                            |
|  Platform:  OpenCode                       |
|  Mode:      standalone                     |
|  Project:   MyApp                          |
|  Preset:    node-typescript                |
|                                            |
+-- Current Change: add-user-login ----------+
|                                            |
|  Tasks:    [#######         ]  45%         |
|  (5/11 complete)                           |
|                                            |
|  [x] 1.1 User model                        |
|  [x] 1.2 Validation                        |
|  [x] 2.1 JWT util                          |
|  [ ] 2.2 Auth middleware    ← NEXT         |
|  [ ] 2.3 Login endpoint                    |
|  [ ] 3.1-3.3 (4 tasks)                     |
|                                            |
|  Blocker:  Awaiting JWT_SECRET env config   |
|                                            |
+-- Rules Loaded -----------------------------+
|                                            |
|  L1 (red lines):      8/8    ✅              |
|  L2 (arch/module/sec): 65/66   ⚠️ 1 skipped |
|  L3 (style/test):     26/26  ✅              |
|                                            |
+-- Next Actions -----------------------------+
|                                            |
|  1. Start Task 2.2: Auth middleware         |
|  2. Or update ai/config.yaml if blocked    |
|                                            |
+============================================+
```

如果项目无活跃 change，输出简版：

```
+------------------------------------+
|  AIOS Ready                        |
+------------------------------------+
|  Platform: OpenCode  |  Mode: standalone  |
|  Project: MyApp      |  Preset: node...  |
|  Rules:  100/100 loaded   ✅                |
|  Change: none — say what you want to build |
+------------------------------------+
```
---

## 规则引用

- 通用 L1 红线: `rules/hard-rules.yaml`
- 平台工具映射: `platforms/<platform>/tool-map.yaml`
- 项目配置: `ai/config.yaml`
- 项目规则: `ai/rules/*.yaml`
- 项目状态: `ai/state/`

## 技能链

bootstrap → design → spec → build → (debug / review) → done → reflect

## 使用场景速查

| 你的情况 | 操作 |
|---------|------|
| 全新项目，想用 AIOS 管全程 | `npx @huahu/paios init` → 重启 AI → 说需求 |
| 已有项目，想适配现有代码 | `/pai:retro` → AI 自动检测技术栈和风格 → 生成配置 |
| 已有 AIOS 项目，刚打开 | 无需操作，`pai:bootstrap` 自动加载 |
| 已有项目，只想用调试功能 | 直接说"帮我调试"，`pai:debug` 独立可用 |
| 已有项目，想走完整流程 | 先 `pai:init` 初始化 → 然后说需求 |
| 想单独用某个技能 | 直接调用，如 `/pai:review` 审查一段代码 |
| 多个技能包共存 | `pai:bootstrap` 会检测冲突，提供 coexist 模式 |

## 技能独立性说明

所有 `pai:*` 技能支持两种调用方式：

1. **链式自动触发**（standalone 模式）：按 bootstrap → design → spec → build → ... 自动进入下一环
2. **独立手动调用**：任何技能都可以通过 `/pai:xxx` 命令或自然语言直接调用。

### 独立调用依赖与降级规则

| 技能 | 必需要素（不能降级） | 可降级（没有时用默认值） | 完全独立可用？ |
|------|---------------------|----------------------|:---:|
| **pai:init** | 无 | — | ✅ |
| **pai:bootstrap** | 无（无 ai/ 则引导 init） | — | ✅ |
| **pai:design** | 无 | `ai/config.yaml` → universal 预设 | ✅ |
| **pai:debug** | 无 | `ai/rules/` → 仅跳过反模式记录 | ✅ |
| **pai:review** | 无 | `ai/rules/` → 仅检查通用原则 | ✅ |
| **pai:reflect** | 无 | `ai/memory/` → 仅输出不记录 | ✅ |
| **pai:spec** | `proposal.md` + `design.md` | `ai/specs/` → 假设无现有 spec | ❌ 需设计文档 |
| **pai:build** | `tasks.md` | `ai/config.yaml` → universal 默认 | ❌ 需任务清单 |
| **pai:done** | 完成的 change 结构 | `ai/rules/` → 仅通用检查 | ❌ 需完成任务 |

**降级策略详解：**
- 缺少 `ai/config.yaml` → 使用 universal 预设（缩进=2, 引号=double, 测试=通用）
- 缺少 `ai/rules/` → 仅使用全局 L1 红线（8 条），跳过高阶规则检查
- 缺少 `ai/specs/` → 假设无现有 spec，只生成 ADDED requirements
- 缺少 `ai/memory/` → 反模式/复盘仅口头输出，不写入文件
- 缺少 `ai/changes/` → pai:spec 自动创建目录；pai:done 无需归档
