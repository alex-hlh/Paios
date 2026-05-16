---
name: pai-build
description: TDD 开发循环 — 严格的 RED-GREEN-REFACTOR 流程。先写测试，确认红灯，写最小实现，确认绿灯，重构。每个 task 完成触发 pai:review。
triggers:
  - "start implementation"
  - "ready to code"
  - "implement"
  - "开始编码"
  - "实现"
  - "写代码"
---

# Build (pai:build)

## 核心规则

<HARD-GATE>
绝对禁止以下行为：
1. 先写实现代码再补测试
2. 跳过测试直接写实现
3. 测试未失败就放过

如果发现之前已写了实现代码但无对应测试，必须先补测试（确认红灯），再验证现有实现（绿灯）。
</HARD-GATE>

## TDD 循环 — 每个 Task 执行一次

### RED: 写测试（先！）

1. 从 `ai/changes/<change-name>/tasks.md` 取下一个未完成的 task
2. 只做这一个 task，不跳到其他
3. **先写测试代码**：
   - 遵循 `ai/config.yaml` 的 `testing.framework` 指定的测试框架
   - 遵循 `ai/rules/test-rules.yaml` 的测试规范
   - 遵循 AAA 模式：Arrange → Act → Assert
   - 遵循 `ai/config.yaml` 的 conventions.naming（文件、函数、变量命名）
   - 遵循 `ai/config.yaml` 的 conventions.code（缩进、引号、分号、行宽）
   - 测试命名：test_<函数名>_<场景>_<期望结果>
4. **运行测试**：使用 {shell} 执行测试命令，确认测试失败（RED）
5. 如果测试不是真正的失败（语法错误、配置问题等）→ 先修复测试本身
6. 用 {task-manager} 更新 tasks.md 中的 task 状态为 in_progress

### GREEN: 最小实现

1. 写**最少**的代码让测试通过——不要多写一行
2. 遵循 `ai/config.yaml` 的 conventions.code 和 conventions.naming
3. 遵循 `ai/rules/arch-rules.yaml` 的架构约束
4. 遵循 `ai/rules/style-rules.yaml` 的代码风格
5. 运行测试，确认通过（GREEN）
6. 如果测试不通过 → 最简单的修改，不要猜测，逐个修复

### REFACTOR: 改进代码

1. 在测试保持通过的前提下重构：
   - 消除重复
   - 改善命名
   - 提取方法/函数
   - 遵循 `ai/config.yaml` 的命名规范
2. 每步重构后运行测试确认仍然通过

### 勾选 Task

1. 用 {file-edit} 将 tasks.md 中对应 task 的 `- [ ]` 改为 `- [x]`
2. **立即触发 pai:review** 审查本次 task 的代码

### 进度展示

每次勾选 task 后，在输出中显示 ASCII 进度条，让用户一目了然进展：

**进度条模板：**
```
[===                    ] 15%  (2/13 tasks)    ███░░░░░░░░░░░░░░░░░
```

**完整进度看板示例：**
```
Change: add-user-login
+--------------------------------------+
| 1. User Model              [RED/GREEN]|  [===========           ] 45%
| 2. Auth Logic              [PENDING]  |
| 3. Token Utility           [PENDING]  |
| 4. Login API               [PENDING]  |
| 5. Middleware              [DONE]     |  [====================   ] 90%
| 6. Login Page              [DONE]     |
| 7. Error Handling          [PENDING]  |
| 8. Integration Test        [PENDING]  |
+--------------------------------------+
Overall: [=====               ] 25%  (2/8 tasks)

Next: Task 3 - Token Utility
```

**简单版（适用于 task 数量少时）：**
```
Progress: [##########          ] 50%  (5/10 tasks)
RED: 3  |  GREEN: 5  |  REFACTOR: 2  |  PENDING: 5
```

**展示时机：**
- 每个 task 的 RED/GREEN/REFACTOR 循环完成时，更新一次进度条
- 如果同一 task 触发了 pai:debug，在 debug 完成后更新
- 进度条颜色暗示：`===` = 已完成，`   ` = 未完成

## 编码规范（全程遵守）

从 `ai/config.yaml` 注入：
- 缩进: {conventions.code.indent} spaces
- 引号: {conventions.code.quotes}
- 分号: {conventions.code.semicolons}
- 尾逗号: {conventions.code.trailing_commas}
- 最大行宽: {conventions.code.max_line_length}
- 文件命名: {conventions.naming.files}
- 函数命名: {conventions.naming.functions}
- 类命名: {conventions.naming.classes}
- 常量命名: {conventions.naming.constants}
- 变量命名: {conventions.naming.variables}

## 完成后

当前 task 完成后，下一个 task 前必须触发 `pai:review`。全部 tasks 完成后触发 `pai:done`。
