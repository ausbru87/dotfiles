#!/usr/bin/env bash

###############################################################################
# Dotfiles Installation Script
# Installs minimal dependencies, symlinks configs, sets up shell/vim/tmux plugins.
#
# Usage:
#   ./install.sh        # Interactive mode
#   ./install.sh -y     # Non-interactive mode (Coder/CI)
#
# Environment variables:
#   DOTFILES_SKIP_INSTALL=1  # Skip package installs (symlinks + plugins only)
###############################################################################

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

###############################################################################
# Environment Detection
###############################################################################

detect_environment() {
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"

  if command -v brew &>/dev/null; then
    PKG_MGR="brew"
  elif command -v apt-get &>/dev/null; then
    PKG_MGR="apt"
  elif command -v dnf &>/dev/null; then
    PKG_MGR="dnf"
  elif command -v yum &>/dev/null; then
    PKG_MGR="yum"
  else
    PKG_MGR="none"
  fi

  [[ "${1:-}" == "-y" || -n "${CODER_WORKSPACE_NAME:-}" ]] && NONINTERACTIVE=1

  log_info "OS: $OS ($ARCH) | Package manager: $PKG_MGR"
}

###############################################################################
# Package Installation Helpers
###############################################################################

install_if_missing() {
  local cmd="$1"
  local pkg="${2:-$1}"

  command -v "$cmd" &>/dev/null && return 0

  log_info "Installing $pkg..."
  case "$PKG_MGR" in
    brew) brew install "$pkg" ;;
    apt)  sudo apt-get install -y "$pkg" ;;
    dnf)  sudo dnf install -y "$pkg" ;;
    yum)  sudo yum install -y "$pkg" ;;
    *)    log_warning "Cannot install $pkg — no supported package manager"; return 1 ;;
  esac
}

###############################################################################
# Minimal Tool Installation
# Only what the dotfiles configs actually depend on.
###############################################################################

install_packages() {
  if [[ "${DOTFILES_SKIP_INSTALL:-}" == "1" ]]; then
    log_info "Skipping package installs (DOTFILES_SKIP_INSTALL=1)"
    return
  fi

  log_info "Installing dependencies..."

  # Update package list (apt only, once)
  [[ "$PKG_MGR" == "apt" ]] && sudo apt-get update -qq

  # Shells & multiplexer
  install_if_missing zsh
  install_if_missing tmux

  # Editors
  install_if_missing vim
  install_if_missing nvim neovim 2>/dev/null || true

  # Git (needed by oh-my-zsh, vim-fugitive, TPM)
  install_if_missing git
  install_if_missing curl

  # Search tools (used by .shellrc, .vimrc fzf.vim :Rg, :Files)
  install_if_missing fzf
  install_if_missing rg ripgrep

  # fd (used by FZF_DEFAULT_COMMAND in .shellrc)
  if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
    case "$PKG_MGR" in
      brew) brew install fd ;;
      apt)  sudo apt-get install -y fd-find ;;
      dnf|yum) sudo "$PKG_MGR" install -y fd-find ;;
    esac
  fi

  # jq (general-purpose, tiny)
  install_if_missing jq

  # Clipboard support for tmux copy-mode on Linux
  if [[ "$OS" == "linux" ]]; then
    install_if_missing xclip 2>/dev/null || true
  fi

  # Starship prompt
  if ! command -v starship &>/dev/null; then
    log_info "Installing starship..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install starship
    else
      curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
  fi

  log_success "Dependencies installed"
}

###############################################################################
# Shell Detection
###############################################################################

detect_shell() {
  HAS_ZSH=false
  HAS_BASH=false

  command -v zsh  &>/dev/null && HAS_ZSH=true
  command -v bash &>/dev/null && HAS_BASH=true

  if $HAS_ZSH; then
    SHELL_NAME="zsh"
  else
    SHELL_NAME="bash"
  fi

  log_info "Detected shell: $SHELL_NAME (zsh=$HAS_ZSH, bash=$HAS_BASH)"
}

