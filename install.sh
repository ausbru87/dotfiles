#!/usr/bin/env bash
###############################################################################
# Dotfiles installer: shell, tmux, LazyVim, and per-profile toolsets on
# macOS, Debian/Ubuntu and Fedora/RHEL. Safe to re-run.
#
# Usage:
#   ./install.sh                         # pick profiles interactively
#   ./install.sh --profiles k8s,iac,ai   # or name them
#   ./install.sh --preset workstation    # or use a preset
#   ./install.sh -y                      # non-interactive: saved profiles
#   ./install.sh --list                  # show profiles and presets
#
# Options:
#   --profiles a,b   Profiles to install (replaces the saved selection)
#   --preset NAME    workstation | server | k8s-node
#   -y, --yes        Never prompt (also implied in Coder workspaces)
#   --dry-run        Print what would be done, change nothing
#   --link-only      Only link configs (no packages or tools)
#   --no-sudo        Skip system packages even if sudo works
#   -h, --help
#
# Environment:
#   DOTFILES_PROFILES="k8s iac"  Default profiles for -y when none are saved
#   DOTFILES_SKIP_INSTALL=1      Same as --link-only
#   GITHUB_TOKEN                 Avoids GitHub API rate limits for mise
###############################################################################

# No -u: macOS ships bash 3.2, where expanding an empty array under -u is an
# "unbound variable" error.
set -eo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/lib/common.sh"
# shellcheck source=lib/profiles.sh
source "$DOTFILES_DIR/lib/profiles.sh"
# shellcheck source=lib/link.sh
source "$DOTFILES_DIR/lib/link.sh"
# shellcheck source=lib/tools.sh
source "$DOTFILES_DIR/lib/tools.sh"

usage() { sed -n '3,27p' "$0" | sed 's/^# \{0,1\}//'; }

REQUESTED=""
HAVE_REQUEST=0
DRY_RUN=0
LINK_ONLY=0
NONINTERACTIVE=0
[[ -n "${CODER_WORKSPACE_NAME:-}" ]] && NONINTERACTIVE=1
[[ "${DOTFILES_SKIP_INSTALL:-}" == 1 ]] && LINK_ONLY=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profiles) REQUESTED="${2:-}"; REQUESTED="${REQUESTED//,/ }"; HAVE_REQUEST=1; shift ;;
    --profiles=*) REQUESTED="${1#*=}"; REQUESTED="${REQUESTED//,/ }"; HAVE_REQUEST=1 ;;
    --preset | --preset=*)
      if [[ "$1" == --preset ]]; then name="${2:-}"; shift; else name="${1#*=}"; fi
      REQUESTED="$(preset_profiles "$name")" || { log_error "Unknown preset '$name'"; exit 1; }
      HAVE_REQUEST=1 ;;
    -y | --yes) NONINTERACTIVE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --link-only) LINK_ONLY=1 ;;
    --no-sudo) NO_SUDO=1 ;;
    --list) detect_platform; list_profiles; exit 0 ;;
    -h | --help) usage; exit 0 ;;
    *) log_error "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done
export DRY_RUN NONINTERACTIVE

main() {
  detect_platform
  log_info "Platform: $OS/$ARCH ($OS_FAMILY)"
  [[ "$DRY_RUN" == 1 ]] && log_info "Dry run: nothing will be changed"

  # Profiles: flags, else the picker, else what was saved last time, else
  # $DOTFILES_PROFILES, else base only.
  local chosen
  if [[ "$HAVE_REQUEST" == 1 ]]; then
    chosen="$REQUESTED"
  else
    chosen="$(saved_profiles || true)"
    [[ -z "$chosen" ]] && chosen="${DOTFILES_PROFILES:-${DOTFILES_PROFILE:-}}"
    if [[ "$NONINTERACTIVE" != 1 && -t 0 && -t 1 && "$LINK_ONLY" != 1 ]]; then
      chosen="$(pick_profiles "$chosen")"
    fi
  fi
  # shellcheck disable=SC2086 # word-split the space-separated list
  resolve_profiles $chosen
  log_info "Profiles: ${RESOLVED[*]}"

  if [[ "$LINK_ONLY" == 1 ]]; then
    log_step "Linking configs (link-only)"
    link_home
    save_profiles
    log_success "Done"
    return
  fi

  detect_sudo
  [[ "$OS_FAMILY" == macos ]] || can_sudo || log_warning "No sudo: system packages will be skipped"

  log_step "System packages"
  case "$OS_FAMILY" in
    macos | debian | rhel)
      # shellcheck source=/dev/null
      source "$DOTFILES_DIR/os/$OS_FAMILY.sh"
      os_install "${RESOLVED[@]}" || log_warning "System package phase had issues (continuing)"
      ;;
    *) log_warning "Unsupported package manager; install zsh, tmux, git and curl yourself" ;;
  esac

  log_step "Linking configs"
  link_home
  save_profiles
  configure_git_local

  log_step "CLI tools (mise)"
  install_mise || log_warning "mise install failed (continuing)"
  install_profile_tools

  log_step "Shell and editor plugins"
  install_ohmyzsh || log_warning "oh-my-zsh had issues (continuing)"
  install_tpm || log_warning "TPM had issues (continuing)"
  install_vim_plug || log_warning "vim-plug had issues (continuing)"
  bootstrap_nvim || log_warning "Neovim bootstrap had issues (continuing)"

  log_step "Profile post-install"
  run_post_installs

  set_default_shell || true

  echo
  log_success "Done. Open a new terminal (or: exec zsh)."
  log_info "Change profiles any time: ./install.sh --profiles ...  (see --list)"
}

main
