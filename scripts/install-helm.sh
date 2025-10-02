#!/usr/bin/env bash
set -euo pipefail

DEFAULT_VERSION="v3.15.2"
DEFAULT_INSTALL_DIR="/usr/local/bin"
HELM_BIN=""
TMPDIR=""

log() {
  printf '[install-helm] %s\n' "$1"
}

die() {
  printf '[install-helm] ERROR: %s\n' "$1" >&2
  exit 1
}

cleanup() {
  if [[ -n ${TMPDIR:-} && -d "$TMPDIR" ]]; then
    rm -rf "$TMPDIR"
  fi
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
    x86_64|amd64) ARCH_ID=amd64 ;;
    arm64|aarch64) ARCH_ID=arm64 ;;
    *) die "Unsupported CPU architecture '$arch'." ;;
  esac
}

resolve_version() {
  VERSION=${HELM_VERSION:-$DEFAULT_VERSION}
  if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    die "HELM_VERSION must be in form vX.Y.Z (got '$VERSION')."
  fi
}

download_and_extract() {
  local url archive_name
  url="https://get.helm.sh/helm-${VERSION}-${OS_ID}-${ARCH_ID}.tar.gz"
  archive_name="helm-${VERSION}-${OS_ID}-${ARCH_ID}.tar.gz"
  TMPDIR=$(mktemp -d)
  log "Downloading Helm ${VERSION} for ${OS_ID}/${ARCH_ID}..."
  curl -fsSL "$url" -o "$TMPDIR/$archive_name" || die "Failed to download Helm from $url"

  log "Extracting archive..."
  tar -xf "$TMPDIR/$archive_name" -C "$TMPDIR" || die "Failed to extract Helm archive"
  HELM_BIN="$TMPDIR/${OS_ID}-${ARCH_ID}/helm"
  if [[ ! -f "$HELM_BIN" ]]; then
    die "Helm binary not found after extraction"
  fi
}

install_binary() {
  local install_dir target
  install_dir=${HELM_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
  target="$install_dir/helm"

  if [[ ! -d "$install_dir" ]]; then
    mkdir -p "$install_dir" || die "Failed to create install directory $install_dir"
  fi

  if [[ ! -w "$install_dir" ]]; then
    die "Install directory $install_dir is not writable. Re-run with sudo or set HELM_INSTALL_DIR to a writable path."
  fi

  install -m 0755 "$HELM_BIN" "$target"
  INSTALLED_PATH="$target"
  log "Helm installed to $target"

  if ! command -v helm >/dev/null 2>&1; then
    log "Warning: helm not found on PATH; ensure $install_dir is added to PATH."
  fi
}

verify_version() {
  local reported
  log "Verifying Helm version..."
  reported=$("$INSTALLED_PATH" version --template '{{ .Version }}' 2>/dev/null || true)
  if [[ -z "$reported" ]]; then
    die "Unable to determine Helm version via helm version command."
  fi
  if [[ "$reported" != "$VERSION" ]]; then
    die "Installed Helm version '$reported' does not match expected '$VERSION'."
  fi
  log "Helm version validated (${reported})."
}

main() {
  trap cleanup EXIT
  require_commands curl tar
  resolve_os_arch
  resolve_version
  download_and_extract
  install_binary
  verify_version
  log "Helm installation complete."
}

main "$@"
