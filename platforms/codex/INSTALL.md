# Codex 安装说明

## 前置条件

- Codex CLI 或 Codex Desktop 已安装

## 安装方式 1：手动配置 AGENTS.md

在项目根目录的 `AGENTS.md`（或全局 AGENTS.md）中添加：

```markdown
## AIOS 工程体系

本项目使用 AIOS（个人AI工程操作系统）。启动时请加载 `pai:bootstrap` 技能。

可用技能:
- pai:bootstrap — 启动引导、加载规则和状态
- pai:prd — 产品规划（PRD 文档生成）
- pai:story — 需求分析与原型设计
- pai:init — 项目初始化
- pai:retro — 已有项目逆向适配
- pai:docs — 项目文档生成
- pai:design — 需求讨论和设计
- pai:amend — 开发中途需求变更
- pai:spec — Spec/Change 管理
- pai:build — TDD 开发
- pai:debug — 系统调试
- pai:review — 代码审查
- pai:done — 归档收尾
- pai:reflect — 自我反思
```

## 安装方式 2：通过 Codex Plugin 系统

将本仓库克隆到本地，然后在 Codex 中通过插件配置加载。

```powershell
git clone https://github.com/alex-hlh/Paios.git C:\path\to\Paios
```

在项目根目录的 `.codex-plugin/plugin.json` 中引入：

```json
{
  "name": "aios",
  "version": "1.0.0",
  "repository": "C:\\path\\to\\Paios"
}
```

## 安装方式 3：通过 MCP 服务器（推荐）

Codex 支持通过 MCP (Model Context Protocol) 服务器集成 AIOS。

```powershell
# 1. 安装依赖
cd C:\path\to\Paios\mcp
npm install

# 2. 在项目根目录的 .codex-plugin/plugin.json 中添加 MCP 配置：
# {
#   "name": "aios",
#   "version": "1.0.0",
#   "mcpServers": {
#     "aios": {
#       "command": "node",
#       "args": ["C:\\path\\to\\Paios\\mcp\\server.js"]
#     }
#   }
# }
```

重启 Codex 后可通过 MCP 资源读取：
- `aios://rules/*` — 所有规则文件
- `aios://presets/*` — 技术栈预设
- `aios://skills/*` — 技能定义
- `aios://version` — 当前版本

## 项目初始化

```powershell
cd my-project
& C:\path\to\Paios\scripts\aios.ps1 init
```

## 验证

在新的 Codex 对话中询问："Tell me about your skills"
应看到 AIOS 技能列表。

## 更新

```powershell
cd C:\path\to\Paios
git pull
```
