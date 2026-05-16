---
name: pai-debug
description: 系统调试 — 4 步法：复现 → 定位根因 → 修复 → 验证。修复后记录反模式。禁止盲猜修复。
triggers:
  - "bug"
  - "error"
  - "failing test"
  - "doesn't work"
  - "not working"
  - "报错"
  - "调试"
  - "debug"
  - "不对"
  - "修一下"
---

# Debug (pai:debug)

## 核心规则

<HARD-GATE>
绝对禁止"盲猜修复"——即不经过复现和定位直接修改代码。
必须先读懂错误信息、定位到具体代码行，理解原因后再动手。
</HARD-GATE>

## 四步法

每次开始调试时，首先用 ASCII 图展示调试路径：

```
+-- DEBUG: <错误简述>
|
+-- Step 1: REPRODUCE
|    +-- Run: <test command>
|    \-- Status: [PASS / FAIL repeatable]
|
+-- Step 2: LOCATE (binary search)
|    +-- Stack trace points: <file>:<line>
|    +-- Check list: variables / boundaries / race condition
|    \-- Hypothesis: <what might be wrong>
|
+-- Step 3: PROPOSE FIX
|    +-- Root cause: <found>
|    +-- Fix: <description>
|    \-- Side effects: <none / ...>
|
\-- Step 4: VERIFY
     +-- Run: <test command>
     \-- Result: [PASS / FAIL]
```

### 步骤 1: 复现问题

- 阅读完整的错误信息和堆栈跟踪
- 使用 {shell} 重新运行出错的测试或操作
- 确认错误可以稳定复现
- 记录：什么输入/操作触发了错误？

### 步骤 2: 定位根因（二分法缩小范围）

- 从堆栈顶端开始向下查找自己项目的代码
- 用二分法：假设范围 → 验证/排除 → 缩小范围
- 使用 {search-grep} 搜索相关代码
- 使用 {file-read} 读取可疑文件
- 检查：
  - 变量值是否正确？
  - 边界条件是否处理？
  - 是否有竞态条件？
  - 是否符合 `ai/rules/` 中的约束？
- **不要猜测**：每一步基于证据（日志、变量值、测试输出）

### 步骤 3: 提出修复方案

- 在动手修复前先描述：
  1. 根因是什么
  2. 修复方案是什么
  3. 为什么这个方案能解决根因
  4. 是否会影响其他功能？
- 如果可能，先让用户确认方案

### 步骤 4: 修复并验证

- 实施修复（最小改动）
- 使用 {shell} 运行相关测试确认通过
- 如果修复引入了新的测试失败 → 回到步骤 1

### 步骤 5: 记录反模式（可选，询问用户）

修复验证通过后，询问用户：

> "这次 bug 的根因是否代表一个值得记录的反模式？如果是，我建议将其添加到 `ai/memory/anti-patterns.md`。"

如果用户同意，使用 {file-read} 读 `ai/memory/anti-patterns.md`，追加新条目：

```markdown
## {date}: {简短标题}
- **现象**: {bug 的表现}
- **根因**: {为什么发生}
- **教训**: {如何避免}
```

## 常见错误模式识别

在定位时主动对照以下常见模式：
- 空值/null 未处理
- 数组/列表越界
- 异步操作顺序问题
- 环境变量/配置缺失
- 类型不匹配
- 权限/认证问题
- 并发/竞态条件
- 缓存未失效

## 完成后

修复完成后自动回到之前的技能流程（pai:build 的下一个 task，或 pai:review）。
