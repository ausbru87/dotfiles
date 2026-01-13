# ~/.bashrc - Bash configuration for Coder workspaces
# Optimized for remote development environments

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# ==============================================================================
# History Configuration
# ==============================================================================
HISTCONTROL=ignoreboth:erasedups  # Ignore duplicates and commands starting with space
HISTSIZE=10000                     # Commands to remember in session
HISTFILESIZE=20000                 # Commands to save in history file
HISTTIMEFORMAT="%F %T "           # Timestamp format
shopt -s histappend               # Append to history, don't overwrite
shopt -s cmdhist                  # Save multi-line commands as single entry

# ==============================================================================
# Shell Options
# ==============================================================================
shopt -s checkwinsize    # Update LINES and COLUMNS after each command
shopt -s globstar        # Enable ** for recursive globbing
shopt -s cdspell         # Autocorrect typos in cd commands
shopt -s dirspell        # Autocorrect directory names during completion
shopt -s autocd          # Type directory name to cd into it
shopt -s nocaseglob      # Case-insensitive globbing

# ==============================================================================
# Environment Variables
# ==============================================================================
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="-R -F -X"  # Raw control chars, quit if one screen, don't clear

# Colored man pages
export LESS_TERMCAP_mb=$'\e[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\e[0m'        # end mode
export LESS_TERMCAP_se=$'\e[0m'        # end standout
export LESS_TERMCAP_so=$'\e[01;44;33m' # begin standout
export LESS_TERMCAP_ue=$'\e[0m'        # end underline
export LESS_TERMCAP_us=$'\e[1;32m'     # begin underline

# XDG Base Directory
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# ==============================================================================
# Path Configuration
# ==============================================================================
# Add local bin directories to PATH
for dir in "$HOME/.local/bin" "$HOME/bin" "$HOME/go/bin" "$HOME/.cargo/bin"; do
    [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]] && PATH="$dir:$PATH"
done
export PATH

# ==============================================================================
# Prompt Configuration
# ==============================================================================
# Use starship if available, otherwise use a nice default prompt
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
else
    # Git branch in prompt
    parse_git_branch() {
        git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
    }
    
    # Colors
    RESET="\[\033[0m\]"
    BLUE="\[\033[0;34m\]"
    GREEN="\[\033[0;32m\]"
    CYAN="\[\033[0;36m\]"
    YELLOW="\[\033[0;33m\]"
    
    # Coder workspace indicator
    if [[ -n "${CODER_WORKSPACE_NAME:-}" ]]; then
        CODER_INDICATOR="${CYAN}[coder:${CODER_WORKSPACE_NAME}]${RESET} "
    else
        CODER_INDICATOR=""
    fi
    
    PS1="${CODER_INDICATOR}${GREEN}\u${RESET}@${BLUE}\h${RESET}:${YELLOW}\w${CYAN}\$(parse_git_branch)${RESET}\$ "
fi

# ==============================================================================
# Aliases
# ==============================================================================
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Listing (use exa/eza if available)
if command -v eza &>/dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -la --group-directories-first --git'
    alias la='eza -a --group-directories-first'
    alias lt='eza --tree --level=2'
elif command -v exa &>/dev/null; then
    alias ls='exa --group-directories-first'
    alias ll='exa -la --group-directories-first --git'
    alias la='exa -a --group-directories-first'
    alias lt='exa --tree --level=2'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah'
    alias la='ls -A'
fi

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline -20'
alias glog='git log --graph --oneline --decorate --all'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -pv'

# Grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# System
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='htop 2>/dev/null || top'

# Quick edits
alias bashrc='${EDITOR} ~/.bashrc && source ~/.bashrc'
alias vimrc='${EDITOR} ~/.vimrc'

# Networking
alias myip='curl -s ifconfig.me'
alias ports='netstat -tulanp 2>/dev/null || ss -tulanp'

# Docker shortcuts (if available)
if command -v docker &>/dev/null; then
    alias d='docker'
    alias dc='docker compose'
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dlog='docker logs -f'
fi

# Kubernetes shortcuts (if available)
if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get svc'
    alias kgd='kubectl get deployments'
    alias kga='kubectl get all'
    alias kdp='kubectl describe pod'
    alias kl='kubectl logs -f'
    alias kex='kubectl exec -it'
fi

# ==============================================================================
# Functions
# ==============================================================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.tar.xz)    tar xJf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find file by name
ff() {
    find . -type f -iname "*$1*" 2>/dev/null
}

# Find directory by name
fd() {
    find . -type d -iname "*$1*" 2>/dev/null
}

# Search for text in files
search() {
    grep -rn "$1" "${2:-.}" 2>/dev/null
}

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    echo "Serving at http://localhost:$port"
    python3 -m http.server "$port" 2>/dev/null || python -m SimpleHTTPServer "$port"
}

# JSON pretty print
json() {
    if [[ -t 0 ]]; then
        python3 -m json.tool "$@"
    else
        python3 -m json.tool
    fi
}

# Backup a file with timestamp
backup() {
    cp "$1" "${1}.backup.$(date +%Y%m%d_%H%M%S)"
}

# Show top disk usage
ducks() {
    du -cksh "${1:-.}"/* 2>/dev/null | sort -rh | head -20
}

# ==============================================================================
# Coder-specific Configuration
# ==============================================================================

# Display Coder workspace info on login
if [[ -n "${CODER_WORKSPACE_NAME:-}" ]]; then
    echo ""
    echo "🚀 Coder Workspace: ${CODER_WORKSPACE_NAME}"
    [[ -n "${CODER_WORKSPACE_TEMPLATE_NAME:-}" ]] && echo "📦 Template: ${CODER_WORKSPACE_TEMPLATE_NAME}"
    [[ -n "${CODER_URL:-}" ]] && echo "🔗 URL: ${CODER_URL}"
    echo ""
fi

# ==============================================================================
# External Tool Integration
# ==============================================================================

# FZF configuration
if [[ -f ~/.fzf.bash ]]; then
    source ~/.fzf.bash
fi

# FZF default options
export FZF_DEFAULT_OPTS='
    --height 40%
    --layout=reverse
    --border
    --info=inline
    --preview-window=right:50%:wrap
'

# Use fd for FZF if available
if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# Pyenv
if [[ -d "$HOME/.pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null
fi

# Go
export GOPATH="${GOPATH:-$HOME/go}"
export GOBIN="$GOPATH/bin"

# Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ==============================================================================
# Completion
# ==============================================================================

# Enable programmable completion
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        source /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        source /etc/bash_completion
    fi
fi

# kubectl completion
if command -v kubectl &>/dev/null; then
    source <(kubectl completion bash 2>/dev/null)
    complete -o default -F __start_kubectl k
fi

# ==============================================================================
# Terraform/IaC Configuration
# ==============================================================================
# Source terraform/cloud CLI configuration
[[ -f ~/.bash_terraform ]] && source ~/.bash_terraform

# ==============================================================================
# Local Overrides
# ==============================================================================
# Source local bashrc if it exists (for machine-specific settings)
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
