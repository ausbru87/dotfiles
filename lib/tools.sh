# shellcheck shell=bash
# Everything that installs into $HOME (no sudo): mise and its tools, shell
# and editor plugin managers, the neovim plugin bootstrap.

export MISE_DATA_DIR="${MISE_DATA_DIR:-$HOME/.local/share/mise}"

install_mise() {
  export PATH="$MISE_DATA_DIR/shims:$HOME/.local/bin:$PATH"
  have mise && return 0
  log_info "Installing mise..."
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    echo "  + curl https://mise.run | sh"
    return 0
  fi
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh
}

# Base first: pypi: tools need uv and npm: tools need node, both from base.
install_profile_tools() {
  have mise || { [[ "${DRY_RUN:-0}" == 1 ]] || { log_warning "mise not available; skipping CLI tools"; return 0; }; }
  export MISE_YES=1
  # mise resolves "latest" through the GitHub API, which allows only 60
  # unauthenticated requests an hour -- a full install can exceed that.
  if [[ -z "${GITHUB_TOKEN:-}${MISE_GITHUB_TOKEN:-}" ]] && have gh && gh auth token >/dev/null 2>&1; then
    GITHUB_TOKEN="$(gh auth token)"
    export GITHUB_TOKEN
  fi

  link_mise_profiles base
  log_info "mise install (base)"
  (cd "$HOME" && run mise install) || log_warning "Some base tools failed to install (continuing)"

  link_mise_profiles "${RESOLVED[@]}"
  if [[ "${#RESOLVED[@]}" -gt 1 ]]; then
    log_info "mise install (${RESOLVED[*]:1})"
    (cd "$HOME" && run mise install) || log_warning "Some profile tools failed to install (continuing)"
  fi
  run mise reshim
}

run_post_installs() {
  local p f
  for p in "${RESOLVED[@]}"; do
    f="$DOTFILES_DIR/profiles/$p/post-install.sh"
    [[ -f "$f" ]] || continue
    log_info "post-install ($p)"
    run bash "$f" || log_warning "post-install for $p failed (continuing)"
  done
}

install_ohmyzsh() {
  have zsh || { log_info "Skipping oh-my-zsh (zsh not found)"; return 0; }
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing oh-my-zsh..."
    if [[ "${DRY_RUN:-0}" == 1 ]]; then
      echo "  + oh-my-zsh install.sh --unattended"
    else
      RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
  fi
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [[ -d "$custom/plugins/zsh-autosuggestions" ]] ||
    run git clone -q --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
  [[ -d "$custom/plugins/zsh-syntax-highlighting" ]] ||
    run git clone -q --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom/plugins/zsh-syntax-highlighting"
  return 0
}

install_tpm() {
  [[ -d "$HOME/.tmux/plugins/tpm" ]] && return 0
  log_info "Installing TPM..."
  run git clone -q --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  # Install the plugins now instead of waiting for prefix + I
  [[ "${DRY_RUN:-0}" == 1 ]] || "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true
}

# Plain vim (the .vimrc) is kept for minimal hosts; nvim uses LazyVim.
install_vim_plug() {
  local plug="$HOME/.vim/autoload/plug.vim"
  [[ -f "$plug" ]] && return 0
  run curl -fsSLo "$plug" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

bootstrap_nvim() {
  have nvim || { [[ "${DRY_RUN:-0}" == 1 ]] || { log_warning "nvim not found; skipping plugin install"; return 0; }; }
  log_info "Installing Neovim plugins, LSPs and parsers (first run takes a few minutes)"
  run nvim --headless "+Lazy! restore" +qa
  run nvim --headless "+luafile $DOTFILES_DIR/lib/nvim-bootstrap.lua"
  echo
}

set_default_shell() {
  have zsh || return 0
  local zsh_path
  zsh_path="$(command -v zsh)"
  [[ "${SHELL:-}" == "$zsh_path" || "${SHELL:-}" == */zsh ]] && return 0
  if ! can_sudo; then
    log_warning "No sudo: can't chsh to zsh. Add 'exec zsh' to ~/.bashrc.local if wanted."
    return 0
  fi
  grep -qx "$zsh_path" /etc/shells 2>/dev/null || echo "$zsh_path" | as_root tee -a /etc/shells >/dev/null
  as_root chsh -s "$zsh_path" "$(whoami)" || log_warning "chsh failed; login shell unchanged"
}

# The shared .gitconfig leaves the credential helper out because the right
# one differs per OS. Set it in ~/.gitconfig.local unless one is configured.
configure_git_local() {
  git config --file "$HOME/.gitconfig.local" credential.helper >/dev/null 2>&1 && return 0
  if [[ "$OS" == darwin ]]; then
    run git config --file "$HOME/.gitconfig.local" credential.helper osxkeychain
  else
    run git config --file "$HOME/.gitconfig.local" credential.helper "cache --timeout=3600"
  fi
  if ! git config user.email >/dev/null 2>&1; then
    log_warning "No git identity. Set it with:"
    log_warning "  git config --file ~/.gitconfig.local user.name  \"Your Name\""
    log_warning "  git config --file ~/.gitconfig.local user.email \"you@example.com\""
  fi
}
