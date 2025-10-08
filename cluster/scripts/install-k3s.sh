#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[install-k3s] %s\n' "$1"
}

die() {
  printf '[install-k3s] ERROR: %s\n' "$1" >&2
  exit 1
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "This script must be run as root (try: sudo ./scripts/install-k3s.sh)"
  fi
}

check_prerequisites() {
  local os arch
  os=$(uname -s)
  arch=$(uname -m)
  if [[ "$os" != "Linux" ]]; then
    die "K3s installation script currently supports Linux hosts only (detected: $os)."
  fi

  case "$arch" in
    x86_64|aarch64|arm64) ;;
    *)
      die "Unsupported CPU architecture '$arch'. Install manually by following https://k3s.io/."
      ;;
  esac

  command -v curl >/dev/null 2>&1 || die "curl is required to download the K3s installer."

  if ! command -v systemctl >/dev/null 2>&1; then
    die "systemd is required to manage the k3s service."
  fi
}

install_k3s() {
  local channel install_url tmp_script
  channel=${K3S_CHANNEL:-stable}
  install_url=${K3S_INSTALL_URL:-https://get.k3s.io}

  log "Installing K3s from channel '$channel'..."
  tmp_script=$(mktemp)
  curl -sfL "$install_url" -o "$tmp_script"
  chmod +x "$tmp_script"

  INSTALL_K3S_CHANNEL="$channel" \
    INSTALL_K3S_VERSION="${K3S_VERSION:-}" \
    INSTALL_K3S_EXEC="${K3S_EXEC:-}" \
    INSTALL_K3S_SKIP_DOWNLOAD="${K3S_SKIP_DOWNLOAD:-}" \
    "$tmp_script" --write-kubeconfig-mode 644

  rm -f "$tmp_script"

  log "Ensuring k3s service is enabled and running..."
  systemctl enable k3s >/dev/null
  systemctl restart k3s
  systemctl is-active --quiet k3s || die "k3s service failed to start. Check journalctl -u k3s."
}

sync_kubeconfig() {
  local kube_src kube_dst target_user target_group target_home
  kube_src=/etc/rancher/k3s/k3s.yaml
  if [[ ! -f "$kube_src" ]]; then
    die "Expected kubeconfig at $kube_src but it was not found."
  fi

  target_user=${SUDO_USER:-root}
  if [[ -n ${SUDO_USER:-} ]]; then
    target_group=$(id -gn "$SUDO_USER") || die "Unable to determine primary group for $SUDO_USER"
  else
    target_group=root
  fi

  if command -v getent >/dev/null 2>&1; then
    target_home=$(getent passwd "$target_user" | cut -d: -f6)
  else
    target_home=$(eval echo "~$target_user")
  fi
  if [[ -z "$target_home" ]]; then
    die "Unable to determine home directory for user '$target_user'."
  fi

  mkdir -p "$target_home/.kube"
  kube_dst=${K3S_KUBECONFIG_DST:-$target_home/.kube/config}
  cp "$kube_src" "$kube_dst"
  chown "$target_user":"$target_group" "$kube_dst"
  chmod 600 "$kube_dst"

  log "Kubeconfig copied to $kube_dst"
  if [[ "$target_user" != "root" ]]; then
    log "To use it as $target_user, run: export KUBECONFIG=$kube_dst"
  else
    log "To use it, run: export KUBECONFIG=$kube_dst"
  fi
}

verify_cluster() {
  if command -v k3s >/dev/null 2>&1; then
    log "Verifying cluster status with 'k3s kubectl get nodes'..."
    if ! k3s kubectl get nodes; then
      die "Cluster verification failed. Review k3s service logs."
    fi
  else
    log "k3s binary not found on PATH; skipping automatic verification."
  fi
}

main() {
  require_root
  check_prerequisites
  install_k3s
  sync_kubeconfig
  verify_cluster
  log "K3s installation complete."
}

main "$@"
