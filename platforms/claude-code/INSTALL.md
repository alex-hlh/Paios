# Claude Code 安装说明

## 前置条件

- Claude Code 已安装

## 安装

### 方式 1：通过 AIOS 市场

```bash
/plugin marketplace add <user>/aios-marketplace
/plugin install aios@aios-marketplace
```

重启 Claude Code。

### 方式 2：手动安装

将仓库克隆到 `~/.claude/plugins/`：

```bash
git clone https://github.com/<user>/aios-skill-pack.git ~/.claude/plugins/aios
```

在项目的 `CLAUDE.md` 或全局 CLAUDE.md 中添加：

```markdown
@~/.claude/plugins/aios/skills/pai-bootstrap/SKILL.md
```

## 验证

重启后询问 Claude："Tell me about your skills"

## 初始化项目

```
$ cd my-project
$ bash path/to/aios-skill-pack/scripts/aios.sh init
```

## 更新

安装后 Claude Code 会自动拉取最新版本。如需锁版本：

```bash
git -C ~/.claude/plugins/aios checkout v1.0.0
```
