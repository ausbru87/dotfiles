#!/usr/bin/env bash

###############################################################################
# Dotfiles Installation Script
# Symlinks configs and sets up oh-my-zsh + vim-plug.
# Does NOT install tools — manage those with your package manager.
#
# Usage:
#   ./install.sh        # Interactive mode
#   ./install.sh -y     # Non-interactive mode (Coder/CI)
###############################################################################

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

###############################################################################
# Oh-My-Zsh + Plugins
###############################################################################

install_ohmyzsh() {
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

  # Shell
  safe_symlink "$DOTFILES_DIR/core/.zshrc" "$HOME/.zshrc"

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

  install_ohmyzsh
  echo ""

  install_vim_plug
  echo ""

  create_symlinks
  echo ""

  log_success "Done! Restart your shell or: source ~/.zshrc"
  echo "  Run :PlugInstall in vim to install plugins."
  echo ""
}

main "$@"
