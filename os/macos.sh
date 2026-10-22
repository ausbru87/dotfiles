# shellcheck shell=bash
# macOS: Homebrew for the few things mise doesn't cover (casks, fonts,
# system libraries). Each profile's Brewfile is applied with brew bundle.

os_install() {
  if ! have brew; then
    log_info "Installing Homebrew..."
    run env NONINTERACTIVE="${NONINTERACTIVE:-0}" /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
  fi
  have brew || { log_warning "Homebrew unavailable; skipping system packages"; return 0; }

  local p f
  for p in "$@"; do
    f="$DOTFILES_DIR/profiles/$p/Brewfile"
    [[ -f "$f" ]] || continue
    log_info "brew bundle ($p)"
    run brew bundle --file="$f" || log_warning "brew bundle for $p had failures (continuing)"
  done
}
