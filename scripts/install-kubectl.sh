#!/usr/bin/env bash
set -euo pipefail

DEFAULT_VERSION="v1.30.3"
DEFAULT_INSTALL_DIR="/usr/local/bin"
INSTALLED_PATH=""

log() {
  printf '[install-kubectl] %s\n' "$1"
}

die() {
  printf '[install-kubectl] ERROR: %s\n' "$1" >&2
  exit 1
}

require_commands() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || die "Required command '$cmd' not found on PATH."
  done
}

resolve_os_arch() {
  local os arch
  os=$(uname -s)
  arch=$(uname -m)

  case "$os" in
    Linux) OS_ID=linux ;;
    Darwin) OS_ID=darwin ;;
    *) die "Unsupported operating system '$os'." ;;
  esac

  case "$arch" in
    x86_64) ARCH_ID=amd64 ;;
    amd64) ARCH_ID=amd64 ;;
    arm64) ARCH_ID=arm64 ;;
    aarch64) ARCH_ID=arm64 ;;
    *) die "Unsupported CPU architecture '$arch'." ;;
  esac
}

resolve_version() {
  VERSION=${KUBECTL_VERSION:-$DEFAULT_VERSION}
  if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    die "KUBECTL_VERSION must be in form vX.Y.Z (got '$VERSION')."
  fi
}

cleanup() {
  [[ -n ${DOWNLOADED_FILE:-} && -f $DOWNLOADED_FILE ]] && rm -f "$DOWNLOADED_FILE"
}

download_kubectl() {
  local url tmpfile
  url="https://dl.k8s.io/release/${VERSION}/bin/${OS_ID}/${ARCH_ID}/kubectl"
  tmpfile=$(mktemp)
  log "Downloading kubectl ${VERSION} for ${OS_ID}/${ARCH_ID}..."
  curl -fsSL "$url" -o "$tmpfile" || die "Failed to download kubectl from $url"
  chmod +x "$tmpfile"
  DOWNLOADED_FILE="$tmpfile"
}

install_binary() {
  local install_dir target
  install_dir=${KUBECTL_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
  target="$install_dir/kubectl"

  if [[ ! -d "$install_dir" ]]; then
    mkdir -p "$install_dir" || die "Failed to create install directory $install_dir"
  fi

  if [[ ! -w "$install_dir" ]]; then
    die "Install directory $install_dir is not writable. Re-run with sudo or choose a different KUBECTL_INSTALL_DIR."
  fi

  install -m 0755 "$DOWNLOADED_FILE" "$target"
  INSTALLED_PATH="$target"
  log "kubectl installed to $target"

  if ! command -v kubectl >/dev/null 2>&1; then
    log "Warning: kubectl not found on PATH; ensure $install_dir is added to PATH."
  fi
}

verify_binary() {
  log "Verifying kubectl client version..."
  "$INSTALLED_PATH" version --client --output=json >/dev/null || die "kubectl client verification failed."
}

determine_kubeconfig() {
  if [[ -n ${KUBECONFIG:-} ]]; then
    KUBECONFIG_PATH="$KUBECONFIG"
    return
  fi

  if [[ -n ${SUDO_USER:-} ]]; then
    if command -v getent >/dev/null 2>&1; then
      KUBECONFIG_PATH=$(getent passwd "$SUDO_USER" | cut -d: -f6)/.kube/config
    else
      KUBECONFIG_PATH=$(eval echo "~$SUDO_USER")/.kube/config
    fi
  else
    KUBECONFIG_PATH="$HOME/.kube/config"
  fi
}

verify_cluster() {
  determine_kubeconfig
  if [[ -z ${KUBECONFIG_PATH:-} || ! -f $KUBECONFIG_PATH ]]; then
    die "Kubeconfig not found at ${KUBECONFIG_PATH:-"(unset)"}. Ensure the local cluster is provisioned and KUBECONFIG is set."
  fi

  log "Checking cluster connectivity with 'kubectl get nodes'..."
  if ! KUBECONFIG="$KUBECONFIG_PATH" "$INSTALLED_PATH" get nodes --request-timeout=10s; then
    die "kubectl could not reach the cluster. Verify the local cluster is running and kubeconfig is valid."
  fi
  log "Cluster connectivity verified via $KUBECONFIG_PATH"
}

main() {
  require_commands curl
  trap cleanup EXIT
  resolve_os_arch
  resolve_version
  download_kubectl
  install_binary
  verify_binary
  verify_cluster
  log "kubectl installation and verification complete."
}

main "$@"
