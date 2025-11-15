#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
LOG_DIR="${TMPDIR:-/tmp}/agentic-k8s"
mkdir -p "$LOG_DIR"

SUMMARY=()
GITEA_NODEPORT=""

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
    sudo "$REPO_ROOT/cluster/scripts/install-k3s.sh"
    add_summary "Installed k3s"
  fi
}

ensure_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    log "kubectl already present"
    add_summary "kubectl already present"
  else
    log "Installing kubectl..."
    bash "$REPO_ROOT/cluster/scripts/install-kubectl.sh"
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

ensure_agent_kubeconfig() {
  local namespace="default"
  local service_account="agent-readonly"
  local clusterrole="agent-readonly-all"
  local clusterrolebinding="agent-readonly-all-binding"
  local kubeconfig_dir="$REPO_ROOT/cluster/kubeconfig"
  local kubeconfig_path="$kubeconfig_dir/agent.yml"

  log "Preparing read-only kubeconfig for agent workflows"
  mkdir -p "$kubeconfig_dir"

  kubectl create serviceaccount "$service_account" \
    --namespace "$namespace" \
    --dry-run=client -o yaml | kubectl apply -f - >/dev/null

  # Create a comprehensive read-only ClusterRole with access to all resources including CRDs
  kubectl apply -f - >/dev/null <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $clusterrole
rules:
  # Read access to all standard API resources
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
  # Read access to all resource statuses
  - apiGroups: ["*"]
    resources: ["*/status"]
    verbs: ["get", "list", "watch"]
  # Read access to non-resource URLs (e.g., /healthz, /metrics)
  - nonResourceURLs: ["*"]
    verbs: ["get"]
EOF

  kubectl create clusterrolebinding "$clusterrolebinding" \
    --clusterrole="$clusterrole" \
    --serviceaccount="$namespace:$service_account" \
    --dry-run=client -o yaml | kubectl apply -f - >/dev/null

  # Create a long-lived token secret for the service account
  local token_secret="${service_account}-token"
  kubectl apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $token_secret
  namespace: $namespace
  annotations:
    kubernetes.io/service-account.name: $service_account
type: kubernetes.io/service-account-token
EOF

  # Wait for the token to be populated
  local token=""
  for _ in {1..30}; do
    token=$(kubectl get secret "$token_secret" -n "$namespace" -o jsonpath='{.data.token}' 2>/dev/null | base64 -d 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$token" ]]; then
      break
    fi
    sleep 1
  done

  if [[ -z "$token" ]]; then
    log "WARNING: Unable to retrieve token from secret $namespace/$token_secret; skipping kubeconfig output"
    return
  fi

  local server
  server=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null | tr -d '\n' || true)
  if [[ -z "$server" ]]; then
    log "WARNING: Unable to resolve cluster server for agent kubeconfig"
    return
  fi

  local ca_data
  ca_data=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' 2>/dev/null | tr -d '\n' || true)
  if [[ -z "$ca_data" ]]; then
    local ca_file
    ca_file=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority}' 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$ca_file" && -r "$ca_file" ]]; then
      ca_data=$(base64 <"$ca_file" 2>/dev/null | tr -d '\n' || true)
    fi
  fi
  if [[ -z "$ca_data" ]]; then
    log "WARNING: Unable to resolve cluster CA data for agent kubeconfig"
    return
  fi

  cat >"$kubeconfig_path" <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $ca_data
    server: $server
  name: agentic-k8s
contexts:
- context:
    cluster: agentic-k8s
    user: $service_account
  name: agentic-k8s
current-context: agentic-k8s
users:
- name: $service_account
  user:
    token: $token
EOF

  chmod 600 "$kubeconfig_path" || true
  add_summary "Generated read-only kubeconfig at $kubeconfig_path"
}

main() {
  cd "$REPO_ROOT"

  require_command sudo

  ensure_k3s
  ensure_kubectl

  log "Installing additional tools (helm, k9s)"
  bash "$REPO_ROOT/cluster/scripts/install-tools.sh"
  add_summary "Installed additional tools (helm, k9s)"

  wait_for_nodes
  ensure_agent_kubeconfig

  log "Installing and configuring Argo CD"
  bash "$REPO_ROOT/cluster/scripts/install-argocd.sh"
  add_summary "Installed and configured Argo CD"

  printf '\nBootstrap summary:\n'
  for entry in "${SUMMARY[@]}"; do
    printf ' - %s\n' "$entry"
  done

  local node_ip
  node_ip=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || true)
  if [[ -z "$node_ip" ]]; then
    node_ip="<node-ip>"
  fi

  printf '\nAdditional Access Information:\n'
  if [[ -z "$GITEA_NODEPORT" ]]; then
    GITEA_NODEPORT=$(kubectl get svc gitea-http -n gitea -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null || true)
  fi
  if [[ -n "$GITEA_NODEPORT" ]]; then
    printf ' - Gitea NodePort: http://%s:%s\n' "$node_ip" "$GITEA_NODEPORT"
  else
    printf ' - Gitea NodePort: http://%s:%s\n' "$node_ip" "<unknown>"
  fi
  printf ' - Agent kubeconfig (read-only): %s\n' "$REPO_ROOT/cluster/kubeconfig"
}

main "$@"
