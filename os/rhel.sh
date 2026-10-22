# shellcheck shell=bash
# Fedora / RHEL / Rocky / Alma / Amazon Linux: dnf (or yum) for the base
# system. ripgrep, fd, bat, fzf etc. come from mise, so EPEL isn't needed.

RHEL_BASE=(zsh tmux vim-enhanced git curl ca-certificates unzip tar gzip xz
  gcc gcc-c++ make python3 bash-completion ncurses "util-linux-user|util-linux" xclip)

os_install() {
  can_sudo || { log_warning "No sudo: skipping dnf packages (tools still install via mise)"; return 0; }
  local mgr=dnf
  have dnf || mgr=yum

  local pkgs=() p line
  for line in "${RHEL_BASE[@]}"; do pkgs+=("$line"); done
  for p in "$@"; do
    [[ -f "$DOTFILES_DIR/profiles/$p/dnf" ]] || continue
    while read -r line; do
      [[ -z "$line" || "$line" == \#* ]] || pkgs+=("$line")
    done <"$DOTFILES_DIR/profiles/$p/dnf"
  done

  # Batch with the first of each "a|b"; on failure, go one by one and try
  # the alternatives (xclip, for one, only exists with EPEL on RHEL).
  local first=()
  for p in "${pkgs[@]}"; do first+=("${p%%|*}"); done
  log_info "$mgr install: ${first[*]}"
  as_root "$mgr" install -y -q "${first[@]}" && return 0
  log_warning "Batch install failed; retrying packages individually"
  local alt ok
  for p in "${pkgs[@]}"; do
    ok=0
    IFS='|' read -ra alts <<<"$p"
    for alt in "${alts[@]}"; do
      as_root "$mgr" install -y -q "$alt" >/dev/null 2>&1 && { ok=1; break; }
    done
    [[ "$ok" == 1 ]] || log_warning "Could not install $p"
  done
}
