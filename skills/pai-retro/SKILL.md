---
name: pai-retro
description: 项目逆向分析 — 扫描已有项目的代码和配置文件，自动检测技术栈、测试框架、代码风格等，生成 ai/ 目录初始化文件。适用于对非 AIOS 创建的项目进行改造。
triggers:
  - "reverse engineering"
  - "codebase analysis"
  - "existing code"
  - "逆向分析"
  - "代码适配"
  - "已有项目"
  - "retro"
  - "retrofit"
  - "逆向"
  - "适配"
  - "分析代码"
  - "retrofit"
---

# Retro (pai:retro)

对非 AIOS 创建的项目进行反向分析，自动检测技术栈和规范，生成 `ai/` 目录。

## 流程

### 步骤 1: 技术栈检测

使用 {search-glob} 和 {file-read} 依次检查项目根目录下的标志性文件：

**语言/框架检测表（按优先级）：**

| 标志文件 | 检测结果 |
|---------|---------|
| `package.json` | Node.js / TypeScript |
| `package.json` + `next.config.*` | Next.js |
| `package.json` + `vue.config.*` | Vue |
| `requirements.txt` / `pyproject.toml` | Python |
| `pyproject.toml` + `[tool.poetry]` | Python + Poetry |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pom.xml` / `build.gradle` | Java / Kotlin |
| `csproj` / `sln` | .NET |
| `composer.json` | PHP / Laravel |
| `Gemfile` | Ruby / Rails |
| 以上均无 | universal |

**测试框架检测：**

| 标志 | 检测结果 |
|------|---------|
| `vitest.config.*` / package.json 含 vitest | vitest |
| `jest.config.*` / package.json 含 jest | jest |
| `pytest.ini` / `conftest.py` | pytest |
| `*_test.go` 文件 | go test |
| `src/test/` (Java) | junit |
| `tests/` 目录 + `#[test]` | cargo test |
| 无法检测 | 使用预设默认值 |

**包管理器检测：**

| 标志 | 检测结果 |
|------|---------|
| `pnpm-lock.yaml` | pnpm |
| `yarn.lock` | yarn |
| `package-lock.json` | npm |
| `bun.lockb` | bun |

### 步骤 2: 代码风格检测

**缩进检测：**
使用 {file-read} 读取项目中最典型的源文件（如 `src/` 或 `app/` 下第一个文件），检测实际使用的缩进：

```
检测方法:
  - 统计文件中前 10 行缩进的空格数，取众数
  - 如果是 tab → indent_style: tabs
  - 否则 → indent: N spaces
```

**引号检测：**
使用 {file-read} 检查典型源文件中的 import/require 语句和字符串：
```
检测方法:
  - 统计 import '...' vs import "..."
  - 取多数派
```

**分号检测：**
检测典型源文件中行尾是否有分号：
```
检测方法:
  - 统计前 20 行有分号的次数
  - >50% → semicolons: true
```

**配置文件优先：**
如果存在 `.editorconfig`、`.prettierrc` 或 `eslint.config.*`，优先读取这些文件的配置，覆盖自动检测结果。

### 步骤 3: 命名风格检测

使用 {search-glob} 列出项目文件，统计命名模式：

| 维度 | 检测方法 | 示例 |
|------|---------|------|
| 文件命名 | 统计 `src/` 或 `app/` 下文件名模式 | `user-auth.ts` → kebab-case |
|  |  | `UserAuth.tsx` → PascalCase |
|  |  | `user_auth.py` → snake_case |
| 函数命名 | 读取典型源文件，检测函数定义模式 | `function getUser` → camelCase |
|  |  | `def get_user` → snake_case |
| 类命名 | 检测 class/struct/type 定义 | `class UserAuth` → PascalCase |
| 常量命名 | 检测 export const / CONSTANT 定义 | `MAX_SIZE` → UPPER_SNAKE_CASE |

### 步骤 4: Commit 风格检测

使用 {shell} 检查最近的 git commit 消息格式：

```bash
git log --oneline -10
```

```
检测:
  - 是否包含 feat: / fix: / chore: 等前缀 → conventional
  - 是否包含 feat(scope): → conventional with scopes
  - 皆非 → 询问用户偏好，默认 conventional
```

### 步骤 5: 展示检测结果并确认

汇总所有检测结果，用 ASCII 面板展示：

```
+============================================+
|  PROJECT ANALYSIS                           |
+============================================+
|                                            |
|  Detected:  Node.js + React + TypeScript   |
|  Test:      vitest (vitest.config.ts)      |
|  Package:   pnpm (pnpm-lock.yaml)          |
|                                            |
+-- Style -----------------------------------+
|                                            |
|  Indent:     2 spaces                      |
|  Quotes:     single (80% of imports)        |
|  Semicolons: true (90% of lines)            |
|  Line width: 80 (default)                  |
|                                            |
+-- Naming ----------------------------------+
|                                            |
|  Files:      kebab-case                    |
|  Functions:  camelCase                     |
|  Classes:    PascalCase                    |
|  Constants:  UPPER_SNAKE_CASE              |
|                                            |
+-- Git -------------------------------------+
|                                            |
|  Style:      conventional (8/10 commits)   |
|  Branch:     feature/*                     |
|                                            |
+============================================+
|  Preset: node-typescript (matched)         |
+============================================+

以上检测结果是否准确？可以逐项修改或整体确认。

[Y/n]: 确认全部
[1-8]: 修改第N项
```

### 步骤 6: 生成 ai/ 目录

用户确认后，按照与 `pai:init` 完全相同的逻辑生成 `ai/` 目录：

1. 创建 `ai/state/`, `ai/memory/`, `ai/rules/custom/`, `ai/specs/`, `ai/changes/`
2. 写入 `ai/config.yaml`（使用检测到的值）
3. 写入 `ai/.version`
4. 写入 `ai/state/` (3 个文件)
5. 写入 `ai/memory/` (3 个文件)
6. 写入 `ai/rules/` (10 个 YAML 文件)
7. 写入 `ai/specs/.gitkeep`, `ai/changes/.gitkeep`

### 步骤 7: 记录到 decisions.md

在 `ai/memory/decisions.md` 中追加：

```markdown
## {date}: AIOS 逆向适配

- **决策**: 通过 pai:retro 对已有项目进行逆向分析并生成 AIOS 配置
- **检测结果**: 技术栈={tech}, 预设={preset}, 规则=92条
- **手动调整**: {如果有的话}
```

## 注意事项

- **不修改项目代码** — pai:retro 只生成 `ai/` 目录，不影响已有代码
- **不覆盖已有 ai/** — 如果已存在，询问是否合并/覆盖
- **可重新运行** — 任何时候都可以重新分析，AIOS 会检测配置变化
- **已存在 spec?** — 如果项目已有 spec/ 或 docs/ 目录，询问是否导入

## 与 pai:init 的区别

| | pai:init | pai:retro |
|---|---------|----------|
| 适用场景 | 新项目 / 空项目 | 已有代码的项目 |
| 配置来源 | 预设档案 + 用户输入 | 自动检测 + 用户确认 |
| 速度 | 更快（一键 Enter） | 更准确（分析现有代码） |
| 交互 | Q1 选语言 → Enter 确认 | 展示分析结果 → 确认/修改 |
