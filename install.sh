#!/usr/bin/env bash

###############################################################################
# Dotfiles Installation Script
# Compatible with Coder dotfiles module (https://registry.coder.com/modules/coder/dotfiles)
# Supports: macOS, Linux (apt/dnf/yum), Coder workspaces, servers
#
# Usage:
#   ./install.sh        # Interactive mode (local)
#   ./install.sh -y     # Non-interactive mode (Coder/CI)
#
# Environment variables:
#   DOTFILES_PROFILE    - Force profile (devops, java, ml)
#   DOTFILES_SKIP_TOOLS - Skip tool installation (symlinks only)
###############################################################################

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

###############################################################################
# Environment Detection
###############################################################################

detect_environment() {
  # OS
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"

  # Package manager
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

  # Coder detection
  if [[ -n "${CODER_WORKSPACE_NAME:-}" ]]; then
    DOTFILES_ENV="coder"
    NONINTERACTIVE=1
  else
    DOTFILES_ENV="local"
  fi

  # Non-interactive flag
  [[ "${1:-}" == "-y" ]] && NONINTERACTIVE=1

  log_info "Environment: $DOTFILES_ENV | OS: $OS ($ARCH) | Package manager: $PKG_MGR"
}

###############################################################################
# Tool Installation (idempotent)
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
    *)    log_warning "Cannot install $pkg - no package manager"; return 1 ;;
  esac
}

install_core_tools() {
  [[ "${DOTFILES_SKIP_TOOLS:-}" == "1" ]] && { log_info "Skipping tool installation"; return 0; }

  log_info "Installing core tools..."

  # Update package list (apt only, once)
  [[ "$PKG_MGR" == "apt" ]] && sudo apt-get update -qq

  # Essential tools
  install_if_missing zsh
  install_if_missing tmux
  install_if_missing vim
  install_if_missing fzf
  install_if_missing jq
  install_if_missing git

  # ripgrep (different package names)
  if ! command -v rg &>/dev/null; then
    case "$PKG_MGR" in
      brew) brew install ripgrep ;;
      apt)  sudo apt-get install -y ripgrep ;;
      dnf)  sudo dnf install -y ripgrep ;;
    esac
  fi

  # fd (different names on different distros)
  if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
    case "$PKG_MGR" in
      brew) brew install fd ;;
      apt)  sudo apt-get install -y fd-find ;;
      dnf)  sudo dnf install -y fd-find ;;
    esac
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

  # neovim (optional, nice to have)
  install_if_missing nvim neovim 2>/dev/null || true

  # AWS CLI
  if ! command -v aws &>/dev/null; then
    log_info "Installing AWS CLI..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install awscli
    else
      install_if_missing unzip
      curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
      unzip -q /tmp/awscliv2.zip -d /tmp
      sudo /tmp/aws/install
      rm -rf /tmp/awscliv2.zip /tmp/aws
    fi
  fi

  log_success "Core tools installed"
}

###############################################################################
# DevOps Tools Installation
###############################################################################

