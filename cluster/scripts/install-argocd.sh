#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

ARGOCD_MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
ARGOCD_NODEPORT=""

log() {
  printf '[install-argocd] %s\n' "$1"
}

wait_for_deployment() {
  local ns=$1
  local name=$2
  log "Waiting for deployment/$name in $ns"
  if kubectl rollout status deployment/"$name" -n "$ns" --timeout=180s >/dev/null; then
    log "deployment/$name in $ns available"
  else
    log "WARNING: deployment/$name in $ns did not reach Ready"
  fi
}

wait_for_statefulset() {
  local ns=$1
  local name=$2
  log "Waiting for statefulset/$name in $ns"
  if kubectl rollout status statefulset/"$name" -n "$ns" --timeout=180s >/dev/null; then
    log "statefulset/$name in $ns available"
  else
    log "WARNING: statefulset/$name in $ns did not reach Ready"
  fi
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
    log "Argo CD server Service already NodePort:$desired_nodeport"
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
  log "Argo CD server Service NodePort:$observed_nodeport"
}

install_argocd() {
  log "Ensuring argocd namespace exists"
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - >/dev/null

  log "Applying Argo CD upstream install manifest"
  kubectl apply -n argocd -f "$ARGOCD_MANIFEST_URL" >/dev/null
  log "Applied Argo CD upstream manifest"

  wait_for_deployment argocd argocd-server
  wait_for_deployment argocd argocd-repo-server
  wait_for_statefulset argocd argocd-application-controller || true
}

create_agent_root_application() {
  log "Creating k8s-agent-root ArgoCD application"

  kubectl apply -f - >/dev/null <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: k8s-agent-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/maluio/agentic-k8s
    targetRevision: main
    path: cluster/argocd/manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy: {}
EOF

  # Wait for the application to be created
  local app_exists=""
  for _ in {1..30}; do
    app_exists=$(kubectl get application k8s-agent-root -n argocd --no-headers 2>/dev/null || true)
    if [[ -n "$app_exists" ]]; then
      break
    fi
    sleep 1
  done

  if [[ -n "$app_exists" ]]; then
    log "Created k8s-agent-root ArgoCD application"
  else
    log "WARNING: k8s-agent-root application creation timeout"
  fi
}

print_access_info() {
  local argocd_password
  argocd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)
  if [[ -z "$argocd_password" ]]; then
    argocd_password="<unknown>"
    log "WARNING: Unable to read Argo CD admin password"
  fi

  local node_ip
  node_ip=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || true)
  if [[ -z "$node_ip" ]]; then
    node_ip="<node-ip>"
  fi

  printf '\nArgo CD Access Information:\n'
  printf ' - Namespace: argocd\n'
  printf ' - Admin username: admin\n'
  printf ' - Admin password: %s\n' "$argocd_password"
  if [[ -n "$ARGOCD_NODEPORT" ]]; then
    printf ' - HTTPS NodePort: https://%s:%s\n' "$node_ip" "$ARGOCD_NODEPORT"
  else
    printf ' - HTTPS NodePort: <unknown; run kubectl -n argocd get svc argocd-server>\n'
  fi
  printf ' - Port-forward option: kubectl port-forward -n argocd svc/argocd-server 8080:443\n'
  printf ' - Once forwarded: https://localhost:8080\n'
}

main() {
  log "Starting Argo CD installation and configuration"

  install_argocd
  create_agent_root_application
  ensure_argocd_nodeport
  print_access_info

  log "Argo CD installation complete"
}

main "$@"