###############################################################################
# Oh-My-Zsh + Plugins (zsh only)
###############################################################################

install_ohmyzsh() {
  if ! $HAS_ZSH; then
    log_info "Skipping oh-my-zsh (zsh not found)"
    return
  fi

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_info "oh-my-zsh already installed"
  else
    log_info "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "oh-my-zsh installed"
  fi

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi
}

###############################################################################
# Vim-Plug
###############################################################################

install_vim_plug() {
  local vim_plug="$HOME/.vim/autoload/plug.vim"
  if [[ ! -f "$vim_plug" ]]; then
    log_info "Installing vim-plug..."
    curl -fLo "$vim_plug" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    log_success "vim-plug installed (run :PlugInstall in vim)"
  else
    log_info "vim-plug already installed"
  fi
}

###############################################################################
# TPM (Tmux Plugin Manager)
###############################################################################

install_tpm() {
  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    log_info "TPM already installed"
  else
    log_info "Installing TPM..."
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    log_success "TPM installed (prefix + I in tmux to install plugins)"
  fi
}

###############################################################################
# Symlinks (idempotent, with backup)
###############################################################################

safe_symlink() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"
  [[ -L "$dest" ]] && rm "$dest"
  [[ -f "$dest" ]] && mv "$dest" "$dest.backup.$(date +%s)"

  ln -sf "$src" "$dest"
  log_success "Linked: $dest -> $src"
}

create_symlinks() {
  log_info "Creating symlinks..."

  # Shared shell config
  safe_symlink "$DOTFILES_DIR/core/.shellrc" "$HOME/.shellrc"

  # Shell RC — symlink based on what's available
  if $HAS_ZSH; then
    safe_symlink "$DOTFILES_DIR/core/.zshrc" "$HOME/.zshrc"
  fi
  if $HAS_BASH; then
    safe_symlink "$DOTFILES_DIR/core/.bashrc" "$HOME/.bashrc"
  fi

  # Git
  safe_symlink "$DOTFILES_DIR/core/.gitconfig" "$HOME/.gitconfig"
  safe_symlink "$DOTFILES_DIR/core/.gitignore_global" "$HOME/.gitignore_global"
  safe_symlink "$DOTFILES_DIR/core/.gitmessage" "$HOME/.gitmessage"

  # Tmux
  safe_symlink "$DOTFILES_DIR/core/.tmux.conf" "$HOME/.tmux.conf"

  # Vim
  safe_symlink "$DOTFILES_DIR/core/.vimrc" "$HOME/.vimrc"

  # Neovim (use same vimrc)
  mkdir -p "$HOME/.config/nvim"
  safe_symlink "$DOTFILES_DIR/core/.vimrc" "$HOME/.config/nvim/init.vim"

  # Starship
  mkdir -p "$HOME/.config"
  safe_symlink "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

  # VS Code (if directory exists)
  if [[ -d "$HOME/.config/Code/User" ]]; then
    safe_symlink "$DOTFILES_DIR/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
    safe_symlink "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
  elif [[ -d "$HOME/Library/Application Support/Code/User" ]]; then
    safe_symlink "$DOTFILES_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    safe_symlink "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
  fi
}

###############################################################################
# Main
###############################################################################

main() {
  log_info "Installing dotfiles..."
  echo ""

  detect_environment "$@"
  echo ""

  install_packages
  echo ""

  detect_shell
  echo ""

  install_ohmyzsh
  echo ""

  install_vim_plug
  echo ""

  install_tpm
  echo ""

  create_symlinks
  echo ""

  log_success "Done! Restart your shell or: source ~/.$SHELL_NAME rc"
  echo "  - Run :PlugInstall in vim to install plugins"
  echo "  - Run prefix + I in tmux to install plugins"
  echo ""
}

main "$@"