install_devops_tools() {
  [[ "${DOTFILES_SKIP_TOOLS:-}" == "1" ]] && { log_info "Skipping devops tools"; return 0; }

  log_info "Installing DevOps tools..."

  # System packages
  install_if_missing htop
  if [[ "$PKG_MGR" == "apt" ]]; then
    install_if_missing ifconfig net-tools
    install_if_missing dig dnsutils
  elif [[ "$PKG_MGR" == "dnf" ]] || [[ "$PKG_MGR" == "yum" ]]; then
    install_if_missing ifconfig net-tools
    install_if_missing dig bind-utils
  fi

  # kubectl
  if ! command -v kubectl &>/dev/null; then
    log_info "Installing kubectl..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install kubectl
    else
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
      rm kubectl
    fi
  fi

  # helm
  if ! command -v helm &>/dev/null; then
    log_info "Installing helm..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install helm
    else
      curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
  fi

  # k9s
  if ! command -v k9s &>/dev/null; then
    log_info "Installing k9s..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install derailed/k9s/k9s
    else
      K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
      curl -sL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" | sudo tar xz -C /usr/local/bin k9s
    fi
  fi

  # kubectx/kubens
  if ! command -v kubectx &>/dev/null; then
    log_info "Installing kubectx/kubens..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install kubectx
    else
      sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
      sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
      sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
    fi
  fi

  # terraform
  if ! command -v terraform &>/dev/null; then
    log_info "Installing terraform..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew tap hashicorp/tap
      brew install hashicorp/tap/terraform
    elif [[ "$PKG_MGR" == "apt" ]]; then
      install_if_missing gpg gnupg
      wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
      sudo apt-get update -qq && sudo apt-get install -y terraform
    else
      # dnf/yum
      sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo 2>/dev/null || true
      sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null || true
      sudo ${PKG_MGR} install -y terraform
    fi
  fi

  # terragrunt
  if ! command -v terragrunt &>/dev/null; then
    log_info "Installing terragrunt..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install terragrunt
    else
      TG_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | jq -r .tag_name)
      sudo curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/${TG_VERSION}/terragrunt_linux_amd64" -o /usr/local/bin/terragrunt
      sudo chmod +x /usr/local/bin/terragrunt
    fi
  fi

  # ansible
  if ! command -v ansible &>/dev/null; then
    log_info "Installing ansible..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install ansible
    else
      install_if_missing pip3 python3-pip
      pip3 install --user ansible
    fi
  fi

  # azure-cli
  if ! command -v az &>/dev/null; then
    log_info "Installing azure-cli..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install azure-cli
    else
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    fi
  fi

  # gcloud
  if ! command -v gcloud &>/dev/null; then
    log_info "Installing gcloud CLI..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install --cask google-cloud-sdk
    else
      curl -sS https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz | tar xz -C /tmp
      /tmp/google-cloud-sdk/install.sh --quiet --path-update=true
      rm -rf /tmp/google-cloud-sdk
    fi
  fi

  # argocd CLI
  if ! command -v argocd &>/dev/null; then
    log_info "Installing argocd CLI..."
    if [[ "$PKG_MGR" == "brew" ]]; then
      brew install argocd
    else
      ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | jq -r .tag_name)
      sudo curl -sSL -o /usr/local/bin/argocd "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
      sudo chmod +x /usr/local/bin/argocd
    fi
  fi

  log_success "DevOps tools installed"
}

###############################################################################
# Oh-My-Zsh Installation
###############################################################################

install_ohmyzsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_info "oh-my-zsh already installed"
  else
    log_info "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "oh-my-zsh installed"
  fi

  # Plugins
  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    log_info "Installing zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    log_info "Installing zsh-syntax-highlighting..."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi
}

###############################################################################
# Symlink Creation (idempotent, with backup)
###############################################################################

safe_symlink() {
  local src="$1"
  local dest="$2"

  # Create parent directory
  mkdir -p "$(dirname "$dest")"

  # Remove existing symlink
  [[ -L "$dest" ]] && rm "$dest"

  # Backup existing file
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

  log_success "Symlinks created"
}

###############################################################################
# Vim Plugin Manager
###############################################################################

install_vim_plug() {
  local vim_plug="$HOME/.vim/autoload/plug.vim"
  if [[ ! -f "$vim_plug" ]]; then
    log_info "Installing vim-plug..."
    curl -fLo "$vim_plug" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    log_success "vim-plug installed (run :PlugInstall in vim)"
  fi
}

###############################################################################
# Main
###############################################################################

main() {
  log_info "Starting dotfiles installation..."
  echo ""

  detect_environment "$@"
  echo ""

  install_core_tools
  echo ""

  install_devops_tools
  echo ""

  install_ohmyzsh
  echo ""

  create_symlinks
  echo ""

  install_vim_plug
  echo ""

  log_success "Dotfiles installation complete!"
  echo ""
  echo -e "${GREEN}Profile:${NC} ${DOTFILES_PROFILE:-devops} (auto-detected or set DOTFILES_PROFILE)"
  echo -e "${GREEN}Config:${NC}  $DOTFILES_DIR"
  echo ""
  echo "Next steps:"
  echo "  1. Restart shell or: source ~/.zshrc"
  echo "  2. Run :PlugInstall in vim for plugins"
  echo ""
}

main "$@"
