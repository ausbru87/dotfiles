# Demo dotfiles for Coder demo-ai-gov* templates.
#
# Minimal by design — keeps the sales demo visuals clean and puts the
# AI CLIs in YOLO mode so approval prompts don't interrupt a demo.
#
# If you want the full-featured dev setup, switch the "Dotfiles Branch"
# parameter on the workspace-create form from `demo` back to `main`.

# Source the system bashrc if present (picks up Ubuntu default PS1,
# ls colors, sensible defaults) before we customize.
[ -r /etc/bash.bashrc ] && . /etc/bash.bashrc

# ---- Prompt ----------------------------------------------------------------
# Green arrow + current directory basename. Easy to read in a projected demo.
PS1='\[\033[1;32m\]\342\236\234\[\033[0m\] \[\033[1;36m\]\W\[\033[0m\] '

# ---- AI CLI aliases --------------------------------------------------------
# "Don't ask, just do it" — so the sales demo doesn't stall on approval
# prompts mid-presentation. On the firewalled template these are no-ops
# (the PATH wrappers already pass the same flags); on the no-firewall
# template they do the actual work.
alias claude='claude --dangerously-skip-permissions'
alias codex='codex --dangerously-bypass-approvals-and-sandbox'

# ---- History ---------------------------------------------------------------
HISTFILE="$HOME/.bash_history"
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
