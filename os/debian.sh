# shellcheck shell=bash
# Debian/Ubuntu: apt for the base system and the libraries some profiles
# need. CLI tools come from mise, so the distro's version (Ubuntu 22.04
# ships neovim 0.6) and naming quirks (yq is a different tool, bat is
# batcat) don't matter here.

DEBIAN_BASE=(zsh tmux vim git curl ca-certificates unzip tar gzip xz-utils
  build-essential python3 bash-completion locales ncurses-term xclip)

APT=(env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300)

apt_update() {
  # Many base images (e.g. Coder's enterprise-base) ship with empty
  # /var/lib/apt/lists, so this must succeed before anything can install.
  log_info "Updating apt package lists..."
  as_root "${APT[@]}" update -qq && return 0
  # A stale third-party repo key (NO_PUBKEY) fails the whole update. apt-key
  # is gone from current Debian, so name the repo rather than guess a fix.
  log_warning "apt-get update failed, often a third-party repo with an expired key"
  log_warning "under /etc/apt/sources.list.d/. Continuing with existing lists."
}

# "a|b" means a if the archive has it, else b (libasound2t64 on Ubuntu
# 24.04+, libasound2 before).
apt_pick() {
  local alt
  IFS='|' read -ra alts <<<"$1"
  for alt in "${alts[@]}"; do
    apt-cache show "$alt" >/dev/null 2>&1 && { echo "$alt"; return; }
  done
  echo "${alts[0]}"
}

os_install() {
  can_sudo || { log_warning "No sudo: skipping apt packages (tools still install via mise)"; return 0; }
  apt_update

  local pkgs=() p line
  for line in "${DEBIAN_BASE[@]}"; do pkgs+=("$line"); done
  for p in "$@"; do
    [[ -f "$DOTFILES_DIR/profiles/$p/apt" ]] || continue
    while read -r line; do
      [[ -z "$line" || "$line" == \#* ]] || pkgs+=("$(apt_pick "$line")")
    done <"$DOTFILES_DIR/profiles/$p/apt"
  done

  log_info "apt install: ${pkgs[*]}"
  as_root "${APT[@]}" install -y -qq "${pkgs[@]}" && return 0
  # One missing package fails the batch; retry one by one so the rest land.
  log_warning "Batch install failed; retrying packages individually"
  for p in "${pkgs[@]}"; do
    as_root "${APT[@]}" install -y -qq "$p" >/dev/null 2>&1 || log_warning "Could not install $p"
  done
}
