# shellcheck shell=bash
# Profile discovery, dependency resolution, presets, and the picker.
#
# A profile is a directory under profiles/ with any of:
#   description     one line shown in the picker and --list
#   requires        profiles this one needs (space-separated)
#   os              platforms it supports (e.g. "linux"); absent = all
#   mise.toml       CLI tools, installed by mise on every OS
#   Brewfile        macOS-only extras (casks, fonts, system libs)
#   apt, dnf        Linux system packages, one per line ("a|b" = a, else b)
#   post-install.sh run after tools are installed
#   aliases.sh      sourced by .shellrc when the profile is active
# LazyVim extras for a profile live in config/nvim/lua/profiles/<name>.lua.

PROFILE_STATE="$HOME/.config/dotfiles/profiles"

preset_profiles() {
  case "$1" in
    workstation) echo "k8s iac cloud-aws aws-dev arch ai" ;;
    server)      echo "" ;;
    k8s-node)    echo "k8s k8s-node" ;;
    *) return 1 ;;
  esac
}

all_profiles() {
  local d
  for d in "$DOTFILES_DIR"/profiles/*/; do
    d=${d%/}; d=${d##*/}
    [[ "$d" == base ]] || echo "$d"
  done
}

profile_exists() { [[ -d "$DOTFILES_DIR/profiles/$1" ]]; }

profile_description() {
  local f="$DOTFILES_DIR/profiles/$1/description"
  [[ -f "$f" ]] && head -1 "$f"
}

profile_supported() {
  local f="$DOTFILES_DIR/profiles/$1/os"
  [[ ! -f "$f" ]] || grep -qw "$OS" "$f"
}

# Expand "requires" depth-first so dependencies come before dependents,
# drop duplicates and unsupported profiles, and always start with base.
resolve_profiles() {
  RESOLVED=()
  _resolve_one base
  local p
  for p in "$@"; do
    [[ "$p" == devops ]] && { _resolve_one k8s; _resolve_one iac; continue; }
    _resolve_one "$p"
  done
}

_resolve_one() {
  local p="$1" r
  case " ${RESOLVED[*]} " in *" $p "*) return ;; esac
  if ! profile_exists "$p"; then
    log_warning "Unknown profile '$p' (see --list); skipping"
    return
  fi
  if ! profile_supported "$p"; then
    log_warning "Profile '$p' is not supported on $OS; skipping"
    return
  fi
  if [[ -f "$DOTFILES_DIR/profiles/$p/requires" ]]; then
    for r in $(cat "$DOTFILES_DIR/profiles/$p/requires"); do
      _resolve_one "$r"
    done
  fi
  RESOLVED+=("$p")
}

saved_profiles() {
  [[ -f "$PROFILE_STATE" ]] && cat "$PROFILE_STATE"
}

save_profiles() {
  # base is implicit; store only the chosen extras
  local list=() p
  for p in "${RESOLVED[@]}"; do [[ "$p" == base ]] || list+=("$p"); done
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    echo "  + save profiles: ${list[*]:-(base only)} -> $PROFILE_STATE"
    return
  fi
  mkdir -p "$(dirname "$PROFILE_STATE")"
  echo "${list[*]}" >"$PROFILE_STATE"
}

list_profiles() {
  local p
  printf '  %-12s %s\n' base "$(profile_description base)"
  for p in $(all_profiles); do
    local note=""
    profile_supported "$p" || note=" (not on $OS)"
    printf '  %-12s %s%s\n' "$p" "$(profile_description "$p")" "$note"
  done
  echo
  echo "Presets:"
  for p in workstation server k8s-node; do
    local members; members="$(preset_profiles "$p")"
    printf '  %-12s %s\n' "$p" "${members:-(base only)}"
  done
}

# Interactive multi-select. Prints the chosen names on stdout.
pick_profiles() {
  local current="$1" choices=() p
  for p in $(all_profiles); do
    profile_supported "$p" && choices+=("$p")
  done

  if have fzf; then
    local picked
    picked=$(for p in "${choices[@]}"; do printf '%-12s %s\n' "$p" "$(profile_description "$p")"; done |
      fzf --multi --height=~20 --reverse --prompt='profiles> ' \
        --header="TAB to select, ENTER to confirm, ESC to keep current: ${current:-base only}" |
      awk '{print $1}' | tr '\n' ' ')
    echo "${picked:-$current}"
    return
  fi

  {
    echo
    echo "Choose profiles (base is always installed):"
    local i=1
    for p in "${choices[@]}"; do
      printf '  %2d) %-12s %s\n' "$i" "$p" "$(profile_description "$p")"
      i=$((i + 1))
    done
    echo "Presets: workstation, server, k8s-node"
    printf 'Numbers, names or a preset, space-separated [%s]: ' "${current:-base only}"
  } >&2
  local answer out=() extra=() w
  read -r answer </dev/tty || answer=""
  [[ -z "$answer" ]] && { echo "$current"; return; }
  for w in $answer; do
    if [[ "$w" =~ ^[0-9]+$ ]] && ((w >= 1 && w <= ${#choices[@]})); then
      out+=("${choices[w - 1]}")
    elif preset_profiles "$w" >/dev/null; then
      read -ra extra <<<"$(preset_profiles "$w")"
      out+=("${extra[@]}")
    else
      out+=("$w")
    fi
  done
  echo "${out[*]}"
}
