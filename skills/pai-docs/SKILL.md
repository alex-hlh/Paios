---
name: pai-docs
description: 项目文档生成 — 基于 ai/ 目录文件和项目代码，自动生成/更新标准项目文档（README、架构、API、贡献指南、开发指南、变更日志）。支持增量更新，不覆盖用户手写内容。
triggers:
  - "documentation"
  - "readme"
  - "api docs"
  - "technical writing"
  - "write docs"
  - "技术文档"
  - "api文档"
  - "generate docs"
  - "pai:docs"
  - "update documentation"
  - "doc"
  - "生成文档"
  - "更新文档"
  - "项目文档"
---

# Docs (pai:docs)

读取 AIOS 生成的 `ai/` 文件和项目代码，自动生成/更新标准项目文档。

## 文档体系

一个规范的项目应包含以下文档。`pai:docs` 根据已有素材按优先级生成：

| 文档 | 必须？ | AIOS 已有素材 | 生成方式 |
|------|:---:|------|---------|
| **README.md** | ✅ | ai/config.yaml, ai/specs/ | 自动生成完整版 |
| **ARCHITECTURE.md** | ✅ | ai/specs/ + ai/memory/decisions.md + 代码结构 | 生成架构文档 |
| **API_REFERENCE.md** | 🟡 | ai/specs/api/ + 代码中的路由 | 有 API 时生成 |
| **CONTRIBUTING.md** | ✅ | ai/rules/git-rules.yaml + ai/config.yaml | 生成贡献指南 |
| **DEVELOPMENT.md** | 🟡 | ai/config.yaml + package.json/配置文件 | 生成开发指南 |
| **CHANGELOG.md** | ✅ | ai/changes/archive/ | 从归档生成 |

## 流程

### 步骤 1: 素材采集

**1A. 从 AIOS 读取：**
使用 {file-read} 读取以下文件：
- `ai/config.yaml` → 项目名、描述、技术栈、编码规范
- `ai/state/roadmap.md` → 版本计划
- `ai/memory/decisions.md` → 架构决策
- `ai/rules/*.yaml` → 全部规范
- `ai/specs/` → 系统行为规格
- `ai/changes/archive/` → 变更历史

**1B. 从项目代码读取：**
使用 {search-glob} 和 {file-read} 采集：
- `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` → 依赖、脚本命令
- 项目顶层目录结构 (src/ app/ routes/ controllers/ models/)
- API 路由文件 → 发现端点
- `README.md` 是否存在 → 决定生成/更新策略

### 步骤 2: 生成/更新 README.md

**内容模板（按此结构生成）：**

```markdown
# {project_name}

{一句话描述}

## Features

<!-- AIOS-AUTO: 从 ai/specs/ 中提取的 ADDED Requirements 列表 -->
- {feature 1}
- {feature 2}
<!-- /AIOS-AUTO -->

## Quick Start

### Prerequisites
- {从 package.json/配置文件 提取的运行时要求}

### Installation
```bash
{从项目配置文件提取的安装命令}
```

### Usage
```bash
{从项目入口文件推断的使用命令}
```

## Project Structure

<!-- AIOS-AUTO: 从项目目录树生成 -->
```
src/
+-- ...
```
<!-- /AIOS-AUTO -->

## Documentation

- [Architecture](ARCHITECTURE.md)
- [API Reference](API_REFERENCE.md) (如有 API)
- [Contributing](CONTRIBUTING.md)
- [Development Guide](DEVELOPMENT.md)
- [Changelog](CHANGELOG.md)

## Tech Stack

<!-- AIOS-AUTO: 从 ai/config.yaml + 项目配置文件生成 -->
| Layer | Technology |
|-------|-----------|
| Language | {language} |
| Framework | {framework} |
| Database | {database} |
| Cache | {cache} |
| Test | {testing_framework} |
<!-- /AIOS-AUTO -->

## License

{从 LICENSE 文件读取或从 ai/config.yaml 推断}
```

**更新策略：**
- 如果 `README.md` 已存在 → 只更新 `<!-- AIOS-AUTO --> ... <!-- /AIOS-AUTO -->` 区块内的内容
- 保留用户手写的其它内容
- 如果不存在 → 生成完整文件

### 步骤 3: 生成 ARCHITECTURE.md

```markdown
# Architecture: {project_name}

## Overview

<!-- AIOS-AUTO: 从 ai/specs/ + decisions.md 合成 -->
{项目架构概要}

## Design Decisions

<!-- 从 ai/memory/decisions.md 提取 -->
| Date | Decision | Rationale |
|------|---------|-----------|
| {date} | {decision} | {rationale} |

## System Modules

<!-- 从代码结构 + ai/specs/ domain 合成 ASCII 图 -->
+-- Module A: {职责}
+-- Module B: {职责}
\-- Module C: {职责}

## Data Flow

{从 ai/specs/ 的 scenarios 推断}
<!-- /AIOS-AUTO -->

## External Dependencies

| Service | Purpose | Protocol |
|---------|---------|---------|
| {从代码依赖分析} | {目的} | {协议} |
```

