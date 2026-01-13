#!/bin/bash
# Dotfiles installer for Coder workspaces
# This script is designed to be run via:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/install.sh | bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/YOUR_USERNAME/dotfiles.git}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Clone or update dotfiles repository
setup_dotfiles_repo() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_info "Dotfiles directory exists, pulling latest changes..."
        git -C "$DOTFILES_DIR" pull --rebase || log_warn "Failed to pull, using existing files"
    else
        log_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
}

# Create symlink with backup
create_symlink() {
    local src="$1"
    local dest="$2"
    
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        log_warn "Backing up existing $dest to ${dest}.backup"
        mv "$dest" "${dest}.backup"
    elif [[ -L "$dest" ]]; then
        rm "$dest"
    fi
    
    ln -sf "$src" "$dest"
    log_success "Linked $src -> $dest"
}

# Install dotfile symlinks
install_dotfiles() {
    log_info "Installing dotfiles..."
    
    local dotfiles=(
        ".bashrc"
        ".bash_aliases"
        ".gitconfig"
        ".vimrc"
        ".tmux.conf"
        ".inputrc"
    )
    
    for dotfile in "${dotfiles[@]}"; do
        if [[ -f "$DOTFILES_DIR/$dotfile" ]]; then
            create_symlink "$DOTFILES_DIR/$dotfile" "$HOME/$dotfile"
        fi
    done
    
    # Create .config directory if needed
    mkdir -p "$HOME/.config"
    
    # Link config directories
    if [[ -d "$DOTFILES_DIR/.config/starship" ]]; then
        mkdir -p "$HOME/.config"
        create_symlink "$DOTFILES_DIR/.config/starship" "$HOME/.config/starship"
    fi
}

# Install optional tools (if not already present)
install_tools() {
    log_info "Checking for optional tools..."
    
    # Install starship prompt if not present
    if ! command -v starship &>/dev/null; then
        log_info "Installing starship prompt..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes 2>/dev/null || log_warn "Failed to install starship"
    fi
    
    # Install fzf if not present
    if ! command -v fzf &>/dev/null; then
        if [[ -d "$HOME/.fzf" ]]; then
            log_info "fzf directory exists, skipping clone"
        else
            log_info "Installing fzf..."
            git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" 2>/dev/null || log_warn "Failed to clone fzf"
            "$HOME/.fzf/install" --all --no-update-rc 2>/dev/null || log_warn "Failed to install fzf"
        fi
    fi
}

# Configure git identity from Coder environment variables
configure_git() {
    log_info "Configuring git..."
    
    # Use Coder workspace owner info if available
    if [[ -n "${CODER_WORKSPACE_OWNER_EMAIL:-}" ]]; then
        git config --global user.email "$CODER_WORKSPACE_OWNER_EMAIL"
        log_success "Set git email to $CODER_WORKSPACE_OWNER_EMAIL"
    fi
    
    if [[ -n "${CODER_WORKSPACE_OWNER_NAME:-}" ]]; then
        git config --global user.name "$CODER_WORKSPACE_OWNER_NAME"
        log_success "Set git name to $CODER_WORKSPACE_OWNER_NAME"
    elif [[ -n "${CODER_WORKSPACE_OWNER:-}" ]]; then
        git config --global user.name "$CODER_WORKSPACE_OWNER"
        log_success "Set git name to $CODER_WORKSPACE_OWNER"
    fi
}

# Source bashrc in current shell
reload_shell() {
    log_info "Reloading shell configuration..."
    # shellcheck disable=SC1091
    source "$HOME/.bashrc" 2>/dev/null || true
}

main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   Coder Workspace Dotfiles Installer   ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    # If running from curl, we need to clone first
    # If running locally, skip the clone
    if [[ "${DOTFILES_LOCAL:-false}" != "true" ]]; then
        setup_dotfiles_repo
    fi
    
    install_dotfiles
    configure_git
    install_tools
    
    echo ""
    log_success "Dotfiles installation complete!"
    log_info "Run 'source ~/.bashrc' or start a new shell to apply changes"
    echo ""
}

main "$@"
