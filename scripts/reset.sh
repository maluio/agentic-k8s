#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  SUDO=${SUDO:-sudo}
else
  SUDO=""
fi

log() {
  printf '[reset] %s\n' "$1"
}

run() {
  if [[ -n "$SUDO" ]]; then
    "$SUDO" "$@"
  else
    "$@"
  fi
}

log "Uninstalling K3s and cleaning node data..."
run /usr/local/bin/k3s-uninstall.sh

log "Removing local kubeconfig copy (${HOME}/.kube/config) if present..."
rm -f "${HOME}/.kube/config" 2>/dev/null || true

log "K3s teardown complete."
