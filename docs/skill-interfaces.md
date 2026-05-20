# AIOS Skill 接口契约

本文档定义 Paios 技能链中每个 skill 的输入/输出接口契约。确保上下游 skill 之间的产物格式一致，避免静默断裂。

## 技能链总览

```
pai:prd → pai:story → pai:design → pai:spec → pai:build → pai:review → pai:done
                                        ↑
                                  pai:amend
                                              (侧线)
                              pai:debug    pai:docs    pai:reflect
```

## 文件接口清单

### `ai/prd.md` — 产品需求文档

| 属性 | 值 |
|------|-----|
| 产出 skill | `pai:prd` |
| 消费 skill | `pai:story` |
| 文件路径 | `ai/prd.md` |
| 可选性 | 可选（无此文件时 `pai:story` 直接询问用户） |
| 格式要求 | Markdown（含背景、目标、用户故事、验收标准） |

**必需结构**：
```markdown
# PRD: {产品名称}

## 背景与目标
{一句话描述要解决什么问题}

## 功能列表
- {功能1}: {一句话描述}
- {功能2}: {一句话描述}

## 用户故事（可选）
- US-01: As a..., I want..., so that...
```

**变更影响**：`pai:prd` 修改此格式时，需同步更新 `pai:story` 的解析逻辑。

---

### `ai/prototype.md` — 界面原型图

| 属性 | 值 |
|------|-----|
| 产出 skill | `pai:story`（步骤2）|
| 消费 skill | `pai:design` |
| 文件路径 | `ai/prototype.md` |
| 可选性 | 可选（纯后端项目可跳过）|
| 格式要求 | Markdown + ASCII 线框图 |

**必需结构**：
- 每个页面用 `## {页面名}` 分隔
- ASCII 原型图用代码块包裹
- 标注核心交互路径（按钮→跳转）

**变更影响**：`pai:design` 读取此文件时，主要依赖页面列表和交互路径。如新增字段需告知 design 团队。

---

### `ai/data-flows.md` — 数据流图

| 属性 | 值 |
|------|-----|
| 产出 skill | `pai:story`（步骤3）|
| 消费 skill | `pai:design`, `pai:spec` |
| 格式要求 | Markdown（含数据流向描述） |

**必需结构**：
```markdown
## {页面/模块名}
- {数据描述} → {来源} → {去向}
- {API 名}: {请求参数} → {响应}
```

---

### `ai/api-list.md` — API 接口清单

| 属性 | 值 |
|------|-----|
| 产出 skill | `pai:story`（步骤3）|
| 消费 skill | `pai:design`, `pai:spec` |
| 格式要求 | Markdown |

**必需结构**：
```markdown
| 方法 | 路径 | 请求参数 | 响应 | 说明 |
|------|------|---------|------|------|
| POST | /api/auth/login | { email, password } | { token, user } | 用户登录 |
```

---

### `ai/backend-flows.md` — 后台业务流程

| 属性 | 值 |
|------|-----|
| 产出 skill | `pai:story`（步骤4）|
| 消费 skill | `pai:design` |
| 格式要求 | Markdown（编号列表描述步骤） |

**必需结构**：
```markdown
## POST /api/auth/login
1. 验证参数
2. 查询数据库
3. 校验密码
4. 生成令牌
5. 返回结果
```

---

### `ai/feature-points.md` — 功能点追溯表

| 属性 | 值 |
|------|-----|
| 产出 skill | `pai:story`（步骤5）|
| 消费 skill | `pai:design`, `pai:spec` |
| 文件路径 | `ai/feature-points.md` |
| 格式要求 | Markdown 表格 |

**必需结构**：
```markdown
| 功能点 | 来源 PRD | MoSCoW | 关联 Story |
|--------|---------|:-----:|:----------:|
| {名称} | {模块} | Must/Should/Could/Won't | US-0X |
```
**说明**：`pai:design` 的阶段 0 自动读取此文件导入功能点列表，跳过发现式提问。

---

### `ai/specs/` — 变更规格