### 步骤 4: 生成 API_REFERENCE.md（如有 API）

```markdown
# API Reference

<!-- AIOS-AUTO: 从 ai/specs/api/ + 代码路由文件生成 -->

## Authentication
{如有 auth spec，自动描述认证方式}

## Endpoints

### {Domain}

| Method | Path | Description |
|--------|------|-------------|
| {method} | {path} | {从 spec scenario 推断的描述} |

### GET /v1/users

**Response:**
```json
{ 从 spec scenario 推断的响应格式 }
```

**Errors:**
| Code | Description |
|------|-------------|
| {code} | {description} |
<!-- /AIOS-AUTO -->
```

### 步骤 5: 生成 CONTRIBUTING.md

```markdown
# Contributing to {project_name}

## Development Workflow

<!-- AIOS-AUTO: 从 ai/rules/git-rules.yaml + ai/config.yaml -->
本项目使用 AIOS 工程体系。贡献代码请遵循：

### Commit Convention
遵循 Conventional Commits 1.0.0：
```
<type>(scope): <description>
```
允许的 type: feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert

示例: `feat(auth): add JWT token refresh endpoint`

### Branch Naming
```
{git.branch_naming}
```

### Code Style
- 缩进: {code.indent} spaces
- 引号: {code.quotes}
- 分号: {code.semicolons}
- 行宽: {code.max_line_length}
- 文件命名: {naming.files}
- 函数命名: {naming.functions}

### Testing
- 框架: {testing.framework}
- 覆盖率: >={testing.coverage_threshold}%
- TDD: 先写测试，再写实现

### Code Review
- 所有代码需经过 Code Review
- Critical 问题必须修复
<!-- /AIOS-AUTO -->

## Pull Request Process

1. Fork the repo
2. Create branch: `{git.branch_naming}`
3. Write code + tests (TDD)
4. Ensure all tests pass
5. Submit PR with Conventional Commits title
```

### 步骤 6: 生成 CHANGELOG.md

```markdown
# Changelog

<!-- AIOS-AUTO: 从 ai/changes/archive/ 按时间倒序生成 -->

## {version} ({date})

{读取对应 archive 目录下的 proposal.md，提取 Intent 和 Scope}

### Added
- {从 archive specs/ 的 ADDED 提取}

### Changed  
- {从 archive specs/ 的 MODIFIED 提取}

### Removed
- {从 archive specs/ 的 REMOVED 提取}

<!-- /AIOS-AUTO -->
```

### 步骤 7: 输出摘要

用 ASCII 面板展示生成结果：

```
+============================================+
|  DOCUMENTATION GENERATED                    |
+============================================+
|                                            |
|  README.md            ✅  generated        |
|  ARCHITECTURE.md      ✅  generated        |
|  API_REFERENCE.md     ⏭️  skipped (no API)  |
|  CONTRIBUTING.md      ✅  generated        |
|  DEVELOPMENT.md       ✅  generated        |
|  CHANGELOG.md    ✅  updated        |
|                                            |
+============================================+
|  Source: ai/ files + project code analysis |
|  Strategy: incremental (AIOS-AUTO blocks)  |
+============================================+
```

## 更新策略（核心特性）

所有 `pai:docs` 生成的文档使用 `<!-- AIOS-AUTO -->` ... `<!-- /AIOS-AUTO -->` 标记自动生成区块：

- **只更新标记区块**：重复运行 `pai:docs` 只更新 `<!-- AIOS-AUTO -->` 内的内容
- **保留手写内容**：标记外的用户手写内容完全保留
- **新增标记不覆盖**：如果用户删除了标记，下次不重新插入
- **自动刷新**：建议在每个 change 归档后运行 `/pai:docs`，保持文档与代码同步

## 何时运行

| 时机 | 原因 |
|------|------|
| `pai:done` 归档后 | 新功能上线，更新 README features 和 CHANGELOG |
| 添加新 API 端点后 | 更新 API_REFERENCE.md |
| 修改代码结构后 | 更新 ARCHITECTURE.md |
| 修改编码规范后 | 更新 CONTRIBUTING.md |
| 项目初始化后 | 首次生成全部文档 |

## 注意事项

- **不覆盖用户手写内容**——通过 AIOS-AUTO 标记实现增量更新
- **文档语言**——与 `ai/config.yaml` 的 `aios.language` 一致（zh-CN / en）
- **API 文档**——只有检测到 API 路由时生成
- **向后兼容**——不会修改或删除已有的非 AIOS 文档
