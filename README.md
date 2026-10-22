# Dotfiles

Shell, tmux, Neovim (LazyVim) and per-role toolsets for **macOS**, **Debian/Ubuntu** and **Fedora/RHEL**. Pick the profiles a machine needs; the same command sets up a laptop, a Linux server or a no-sudo container.

## Install

```bash
git clone https://github.com/ausbru87/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh                 # pick profiles interactively
```

```bash
./install.sh --preset workstation      # everything below
./install.sh --profiles k8s,iac,ai     # just these (base is always included)
./install.sh -y                        # no prompts: reuse the saved selection
./install.sh --dry-run --profiles aws-dev
./install.sh --list
```

The selection is saved to `~/.config/dotfiles/profiles`. Re-run with different profiles any time. Deselected tools stay installed until `mise prune`.

| Option | |
|---|---|
| `--profiles a,b` | Profiles to install (replaces the saved selection) |
| `--preset NAME` | `workstation`, `server` (base only), `k8s-node` |
| `-y` | Never prompt (implied in Coder workspaces) |
| `--dry-run` | Print what would happen |
| `--link-only` | Only link configs (also `DOTFILES_SKIP_INSTALL=1`) |
| `--no-sudo` | Skip system packages (auto-detected when sudo isn't usable) |

Set `GITHUB_TOKEN` (or be logged in with `gh`) on fresh machines: mise looks up `latest` versions through the GitHub API, which allows 60 anonymous requests an hour.

## Profiles

| Profile | Installs | LazyVim extras |
|---|---|---|
| **base** | zsh + oh-my-zsh, tmux + TPM, neovim, node LTS, uv, starship, fzf, ripgrep, fd, eza, bat, zoxide, atuin, delta, jq, yq, direnv, lazygit, gh. macOS: Ghostty, JetBrains Mono Nerd Font | json, yaml, toml, markdown |
| **k8s** | kubectl, helm, k9s, kubectx/kubens, kustomize, kind, stern, krew, kubeconform. macOS: colima + docker CLI | helm, docker |
| **k8s-node** | kubeadm (Linux only) | |
| **iac** | terraform, tflint, terraform-docs, ansible, ansible-lint, argocd, sops, age, pre-commit, trivy | terraform, ansible |
| **cloud-aws** | aws cli v2, session-manager-plugin, granted | |
| **aws-dev** | python 3.12, aws-cdk, typescript, cfn-lint (+ cloud-aws) | typescript, python |
| **arch** | mermaid-cli, d2, graphviz, draw.io (macOS) | |
| **ai** | Claude Code (native installer), opencode | claudecode |
| **java**, **ml** | Aliases only | |

## How it works

- **CLI tools come from [mise](https://mise.jdx.dev)**, as prebuilt binaries in `~/.local/share/mise`. Every OS gets the same versions with no sudo, and distro quirks don't matter (Ubuntu 22.04's neovim 0.6, apt's different `yq`, RHEL needing EPEL). Each profile's `mise.toml` is linked into `~/.config/mise/conf.d/`. Run `mise upgrade` to update, or pin versions in the profile files.
- **System packages** (`os/`) cover only what mise can't: zsh, tmux, git, compilers, Chromium libraries for mermaid-cli, and macOS casks and fonts.
- **Shell aliases** (`profiles/<name>/aliases.sh`) and **LazyVim extras** (`config/nvim/lua/profiles/<name>.lua`) load for the saved profiles. `DOTFILES_PROFILES="k8s iac"` overrides them for one shell or a Coder template.

```
install.sh              entry point
lib/                    installer internals
os/                     macos.sh, debian.sh, rhel.sh
home/                   linked into ~ (.zshrc, .shellrc, .tmux.conf, .gitconfig, …)
config/                 linked into ~/.config (nvim, starship.toml, ghostty)
profiles/<name>/        description, requires, os, mise.toml, Brewfile, apt, dnf,
                        post-install.sh, aliases.sh
tests/container.sh      installer test in Ubuntu/Debian/Fedora/Rocky containers
```

### Adding a profile

Create `profiles/<name>/` with a one-line `description` and any of: `mise.toml` (tools; `mise registry` lists names), `requires` (other profiles), `os` (`linux` or `darwin`), `Brewfile`, `apt`/`dnf` (one package per line, `a|b` for a fallback name), `post-install.sh`, `aliases.sh`. For editor support, add `config/nvim/lua/profiles/<name>.lua`.

## Neovim: Markdown and Mermaid

| Keys | What |
|---|---|
| (automatic) | Diagrams render inline in Ghostty / Kitty / WezTerm, including inside tmux |
| `space m d` | Open the diagram under the cursor (or all diagrams) in a browser |
| `space c p` | Live preview of the whole Markdown file |

Over SSH there's no local browser, so previews are served over HTTP and the URL is shown (and copied) instead: `space m d` on port 8765, `space c p` on port 8766. The servers listen on all interfaces, so use a trusted network or Tailscale. Override with `NVIM_PREVIEW_HOST` (host in the URL) and `NVIM_PREVIEW_BIND` (listen address).

## Local overrides

Machine-specific config, not tracked:

- `~/.zshrc.local` / `~/.bashrc.local`
- `~/.gitconfig.local`: identity, credential helper (the installer sets one per OS)
- `~/.tmux.conf.local`, `~/.vimrc.local`

## Testing

```bash
tests/container.sh                       # all distros, workstation profiles
tests/container.sh fedora:41 k8s,iac     # one distro, chosen profiles
```
