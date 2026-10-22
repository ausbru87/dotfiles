# shellcheck shell=bash
# Shared helpers for install.sh: logging, dry-run, sudo detection.

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_step()    { echo; echo -e "${GREEN}==>${NC} $1"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Run a command, or only print it under --dry-run.
run() {
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    echo "  + $*"
  else
    "$@"
  fi
}

# Root needs no sudo; otherwise use sudo when it works without a password,
# or when a TTY is attached so it can prompt. Anything else (OpenShift
# restricted-v2 pods, CI without sudo) is a no-sudo host: system packages
# are skipped and everything else installs into $HOME.
detect_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=()
  elif [[ "${NO_SUDO:-0}" == 1 ]]; then
    SUDO=(false)
  elif have sudo && { sudo -n true 2>/dev/null || [[ -t 0 && "${NONINTERACTIVE:-0}" != 1 ]]; }; then
    SUDO=(sudo)
  else
    NO_SUDO=1
    SUDO=(false)
  fi
}

can_sudo() { [[ "${NO_SUDO:-0}" != 1 ]]; }

# sudo-or-root wrapper; under dry-run only prints.
as_root() { run "${SUDO[@]}" "$@"; }

detect_platform() {
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  OS_FAMILY=unknown
  if [[ "$OS" == darwin ]]; then
    OS_FAMILY=macos
  elif have apt-get; then
    OS_FAMILY=debian
  elif have dnf || have yum; then
    OS_FAMILY=rhel
  fi
}
