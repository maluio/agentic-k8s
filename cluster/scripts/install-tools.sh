#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
TMP_DIR="${TMPDIR:-/tmp}/agentic-k8s-tools"
mkdir -p "$TMP_DIR"

log() {
  printf '[install-tools] %s\n' "$1"
}

detect_arch() {
  local arch
  arch=$(uname -m)
  case "$arch" in
    x86_64)
      echo "amd64"
      ;;
    aarch64|arm64)
      echo "arm64"
      ;;
    armv7l)
      echo "arm"
      ;;
    *)
      log "WARNING: Unknown architecture $arch, defaulting to amd64"
      echo "amd64"
      ;;
  esac
}

install_helm() {
  if command -v helm >/dev/null 2>&1; then
    local current_version
    current_version=$(helm version --short 2>/dev/null | grep -oP 'v[0-9.]+' || echo "unknown")
    log "helm already installed ($current_version)"
    return
  fi

  log "Installing helm..."

  local helm_script="$TMP_DIR/get_helm.sh"

  if ! curl -fsSL -o "$helm_script" https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4; then
    log "ERROR: Failed to download helm installation script"
    return 1
  fi

  chmod 700 "$helm_script"

  if "$helm_script"; then
    log "helm installed successfully"
    rm -f "$helm_script"
  else
    log "ERROR: helm installation failed"
    rm -f "$helm_script"
    return 1
  fi
}

install_k9s() {
  if command -v k9s >/dev/null 2>&1; then
    local current_version
    current_version=$(k9s version --short 2>/dev/null | head -n1 | grep -oP 'v[0-9.]+' || echo "unknown")
    log "k9s already installed ($current_version)"
    return
  fi

  log "Installing k9s..."

  local arch
  arch=$(detect_arch)

  # Get the latest version from GitHub API
  local latest_version
  latest_version=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | grep -oP '"tag_name": "\K[^"]+' || echo "")

  if [[ -z "$latest_version" ]]; then
    log "WARNING: Could not determine latest k9s version, using v0.32.5"
    latest_version="v0.32.5"
  fi

  log "Downloading k9s $latest_version for $arch..."

  local download_url="https://github.com/derailed/k9s/releases/download/${latest_version}/k9s_linux_${arch}.deb"
  local deb_file="$TMP_DIR/k9s_linux_${arch}.deb"

  if ! curl -fsSL -o "$deb_file" "$download_url"; then
    log "ERROR: Failed to download k9s from $download_url"
    return 1
  fi

  log "Installing k9s package..."
  if sudo dpkg -i "$deb_file" >/dev/null 2>&1; then
    log "k9s installed successfully"
    rm -f "$deb_file"
  else
    log "ERROR: k9s installation failed"
    rm -f "$deb_file"
    return 1
  fi
}

main() {
  log "Starting tools installation"

  install_helm
  install_k9s

  log "Tools installation complete"

  # Display installed versions
  if command -v helm >/dev/null 2>&1; then
    printf '\nInstalled tools:\n'
    printf ' - helm: %s\n' "$(helm version --short 2>/dev/null | grep -oP 'v[0-9.]+' || echo 'unknown')"
  fi
  if command -v k9s >/dev/null 2>&1; then
    printf ' - k9s: %s\n' "$(k9s version --short 2>/dev/null | head -n1 | grep -oP 'v[0-9.]+' || echo 'unknown')"
  fi
}

main "$@"
