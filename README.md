# Dotfiles

Shell, editor, and git configuration for macOS and Linux. Works with **zsh** or **bash** — the installer detects what's available.

## Install

```bash
git clone https://github.com/ausbru87/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

The install script installs minimal dependencies, symlinks configs, and sets up plugin managers (oh-my-zsh, vim-plug, TPM).

### What Gets Installed

zsh, tmux, vim, neovim, git, curl, fzf, ripgrep, fd, jq, starship, xclip (Linux). Skip with `DOTFILES_SKIP_INSTALL=1`.

## What's Included

| Config | Description |
|--------|-------------|
| `.shellrc` | Shared config: aliases, PATH, platform detection, starship, profiles |
| `.zshrc` | Zsh-specific: oh-my-zsh, plugins, history opts — sources `.shellrc` |
| `.bashrc` | Bash-specific: history, shopt, completion — sources `.shellrc` |
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

- `~/.zshrc.local` / `~/.bashrc.local`
- `~/.gitconfig.local`
- `~/.tmux.conf.local`
- `~/.vimrc.local`