| 属性 | 值 |
|------|-----|
| 产出 skill | `pai:spec` |
| 消费 skill | `pai:build` |
| 目录路径 | `ai/specs/{change-id}/` |
| 格式要求 | YAML + Markdown |

**必需结构**：
```yaml
# ai/specs/{change-id}/spec.yaml
change:
  id: "{change-id}"
  title: "{变更名称}"
  type: "feature|refactor|bugfix|chore"
  design_ref: "ai/design.md"  # 关联的设计文档

requirements:
  - id: "REQ-001"
    description: "{需求描述}"
    source: "pai:story"  # 来源
    status: "added|unchanged|modified|removed"

tasks:
  - id: "T-001"
    description: "{任务描述}"
    req_ref: "REQ-001"
    type: "test|impl|docs"
```

---

### `ai/state/current.md` — 当前工作焦点

| 属性 | 值 |
|------|-----|
| 更新 skill | `pai:design`, `pai:spec`, `pai:build`, `pai:done` |
| 读取 skill | `pai:bootstrap`, `pai:amend`, 所有 skill |
| 格式要求 | Markdown |

**必需结构**：
```markdown
# Current State

## Active Change
- id: {change-id}
- title: {变更标题}
- phase: design|spec|build|review|done
- progress: {完成}/{总数}

## Blockers
- {如需描述阻塞项}
```

**变更影响**：所有更新 `current.md` 的 skill 必须保持此结构。添加字段不影响向下兼容。

---

### `ai/state/tasks.md` — 任务看板

| 属性 | 值 |
|------|-----|
| 更新 skill | `pai:spec`, `pai:build` |
| 读取 skill | `pai:build`, `pai:review`, `pai:done` |
| 格式要求 | Markdown 表格 |

**必需结构**：
```markdown
| ID | Task | Phase | Status | Assigned |
|----|------|-------|--------|----------|
| T-001 | 实现登录 API | build | done | AI |
| T-002 | 写登录单元测试 | test | in-progress | AI |
```

---

### `ai/state/roadmap.md` — 产品路线图

| 属性 | 值 |
|------|-----|
| 更新 skill | `pai:prd`, `pai:amend`（策略C）|
| 读取 skill | `pai:bootstrap`, `pai:prd` |
| 格式要求 | Markdown |

---

### `ai/config.yaml` — 项目配置

| 属性 | 值 |
|------|-----|
| 生成 skill | `pai:init` |
| 读取 skill | `pai:bootstrap`, 所有 skill |
| 格式要求 | YAML |

**参考模板**：`templates/config.yaml`

---

### `ai/memory/decisions.md` — 关键决策记录

| 属性 | 值 |
|------|-----|
| 更新 skill | `pai:design`, `pai:reflect` |
| 读取 skill | `pai:bootstrap`, `pai:design` |

---

### `ai/memory/anti-patterns.md` — 反模式记录

| 属性 | 值 |
|------|-----|
| 更新 skill | `pai:debug`, `pai:reflect` |
| 读取 skill | `pai:bootstrap`, `pai:debug`, `pai:design` |

---

### `ai/rules/*.yaml` — 规则文件

| 属性 | 值 |
|------|-----|
| 生成 skill | `pai:init` |
| 读取 skill | `pai:bootstrap`, 所有 skill |
| 来源模板 | `templates/rules/` |

**层级**：L1 硬性红线 → L2 架构/安全/模块约束 → L3 风格/测试建议
**引用方式**：通过 `enforcement` 字段区分 BLOCK_AND_WARN / REFACTOR_SUGGESTION / STYLE / WARN

---

## 版本兼容性声明

- **向后兼容**：在现有文件中添加新字段/新节不会破坏下游 skill
- **破坏性变更**：重命名/删除字段、改变文件位置、改变必需结构
- **破坏性变更流程**：
  1. 先更新此契约文档
  2. 再更新所有消费该产物的 skill
  3. 最后更新产出 skill
- **版本号**：Paios skill pack 的主版本号（`major.minor.patch`）中，major 升级对应破坏性接口变更

## 校验

运行 `scripts/validate.ps1` 验证基本完整性。接口合规性需配合实际对话测试。
