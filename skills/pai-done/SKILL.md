---
name: pai-done
description: 归档收尾 — 全部 tasks 完成后激活。运行全量测试、冲突检测、merge specs、归档 change、更新状态、提示 git 操作。自动触发 pai:reflect。
triggers:
  - "all tasks complete"
  - "finish"
  - "done"
  - "完成"
  - "归档"
  - "收尾"
---

# Done (pai:done)

## 前序检查

在执行归档前确认：
- `ai/changes/<change-name>/tasks.md` 中所有 task 已勾选 `[x]`
- 如果有未完成的 task → 拒绝归档，返回 pai:build

## 流程

### 步骤 1: 运行全量测试

- 使用 {shell} 运行项目全量测试命令
- 如果有测试失败 → 停止归档，触发 pai:debug
- 所有测试通过后继续

### 步骤 2: 冲突检测

在归档前检查是否有其他未归档的 change 修改了相同的 spec 文件：

1. 使用 {search-glob} 扫描 `ai/changes/` 下除当前 change 和 `archive/` 外的所有文件夹
2. 对每个未归档 change，比对 `specs/` 下的文件路径
3. 如果发现相同路径 → 列出冲突的 change 名称和 spec 文件：

```
⚠️ 检测到 spec 冲突:

当前 change: <current-change>
冲突 change: <conflict-change>
冲突 spec:   <spec-file>

这两个 change 都修改了同一个 spec，自动合并可能产生冲突。
请手动解决：先归档其中一个，或手动合并 spec 后再归档。

归档被阻止，等待用户处理。
```

4. 如果无冲突 → 继续步骤 3

### 步骤 3: 合并 Delta Spec

对于 delta spec 中的每个 requirement：

- **ADDED** → 追加到 `ai/specs/<domain>/spec.md` 的 Requirements 区域
- **MODIFIED** → 替换 `ai/specs/<domain>/spec.md` 中的对应 requirement（按 requirement 标题匹配）
- **REMOVED** → 从 `ai/specs/<domain>/spec.md` 中删除对应 requirement

如果 `ai/specs/<domain>/` 不存在，创建对应目录。
如果 `ai/specs/<domain>/spec.md` 不存在，以 delta 内容创建。

### 步骤 4: 归档 Change

1. 将 `ai/changes/<change-name>/` 移动到 `ai/changes/archive/<YYYY-MM-DD>-<change-name>/`
2. 使用 {shell} 执行移动操作

### 步骤 5: 更新状态文件

**ai/state/current.md**:
- 清空当前激活的 change
- 如果 roadmap 中有下一项，更新为下一目标
- 更新 `最后更新` 时间

**ai/state/tasks.md**:
- 将完成的 tasks 移到 DONE 区域
- 如果 DONE 区域积累超过 10 项，归档到下方归档区

### 步骤 6: 提示 Git 操作

根据 `ai/config.yaml` 的 `conventions.git.commit_style` 生成 commit 建议：

```
建议的 git 操作:

# 1. 查看变更
git status
git diff

# 2. 提交（Conventional Commits 格式）
git add .
git commit -m "feat(<domain>): <change-description>"

# 3. 推送（需你手动执行）
# git push origin <branch>

以上命令仅供参考，请自行确认后执行。AI 不会自动执行 git 操作。
```

**绝对不执行 git push/merge/deploy 操作。**

### 步骤 7: 触发 pai:reflect

归档完成后自动触发 `pai:reflect` 进行自我反思。

## 错误处理

- 测试失败 → 触发 pai:debug
- Spec 冲突 → 阻止归档，等待用户
- 文件移动失败 → 报告错误，重试
- tasks.md 有未完成项 → 拒绝归档
