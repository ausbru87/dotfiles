# Dotfiles

Multi-profile dotfiles for macOS, Linux, and Coder workspaces.

## Quick Start

```bash
# Clone and install
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

## Coder Workspaces

Works with the [Coder dotfiles module](https://registry.coder.com/modules/coder/dotfiles):

```hcl
module "dotfiles" {
  source   = "registry.coder.com/modules/dotfiles/coder"
  agent_id = coder_agent.main.id
}
```

## Profiles

Auto-detected from workspace name or set via `DOTFILES_PROFILE`:

| Profile | Trigger patterns | Tools |
|---------|-----------------|-------|
| **devops** (default) | `*devops*`, `*infra*`, `*k8s*` | kubectl, helm, terraform, oc |
| **java** | `*java*`, `*spring*`, `*jvm*` | maven, gradle, SDKMAN |
| **ml** | `*ml*`, `*ai*`, `*jupyter*` | conda, pip, jupyter |

Override: `export DOTFILES_PROFILE=java`

## Structure

```
dotfiles/
├── install.sh          # Main installer (Coder-compatible)
├── core/               # Shared configs
│   ├── .zshrc          # Shell with auto-detection
│   ├── .gitconfig
│   ├── .tmux.conf
│   └── .vimrc
├── profiles/           # Profile-specific aliases
│   ├── devops/
│   ├── java/
│   └── ml/
├── starship/           # Prompt config
└── vscode/             # Editor settings
```

## Features

- **Cross-platform**: macOS + Linux (apt/dnf/yum)
- **Auto-detection**: OS, arch, Coder workspace, SSH server
- **Idempotent**: Safe to re-run
- **Fast**: Skips already-installed tools
- **Non-interactive**: `-y` flag or auto-detect Coder

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DOTFILES_PROFILE` | Force profile (devops, java, ml) |
| `DOTFILES_SKIP_TOOLS` | Skip tool installation (1 = skip) |

## Core Tools Installed

zsh, tmux, vim, neovim, fzf, ripgrep, fd, jq, starship, oh-my-zsh

## Local Overrides

Create these files for machine-specific config (not tracked):
- `~/.zshrc.local`
- `~/.gitconfig.local`
- `~/.tmux.conf.local`
- `~/.vimrc.local`
