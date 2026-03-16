# Dotfiles

Shell, editor, and git configuration for macOS and Linux.

## Install

```bash
git clone git@gitlab.zambruhni.com:lab/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

The install script symlinks configs and sets up oh-my-zsh + vim-plug. It does **not** install tools — manage those with your package manager.

## What's Included

| Config | Description |
|--------|-------------|
| `.zshrc` | Zsh with oh-my-zsh, starship prompt, fzf, profile aliases |
| `.vimrc` | Vim/Neovim with vim-plug, fzf, NERDTree, ALE, gruvbox |
| `.tmux.conf` | Tmux with C-a prefix, vi keys, mouse, status bar |
| `.gitconfig` | Git aliases, merge/rebase settings, global ignore |
| `starship.toml` | Starship prompt with git, k8s, directory info |
| `vscode/` | VS Code settings and keybindings |

## Profile Aliases

Set `DOTFILES_PROFILE` or let it auto-detect from workspace/directory name:

- **devops** (default) — kubectl, helm, terraform shortcuts
- **java** — maven, gradle, Spring Boot shortcuts
- **ml** — conda, pip, jupyter, pytorch shortcuts

## Local Overrides

Machine-specific config (not tracked in git):

- `~/.zshrc.local`
- `~/.gitconfig.local`
- `~/.tmux.conf.local`
- `~/.vimrc.local`
