#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
LOG_DIR="${TMPDIR:-/tmp}/agentic-k8s"
mkdir -p "$LOG_DIR"

SUMMARY=()
ARGOCD_MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

log() {
  printf '[bootstrap] %s\n' "$1"
}

add_summary() {
  SUMMARY+=("$1")
}

require_command() {
  local cmd=$1
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf '[bootstrap] ERROR: required command %s not found on PATH\n' "$cmd" >&2
    exit 1
  fi
}

ensure_k3s() {
  if systemctl is-active --quiet k3s; then
    log "k3s service already active"
    add_summary "k3s already running"
  else
    log "Installing k3s (sudo required)..."
    sudo "$REPO_ROOT/scripts/install-k3s.sh"
    add_summary "Installed k3s"
  fi
}

ensure_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    log "kubectl already present"
    add_summary "kubectl already present"
  else
    log "Installing kubectl..."
    bash "$REPO_ROOT/scripts/install-kubectl.sh"
    add_summary "Installed kubectl"
  fi
}

wait_for_nodes() {
  log "Waiting for Kubernetes nodes to register..."
  local node_list=""
  for _ in {1..60}; do
    node_list=$(kubectl get nodes --no-headers 2>/dev/null || true)
    if [[ -n "$node_list" ]]; then
      break
    fi
    sleep 2
  done

  if [[ -z "$node_list" ]]; then
    log "WARNING: No Kubernetes nodes detected after waiting; proceeding anyway"
    return
  fi

  log "Waiting for Kubernetes nodes to be Ready..."
  if ! kubectl wait --for=condition=Ready node --all --timeout=180s >/dev/null 2>&1; then
    log "WARNING: Kubernetes nodes did not reach Ready within timeout"
  else
    log "Kubernetes nodes Ready"
  fi
}

wait_for_deployment() {
  local ns=$1
  local name=$2
  log "Waiting for deployment/$name in $ns"
  kubectl rollout status deployment/"$name" -n "$ns" --timeout=180s >/dev/null
  add_summary "deployment/$name in $ns available"
}

wait_for_statefulset() {
  local ns=$1
  local name=$2
  log "Waiting for statefulset/$name in $ns"
  kubectl rollout status statefulset/"$name" -n "$ns" --timeout=180s >/dev/null
  add_summary "statefulset/$name in $ns available"
}

install_argocd() {
  log "Ensuring argocd namespace exists"
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - >/dev/null

  log "Applying Argo CD upstream install manifest"
  kubectl apply -n argocd -f "$ARGOCD_MANIFEST_URL" >/dev/null
  add_summary "Applied Argo CD upstream manifest"

  wait_for_deployment argocd argocd-server
  wait_for_deployment argocd argocd-repo-server
  wait_for_statefulset argocd argocd-application-controller || true
}

main() {
  cd "$REPO_ROOT"

  require_command sudo

  ensure_k3s
  ensure_kubectl
  wait_for_nodes
  install_argocd

  local argocd_password
  argocd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)
  if [[ -n "$argocd_password" ]]; then
    add_summary "Retrieved Argo CD admin credentials"
  else
    argocd_password="<unknown>"
    log "WARNING: Unable to read Argo CD admin password"
  fi

  printf '\nBootstrap summary:\n'
  for entry in "${SUMMARY[@]}"; do
    printf ' - %s\n' "$entry"
  done

  local node_ip
  node_ip=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || true)
  if [[ -z "$node_ip" ]]; then
    node_ip="<node-ip>"
  fi

  printf '\nAccess information:\n'
  printf ' - Argo CD namespace: argocd\n'
  printf ' - Argo CD admin password: %s\n' "$argocd_password"
  printf ' - Access via port-forward: kubectl port-forward -n argocd svc/argocd-server 8080:443\n'
  printf ' - Once forwarded: https://localhost:8080 (user: admin)\n'
}

main "$@"
