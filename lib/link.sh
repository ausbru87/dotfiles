# shellcheck shell=bash
# Symlinking configs into $HOME, idempotent and with backups.

# Link src to dest. An existing link is replaced; an existing file or
# directory is moved aside to dest.backup.<timestamp> first (ln -sf onto a
# real directory would otherwise create the link inside it).
safe_link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    return
  fi
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    echo "  + link $dest -> $src"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    local backup
    backup="$dest.backup.$(date +%s)"
    mv "$dest" "$backup"
    log_warning "Backed up $dest -> $backup"
  fi
  ln -s "$src" "$dest"
  log_success "Linked $dest"
}

link_home() {
  local f
  for f in .shellrc .zshrc .bashrc .gitconfig .gitignore_global .gitmessage .tmux.conf .vimrc; do
    safe_link "$DOTFILES_DIR/home/$f" "$HOME/$f"
  done

  safe_link "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
  safe_link "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
  if [[ "$OS" == darwin ]] || have ghostty; then
    safe_link "$DOTFILES_DIR/config/ghostty/config" "$HOME/.config/ghostty/config"
  fi

  if [[ -d "$HOME/.config/Code/User" ]]; then
    safe_link "$DOTFILES_DIR/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
    safe_link "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
  elif [[ -d "$HOME/Library/Application Support/Code/User" ]]; then
    safe_link "$DOTFILES_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    safe_link "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
  fi
}

# Each selected profile's mise.toml is linked into mise's global conf.d, so
# mise sees the union of their tools. Links for deselected profiles are
# removed; the tools stay installed until `mise prune`.
#   link_mise_profiles <profile>...
link_mise_profiles() {
  local confd="$HOME/.config/mise/conf.d" f p
  for f in "$confd"/dotfiles-*.toml; do
    [[ -L "$f" ]] || continue
    p=${f##*/dotfiles-}; p=${p%.toml}
    case " $* " in
      *" $p "*) ;;
      *) run rm "$f" ;;
    esac
  done
  for p in "$@"; do
    [[ -f "$DOTFILES_DIR/profiles/$p/mise.toml" ]] &&
      safe_link "$DOTFILES_DIR/profiles/$p/mise.toml" "$confd/dotfiles-$p.toml"
  done
  return 0
}
