# 技能链端到端测试

## 测试目的
验证从需求到归档的完整技能链流程。

## 测试环境
- 平台: {OpenCode / Claude Code}
- 版本:
- 日期:

## 测试场景：实现一个计数器功能

### 前提
项目已通过 `aios init --defaults` 初始化。

### 测试步骤

1. 用户：帮我做一个计数器，支持加减操作

   **期望：** pai:bootstrap → pai:design
   - [ ] AI 开始一问一答澄清需求
   - [ ] AI 提出 2-3 个设计方案
   - [ ] 分节展示设计并逐一确认
   - [ ] 写入 `ai/changes/add-counter/proposal.md` + `design.md`

2. 用户：确认设计，生成 spec

   **期望：** pai:spec
   - [ ] 生成 delta spec（ADDED Requirements）
   - [ ] 使用 Given/When/Then 场景格式
   - [ ] 生成 `tasks.md`（task 粒度 2-5 分钟）
   - [ ] 写入时间戳

3. 用户：开始实现

   **期望：** pai:build
   - [ ] 每次只做一个 task
   - [ ] 先写测试，确认红灯
   - [ ] 写最小实现，确认绿灯
   - [ ] 重构后勾选 task
   - [ ] 下一个 task 前触发 pai:review

4. 模拟报错：计数超过 999 时出现 bug

   **期望：** pai:debug
   - [ ] 先复现问题
   - [ ] 定位根因（不是盲猜）
   - [ ] 提出修复方案
   - [ ] 修复后运行测试验证
   - [ ] 询问是否记录反模式

5. 全部 tasks 完成

   **期望：** pai:done → pai:reflect
   - [ ] 运行全量测试
   - [ ] 冲突检测
   - [ ] merge delta 到主 spec
   - [ ] 归档到 archive/
   - [ ] 更新 state/current.md
   - [ ] 提示 git commit 命令（格式符合 conventional commits）
   - [ ] 触发 pai:reflect 自我反思

## 测试结果

| 步骤 | 结果 | 备注 |
|------|------|------|
| 1. design | ⬜ | |
| 2. spec | ⬜ | |
| 3. build (TDD) | ⬜ | |
| 4. debug | ⬜ | |
| 5. done + reflect | ⬜ | |
