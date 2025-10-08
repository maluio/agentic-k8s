#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
LOG_DIR="${TMPDIR:-/tmp}/agentic-k8s"
mkdir -p "$LOG_DIR"

SUMMARY=()
ARGOCD_MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
ARGOCD_NODEPORT=""
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

wait_for_deployment() {
  local ns=$1
  local name=$2
  log "Waiting for deployment/$name in $ns"
  if kubectl rollout status deployment/"$name" -n "$ns" --timeout=180s >/dev/null; then
    add_summary "deployment/$name in $ns available"
  else
    log "WARNING: deployment/$name in $ns did not reach Ready"
  fi
}

wait_for_statefulset() {
  local ns=$1
  local name=$2
  log "Waiting for statefulset/$name in $ns"
  if kubectl rollout status statefulset/"$name" -n "$ns" --timeout=180s >/dev/null; then
    add_summary "statefulset/$name in $ns available"
  else
    log "WARNING: statefulset/$name in $ns did not reach Ready"
  fi
}

ensure_agent_kubeconfig() {
  local agent_dir="$REPO_ROOT/agent"
  local namespace="default"
  local service_account="agent-readonly"
  local clusterrolebinding="agent-readonly-view"
  local kubeconfig_path="$agent_dir/kubeconfig"

  log "Preparing read-only kubeconfig for agent workflows"
  mkdir -p "$agent_dir"

  kubectl create serviceaccount "$service_account" \
    --namespace "$namespace" \
    --dry-run=client -o yaml | kubectl apply -f - >/dev/null

  kubectl create clusterrolebinding "$clusterrolebinding" \
    --clusterrole=view \
    --serviceaccount="$namespace:$service_account" \
    --dry-run=client -o yaml | kubectl apply -f - >/dev/null

  local token
  if ! token=$(kubectl create token "$service_account" --namespace "$namespace" 2>/dev/null | tr -d '\n'); then
    log "WARNING: Unable to generate token for $namespace/$service_account; skipping kubeconfig output"
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
  add_summary "Generated read-only kubeconfig at agent/kubeconfig"
}

ensure_argocd_nodeport() {
  local namespace="argocd"
  local service="argocd-server"
  local desired_nodeport=32443

  log "Ensuring Argo CD server Service exposes NodePort ${desired_nodeport}"

  local current_type=""
  current_type=$(kubectl get svc "$service" -n "$namespace" -o jsonpath='{.spec.type}' 2>/dev/null || true)

  local current_https_nodeport=""
  if [[ -n "$current_type" ]]; then
    current_https_nodeport=$(kubectl get svc "$service" -n "$namespace" -o jsonpath='{range .spec.ports[?(@.name=="https")]}{.nodePort}{end}' 2>/dev/null || true)
  fi

  if [[ "$current_type" == "NodePort" && "$current_https_nodeport" == "$desired_nodeport" ]]; then
    ARGOCD_NODEPORT="$current_https_nodeport"
    add_summary "Argo CD server Service already NodePort:$desired_nodeport"
    return
  fi

  if ! kubectl patch svc "$service" -n "$namespace" --type merge -p "{\"spec\":{\"type\":\"NodePort\",\"ports\":[{\"name\":\"https\",\"nodePort\":$desired_nodeport}]}}" >/dev/null 2>&1; then
    log "WARNING: Failed to set fixed NodePort ${desired_nodeport}; falling back to cluster-assigned port"
    if ! kubectl patch svc "$service" -n "$namespace" --type merge -p '{"spec":{"type":"NodePort"}}' >/dev/null 2>&1; then
      log "WARNING: Unable to patch Argo CD server Service to NodePort"
      return
    fi
  fi

  local observed_nodeport=""
  observed_nodeport=$(kubectl get svc "$service" -n "$namespace" -o jsonpath='{range .spec.ports[?(@.name=="https")]}{.nodePort}{end}' 2>/dev/null || true)
  if [[ -z "$observed_nodeport" ]]; then
    log "WARNING: Unable to determine Argo CD server NodePort after patch"
    return
  fi

  ARGOCD_NODEPORT="$observed_nodeport"
  add_summary "Argo CD server Service NodePort:$observed_nodeport"
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
  ensure_agent_kubeconfig
  ensure_argocd_nodeport

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
  if [[ -n "$ARGOCD_NODEPORT" ]]; then
    printf ' - Argo CD HTTPS NodePort: https://%s:%s (user: admin)\n' "$node_ip" "$ARGOCD_NODEPORT"
    printf ' - Optional port-forward: kubectl port-forward -n argocd svc/argocd-server 8080:443\n'
    printf ' - Once forwarded: https://localhost:8080 (user: admin)\n'
  else
    printf ' - Argo CD HTTPS NodePort: <unknown; run kubectl -n argocd get svc argocd-server>\n'
    printf ' - Optional port-forward: kubectl port-forward -n argocd svc/argocd-server 8080:443\n'
    printf ' - Once forwarded: https://localhost:8080 (user: admin)\n'
  fi
  if [[ -z "$GITEA_NODEPORT" ]]; then
    GITEA_NODEPORT=$(kubectl get svc gitea-http -n gitea -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null || true)
  fi
  if [[ -n "$GITEA_NODEPORT" ]]; then
    printf ' - Gitea NodePort: http://%s:%s\n' "$node_ip" "$GITEA_NODEPORT"
  else
    printf ' - Gitea NodePort: http://%s:%s\n' "$node_ip" "<unknown>"
  fi
  printf ' - Agent kubeconfig (read-only): %s\n' "$REPO_ROOT/agent/kubeconfig"
}

main "$@"
