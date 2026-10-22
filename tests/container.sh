#!/usr/bin/env bash
# Run the installer in fresh Linux containers and check the result.
#   tests/container.sh                      # all images, workstation preset
#   tests/container.sh ubuntu:24.04 k8s,iac # one image, chosen profiles
# Needs docker (or podman via DOCKER=podman). Set GITHUB_TOKEN to avoid
# GitHub API rate limits when mise resolves "latest".
set -eo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER="${DOCKER:-docker}"
IMAGES=("${1:-ubuntu:24.04}")
[[ -z "$1" ]] && IMAGES=(ubuntu:24.04 ubuntu:22.04 debian:12 fedora:41 rockylinux:9)
PROFILES="${2:-k8s,iac,cloud-aws,aws-dev,arch,ai}"

# Commands every install should leave on PATH for an interactive zsh.
CHECK='for c in zsh tmux git nvim mise starship fzf rg eza bat delta; do
  command -v $c >/dev/null || { echo "MISSING $c"; fail=1; }; done
case ",$PROFILES," in *,k8s,*) command -v kubectl helm k9s >/dev/null || fail=1 ;; esac
case ",$PROFILES," in *,iac,*) command -v terraform ansible >/dev/null || fail=1 ;; esac
case ",$PROFILES," in *,aws-dev,*) command -v cdk aws >/dev/null || fail=1 ;; esac
exit ${fail:-0}'

status=0
for image in "${IMAGES[@]}"; do
  echo "=== $image ($PROFILES)"
  # Bootstrap only what a bare image lacks to fetch the installer's deps.
  if "$DOCKER" run --rm -e GITHUB_TOKEN -e PROFILES="$PROFILES" -e CHECK="$CHECK" -v "$REPO:/src:ro" "$image" bash -c '
      set -e
      (command -v apt-get >/dev/null && apt-get update -qq && apt-get install -y -qq git curl sudo >/dev/null) ||
        (command -v dnf >/dev/null && dnf install -y -q git curl sudo >/dev/null)
      cp -r /src "$HOME/dotfiles"
      "$HOME/dotfiles/install.sh" -y --profiles "$PROFILES"
      zsh -i -c "$CHECK"
    '; then
    echo "PASS $image"
  else
    echo "FAIL $image"; status=1
  fi
done
exit $status
