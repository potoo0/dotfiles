chezmoi 只能管理用户家目录下的, 其会复制一份到 *source-path* (默认为 `~/.local/share/chezmoi`), 称之为 working copy.

## 日常命令

```bash
# 从已有仓库初始化, 以下命令会以 https 从 github 仓库 user/dotfiles 拉取
chezmoi init user

# git 拉取更新
chezmoi git pull -- --autostash --rebase && chezmoi diff

# 查看 working copy 与 home 下的差异
chezmoi diff
chezmoi apply --verbose --dry-run

# home 的改动提交到 working copy, re-add 不加参数则会提交所有变更
chezmoi re-add

# git 提交, 如果 git 命令不带参数则可以省略 --
chezmoi git -- commit -m "Update dotfiles"
chezmoi git push

# 与 outside_root 的之间的同步 (outside_root 是指以根目录起始的), 不支持删除
chezmoi cd
# 同步所有到 /
sudo rsync -avh outside_root/ / --dry-run
# 同步某个文件到 outside_root
rsync -avh /etc/tmux.conf outside_root/etc/ --dry-run
rsync -avh /etc/lf/ outside_root/etc/lf --dry-run
```
