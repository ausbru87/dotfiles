# ~/.zshrc
# Zsh-specific configuration, then sources shared .shellrc

###############################################################################
# Find dotfiles directory (works whether symlinked or not)
###############################################################################

if [[ -L "$HOME/.zshrc" ]]; then
  DOTFILES_DIR="$(dirname "$(dirname "$(readlink -f "$HOME/.zshrc")")")"
else
  DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
fi
export DOTFILES_DIR

###############################################################################
# Oh-My-Zsh
###############################################################################

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
DISABLE_AUTO_UPDATE="true"
COMPLETION_WAITING_DOTS="true"

plugins=(
  git
  docker
  history
  zsh-autosuggestions
  zsh-syntax-highlighting
)

command -v kubectl &>/dev/null && plugins+=(kubectl)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

###############################################################################
# Zsh History
###############################################################################

HIST_STAMPS="yyyy-mm-dd"
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS SHARE_HISTORY

###############################################################################
# direnv (zsh hook)
###############################################################################

command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

###############################################################################
# Shared configuration
###############################################################################

source "$DOTFILES_DIR/core/.shellrc"
