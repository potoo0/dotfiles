# AGENTS.md

这是个人 dotfiles 仓库，采用 chezmoi 命名：`dot_zshrc` 对应 `~/.zshrc`，`dot_config/foo` 对应 `~/.config/foo`。

## 修改原则

- 保持现有风格，避免顺手重排无关配置。
- 未被明确要求时，不要执行 chezmoi 命令。
- 重点关注 tmux / zsh 配置正确性，尤其是多层引号、tmux 格式字符串和 shell 变量求值时机。

## tmux

`dot_config/tmux/tmux.conf` 同时兼容 tmux 配置和 shell 脚本片段，部分 `# ` 注释内容会通过下面的方式执行：

```bash
cut -c3- dot_config/tmux/tmux.conf | bash -s function_name
```

- 修改内嵌 shell 函数后，运行 `cut -c3- dot_config/tmux/tmux.conf | bash -n`。
- tmux target 优先使用稳定 id，例如 `#{window_id}`、`#{pane_id}`；展示给用户时再使用 `#{session_name}:#{window_index}` 等可读格式。

## zsh

- `dot_zshrc` 依赖 zinit，验证时不要随意 source 整个文件，避免触发插件安装或改变当前 shell。
- 修改函数时优先静态检查或单独验证函数逻辑。
- WSL 相关函数如 `sync_wsl_interop`、`run_vscode_like` 涉及 Windows 可执行文件路径，改动前确认调用场景。

## 验证

按改动范围选择：

```bash
git diff --check
cut -c3- dot_config/tmux/tmux.conf | bash -n

TSOCK="tmuxtest-$$"
tmux -L "$TSOCK" -f dot_config/tmux/tmux.conf new-session -d -s "$TSOCK"
tmux -L "$TSOCK" kill-server
```

如果缺少依赖导致测试不能跑，说明具体缺失项，不要自动安装全局依赖。

## 提交消息

沿用现有风格，例如：

```text
tmux(conf): 尝试加载 tmux.local.conf; 配置 tmux-agent-indicator 样式
```
