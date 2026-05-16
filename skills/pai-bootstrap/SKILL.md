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
  ask (默认)       → 检测到冲突时，暂停启动序列，向用户展示检测结果，
                      询问选择模式。将用户选择写入 ai/config.yaml 以记住偏好。
  standalone        → AIOS 完全接管。忽略其他技能包的技能链。
                      仅 AIOS 的 Red Flags 和规则生效。强制执行 AIOS 技能链。
  complementary     → AIOS 退化为"上下文注入器"模式：
                       - 仍然加载 L1 红线 + 项目规则 + 状态 + 配置
                       - 仍然注入 Red Flags 表和压力测试
                       - 不注入 AIOS 技能链触发规则
                       - 不覆盖或干扰其他技能包的工作流
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
  C) 本会话禁用 AIOS 技能链 (仅注入规则)

你的选择: _
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

### 步骤 5: 版本兼容检查

检查项目根目录是否存在 `ai/.version`：

- 如果不存在 `ai/` 目录 → 提示："本项目未初始化 AIOS。是否运行 `aios init` 初始化？"
- 如果 `ai/.version` 版本与 `{SKILL_PACK_VERSION}` 不匹配 → 提示："项目 AIOS 版本 (X) 与当前技能包版本 (Y) 不一致，建议运行 `aios update`"
- 如果版本一致 → 正常继续

### 步骤 6: 读取项目状态

如果 `ai/` 目录存在，依次读取：

1. `ai/config.yaml` → 提取 conventions 和 aios 配置
2. `ai/state/current.md` → 当前工作焦点和阻塞项
3. `ai/state/tasks.md` → 任务看板
4. `ai/state/roadmap.md` → 版本路线图
5. `ai/memory/glossary.yaml` → 项目统一术语表

### 步骤 7: 扫描并加载所有规则文件

扫描 `ai/rules/` 下所有 `.yaml` 文件（包括 `custom/` 子目录），按优先级注入：

```
规则优先级：
  ai/rules/hard-rules.yaml     → L1 项目级红线（不可违抗）
  ai/rules/arch-rules.yaml     → L2 架构约束
  ai/rules/security-rules.yaml → L2 安全规范 (OWASP)
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

### 步骤 10: 输出就绪摘要

```
AIOS 就绪
平台: {platform}
共存模式: {coexistence_mode} (standalone / complementary)
项目: {project.name} | 预设: {preset}
当前 change: {current_change 或 "无"}
下一个 task: {next_task 或 "无"}
阻塞项: {blockers 或 "无"}
已加载规则: {rule_count} 条 (L1 + L2 + L3)
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
