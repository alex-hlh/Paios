---
name: pai-init
description: 项目初始化 — 手动触发 AIOS 项目初始化。交互式选择技术栈预设，自动生成 ai/ 目录及所有配置文件。
triggers:
  - "setup project"
  - "initialize"
  - "new project setup"
  - "start new project"
  - "项目初始化"
  - "aios init"
  - "pai:init"
  - "init project"
---

# Init (pai:init)

手动触发项目 AIOS 初始化。与 `pai:bootstrap` 步骤 5 的自动初始化逻辑完全一致。

## 流程

1. 询问用户预设语言/技术栈：

```
选择预设技术栈:

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

3. 展示默认配置并确认：

```
检测到 {preset_name} 预设，默认配置:
  缩进: {indent} | 引号: {quotes} | 分号: {semicolons} | 行宽: {line_length}
  文件命名: {file_naming} | 测试框架: {test_framework}
  commit 风格: conventional | 分支命名: feature/<name>
  AI 输出语言: zh-CN | 严格模式: 开启

确认以上默认配置？[Y/n]: _
```

4. 创建目录结构：`ai/state/  ai/memory/  ai/rules/custom/  ai/specs/  ai/changes/`

5. 从 `templates/` 读取模板文件，替换占位符后写入 `ai/` 目录

6. 输出完成摘要：

```
AIOS 初始化完成！

已生成 ai/ 目录:
  ai/config.yaml      — 项目个性化配置
  ai/.version          — AIOS v1.0.0
  ai/state/            — 当前工作焦点 (3 个文件)
  ai/memory/           — 长期项目记忆 (3 个文件)
  ai/rules/            — 80 条工程规则 (9 个文件)
  ai/specs/            — 系统行为规格
  ai/changes/          — 变更提案

下次 AI 启动时，pai:bootstrap 会自动加载项目配置。
```


## Git Hooks 安装（可选）

AIOS 提供 git hooks 自动检查提交质量。

**macOS / Linux**:
```bash
bash path/to/Paios/scripts/hooks/install.sh
```

**Windows**:
```powershell
& path\\to\\Paios\\scripts\\hooks\\install.ps1
```

安装后：
- **pre-commit hook**: 密钥扫描 + 调试代码检查 + state 更新提醒
- **commit-msg hook**: Conventional Commits 格式校验

紧急跳过：
```bash
git commit --no-verify -m "fix: critical hotfix"
```


## 预设档案参考

详见 `templates/presets/` 目录，6 个预设档案对应不同技术栈。

## 完成后

返回 `pai:bootstrap` 继续正常的启动序列（读取刚生成的 `ai/state/` 和 `ai/config.yaml`）。
