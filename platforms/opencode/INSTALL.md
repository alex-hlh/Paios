# OpenCode 安装说明

## 前置条件

- [OpenCode.ai](https://opencode.ai) 已安装

## 安装

在项目或全局 `opencode.json` 的 `plugin` 数组中添加：

```json
{
  "plugin": ["aios@git+https://github.com/<user>/aios-skill-pack.git"]
}
```

重启 OpenCode。插件安装后自动注册所有技能。

验证：询问 AI "Tell me about your skills"

## 初始化项目

```
$ cd my-project
$ path/to/aios-skill-pack/scripts/aios init
```

完成初始化后，项目的 `ai/` 目录已被创建。下次启动 OpenCode 时，`pai:bootstrap` 会自动加载项目状态。

## 更新

```json
{
  "plugin": ["aios@git+https://github.com/<user>/aios-skill-pack.git#v1.0.0"]
}
```

锁定版本后，手动更新 tag 即可升级。

## Windows 安装

如果 OpenCode 的 git-backed 插件安装失败，使用系统 npm 安装：

```powershell
npm install aios-skill-pack@git+https://github.com/<user>/aios-skill-pack.git --prefix "$HOME\.config\opencode"
```

然后在 `opencode.json` 中：

```json
{
  "plugin": ["~/.config/opencode/node_modules/aios-skill-pack"]
}
```
