---
name: pai-review
description: 代码审查 — 每个 task 完成后自动触发。对照 spec、规则和配置进行三维审查：完整性、正确性、合规性。Critical 问题阻断继续。
triggers:
  - "task complete"
  - "after TDD cycle"
  - "code review"
  - "每个task后"
  - "审查"
---

# Review (pai:review)

## 审查范围

**只审查本次 task 涉及的变更文件。** 不检查无关文件和预先存在的问题。

## 三步审查

### 步骤 1: 完整性检查 (Completeness)

对照 `ai/changes/<change-name>/tasks.md` 和 `spec.md`：

- [ ] 当前 task 是否已完成？
- [ ] 对应的 spec requirement 是否全部实现？
- [ ] spec 中定义的 Scenario 是否都有对应测试？（检查边界情况）
- [ ] 是否有遗漏的场景？

### 步骤 2: 正确性检查 (Correctness)

- [ ] 代码逻辑是否正确实现了 spec 描述的行为？
- [ ] 错误处理是否充分？（不吞异常、有意义的错误信息）
- [ ] 边界条件是否处理？（空值、空列表、极大/极小值）
- [ ] 是否存在明显的性能问题？（N+1 查询、不必要的循环）
- [ ] 是否有安全风险？（注入、敏感信息泄露）

### 步骤 3: 合规性检查 (Compliance)

- [ ] **L1 红线**：检查是否违反 `rules/hard-rules.yaml` 和 `ai/rules/hard-rules.yaml`
- [ ] **L2 架构**：检查是否违反 `ai/rules/arch-rules.yaml`
- [ ] **L3 风格**：检查是否符合 `ai/rules/style-rules.yaml`
- [ ] **Git 规范**：如果涉及 commit，检查是否符合 `ai/rules/git-rules.yaml`
- [ ] **代码风格**：检查是否符合 `ai/config.yaml` 的 conventions.code
- [ ] **命名规范**：检查是否符合 `ai/config.yaml` 的 conventions.naming
- [ ] **测试规范**：检查是否符合 `ai/rules/test-rules.yaml`

## 审查结果分类

### Critical（阻断）
- 违反 L1 红线（BLOCK_AND_WARN）
- 违反 L2 架构中标记为 BLOCK_AND_WARN 的规则
- 违反 REVIEW_BLOCK 标记的规则（如：commit 格式错误、测试覆盖率不达标、安全事件未记录日志）
- Spec 定义的 Scenario 无测试覆盖
- 安全漏洞（SQL 注入、XSS、硬编码密钥）

**处理**：必须修复后才能继续下一个 task。

### Warning（警告）
- 违反 L2 架构中标记为 REFACTOR_SUGGESTION 的规则
- 违反 REVIEW_SUGGESTION 标记的规则（如：未使用 mock、依赖漏洞）
- 违反 L3 风格规范（STYLE / WARN）
- 违反 AUDIT_ONLY 标记的规则（如：未经过人类 Code Review 的代码）
- 代码风格与 `ai/config.yaml` 不一致
- 缺少注释

**处理**：记录但允许继续。累积 3+ Warning 时建议先修复。

### OK（通过）
- 所有检查通过

## 输出格式（ASCII 可视化）

使用以下格式展示审查结果，便于快速识别问题区域：

```
+------------------------------------------+
|  REVIEW: add-user-login — Task 1.1        |
+------------------------------------------+
| COMPLETENESS  |  spec scenarios: 3/3 ✅   |
|               |  test coverage:  1/1 ✅   |
+---------------+--------------------------+
| CORRECTNESS   |  logic: valid   ✅       |
|               |  edge cases:    2/3 ⚠️   |
|               |  security:      OK  ✅   |
+---------------+--------------------------+
| COMPLIANCE    |  L1 (red lines): 8/8 ✅  |
|               |  L2 (arch):     14/14 ✅  |
|               |  L3 (style):    15/16 ⚠️ |
|               |  git rules:      6/6  ✅  |
|               |  test rules:    10/10 ✅  |
+---------------+--------------------------+
| SUMMARY                                 |
+------------------------------------------+
|  Critical: 0  |  Warning: 1  |  Pass: 6  |
+------------------------------------------+

Result: PASS (with warnings) — continue to next task.
```

**简单版（小 task 时使用）：**
```
=== REVIEW Task 1.1 ===
Completeness:  OK      Correctness: OK
Compliance:    ⚠️ 1 warning (style S008: function >50 lines)
Critical: 0  |  Warning: 1
>> Continue to next task
```

## 完成后

- Critical = 0 → 继续 pai:build 的下一个 task
- Critical > 0 → 修复 Critical 问题，重新审查后再继续
