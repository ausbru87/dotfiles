# ~/.zshrc
# Multi-profile dotfiles with auto-detection
# Supports: macOS, Linux, Coder workspaces, servers

###############################################################################
# Platform Detection
###############################################################################

export DOTFILES_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"  # darwin, linux
export DOTFILES_ARCH="$(uname -m)"                              # arm64, x86_64

# Environment detection
if [[ -n "${CODER_WORKSPACE_NAME:-}" ]]; then
  export DOTFILES_ENV="coder"
elif [[ -n "$SSH_CONNECTION" ]]; then
  export DOTFILES_ENV="server"
else
  export DOTFILES_ENV="local"
fi

# Find dotfiles directory (works whether symlinked or not)
if [[ -L "$HOME/.zshrc" ]]; then
  DOTFILES_DIR="$(dirname "$(dirname "$(readlink -f "$HOME/.zshrc")")")"
else
  DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
fi
export DOTFILES_DIR

###############################################################################
# Profile Auto-Detection
###############################################################################

DOTFILES_PROFILE="${DOTFILES_PROFILE:-}"

if [[ -z "$DOTFILES_PROFILE" ]]; then
  case "${CODER_WORKSPACE_NAME:-}${PWD}" in
    *devops*|*infra*|*k8s*|*terraform*|*ansible*)
      DOTFILES_PROFILE="devops" ;;
    *java*|*spring*|*jvm*|*maven*|*gradle*)
      DOTFILES_PROFILE="java" ;;
    *ml*|*ai*|*jupyter*|*notebook*|*pytorch*|*tensorflow*)
      DOTFILES_PROFILE="ml" ;;
    *)
      DOTFILES_PROFILE="devops" ;;  # default
  esac
fi
export DOTFILES_PROFILE

###############################################################################
# Oh-My-Zsh Configuration
###############################################################################

export ZSH="$HOME/.oh-my-zsh"

# Use starship instead of a theme
ZSH_THEME=""

# oh-my-zsh settings
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
DISABLE_AUTO_UPDATE="true"  # Faster startup for Coder
COMPLETION_WAITING_DOTS="true"

# History settings
HIST_STAMPS="yyyy-mm-dd"
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS SHARE_HISTORY

# Plugins
plugins=(
  git
  docker
  fzf
  history
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Add kubectl plugin only if kubectl exists
command -v kubectl &>/dev/null && plugins+=(kubectl)

# Source oh-my-zsh (if installed)
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

###############################################################################
# Platform-Specific Configuration
###############################################################################

if [[ "$DOTFILES_OS" == "darwin" ]]; then
  # macOS: Homebrew
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  # macOS aliases
  alias ls='ls -G'
  alias clipboard='pbcopy'
  alias paste='pbpaste'

else
  # Linux
  [[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
  [[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
  [[ -d "/usr/local/bin" ]] && export PATH="/usr/local/bin:$PATH"

  alias ls='ls --color=auto'
  alias clipboard='xclip -selection clipboard'
  alias paste='xclip -selection clipboard -o'

  # Fix bat on Ubuntu/Debian
  command -v batcat &>/dev/null && ! command -v bat &>/dev/null && alias bat='batcat'
fi

###############################################################################
# Universal Aliases
###############################################################################

alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Editor
alias v='vim'
alias nv='nvim'

# Git shortcuts (supplement oh-my-zsh git plugin)
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

###############################################################################
# Tool Configuration
###############################################################################

# FZF
if command -v fzf &>/dev/null; then
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# direnv
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

###############################################################################
# Starship Prompt
###############################################################################

if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

###############################################################################
# Profile-Specific Configuration
###############################################################################

# Source profile aliases
if [[ -f "$DOTFILES_DIR/profiles/$DOTFILES_PROFILE/aliases.sh" ]]; then
  source "$DOTFILES_DIR/profiles/$DOTFILES_PROFILE/aliases.sh"
fi

###############################################################################
# Local Overrides
###############################################################################

# Machine-specific config (not tracked in git)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
