# ~/.bashrc
# Bash-specific configuration, then sources shared .shellrc

###############################################################################
# Find dotfiles directory (works whether symlinked or not)
###############################################################################

if [ -L "$HOME/.bashrc" ]; then
  _readlink="$(readlink -f "$HOME/.bashrc" 2>/dev/null || readlink "$HOME/.bashrc")"
  DOTFILES_DIR="$(cd "$(dirname "$(dirname "$_readlink")")" && pwd)"
  unset _readlink
else
  DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
fi
export DOTFILES_DIR

###############################################################################
# Bash History
###############################################################################

HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "
shopt -s histappend

###############################################################################
# Bash Options
###############################################################################

shopt -s checkwinsize   # update LINES/COLUMNS after each command
shopt -s globstar 2>/dev/null  # ** recursive glob (bash 4+)
shopt -s cdspell        # autocorrect minor cd typos

###############################################################################
# Bash Completion
###############################################################################

if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# kubectl completion
command -v kubectl >/dev/null 2>&1 && eval "$(kubectl completion bash)"

###############################################################################
# direnv (bash hook)
###############################################################################

command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"

###############################################################################
# Shared configuration
###############################################################################

source "$DOTFILES_DIR/core/.shellrc"
