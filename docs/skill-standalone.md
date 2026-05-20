# AIOS Skill 独立调用与降级规则

所有 `pai:*` 技能支持两种调用方式：

1. **链式自动触发**（standalone 模式）：按 `bootstrap → design → (amend) → spec → build → ...` 自动进入下一环
2. **独立手动调用**：任何技能都可以通过 `/pai:xxx` 命令或自然语言直接调用

## 独立调用依赖与降级规则

| 技能 | 必需要素（不能降级） | 可降级（没有时用默认值） | 完全独立可用？ |
|------|---------------------|----------------------|:---:|
| **pai:init** | 无 | — | ✅ |
| **pai:prd** | 无 | `ai/config.yaml` → 使用项目名 + universal 默认 | ✅ |
| **pai:story** | prd.md（可选） | 无 prd.md → 直接询问用户功能描述 | ✅ |
| **pai:bootstrap** | 无（无 ai/ 则引导 init） | — | ✅ |
| **pai:coexist** | 无 | — | ✅ |
| **pai:design** | 无 | `ai/config.yaml` → universal 预设 | ✅ |
| **pai:amend** | 活跃 change（ai/state/current.md） | 无活跃 change → 降级为 pai:design | ✅ |
| **pai:debug** | 无 | `ai/rules/` → 仅跳过反模式记录 | ✅ |
| **pai:review** | 无 | `ai/rules/` → 仅检查通用原则 | ✅ |
| **pai:reflect** | 无 | `ai/memory/` → 仅输出不记录 | ✅ |
| **pai:spec** | `proposal.md` + `design.md` | `ai/specs/` → 假设无现有 spec | ⚠️ 需设计文档 |
| **pai:build** | `tasks.md` | `ai/config.yaml` → universal 默认 | ⚠️ 需任务清单 |
| **pai:done** | 完成的 change 结构 | `ai/rules/` → 仅通用检查 | ⚠️ 需完成的任务 |

**降级策略详解**：
- 缺少 `ai/config.yaml` → 使用 universal 预设（缩进=2, 引号=double, 测试=通用）
- 缺少 `ai/rules/` → 仅使用全局 L1 红线（8 条），跳过高阶规则检查
- 缺少 `ai/specs/` → 假设无现有 spec，只生成 ADDED requirements
- 缺少 `ai/memory/` → 反模式/复盘仅口头输出，不写入文件
- 缺少 `ai/changes/` → pai:spec 自动创建目录；pai:done 无需归档
