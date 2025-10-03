#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
LOG_DIR="${TMPDIR:-/tmp}/agentic-k8s"
mkdir -p "$LOG_DIR"

SUMMARY=()

GITEA_USER="agentadmin"
GITEA_EMAIL="agentadmin@example.com"
GITEA_PASSWORD="agentadmin123!"
GITEA_TOKEN_SECRET_NAME="repo-agentic-k8s"

GITEA_PORT_FORWARD_CMD="kubectl port-forward -n gitea svc/gitea-http 8090:3000 --address 0.0.0.0"
ARGO_HTTP_PORT_FORWARD_CMD="kubectl port-forward -n argocd svc/argocd-server 8093:80 --address 0.0.0.0"
ARGO_TLS_PORT_FORWARD_CMD="kubectl port-forward -n argocd svc/argocd-server 8083:443 --address 0.0.0.0"
NGINX_PORT_FORWARD_CMD="kubectl port-forward -n default svc/nginx-example 8081:80 --address 0.0.0.0"
FIREFOX_PORT_FORWARD_CMD="kubectl port-forward -n tools svc/firefox 5801:5800 --address 0.0.0.0"

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

ensure_helm() {
  if command -v helm >/dev/null 2>&1; then
    log "Helm already present"
    add_summary "Helm already present"
  else
    log "Installing Helm..."
    bash "$REPO_ROOT/scripts/install-helm.sh"
    add_summary "Installed Helm"
  fi
}

wait_for_nodes() {
  log "Waiting for Kubernetes nodes to be Ready..."
  kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null
  log "Kubernetes nodes Ready"
}

helm_upgrade() {
  local release=$1
  local chart_path=$2
  local namespace=$3
  shift 3
  log "Deploying/Upgrading Helm release $release"
  helm upgrade --install "$release" "$chart_path" --namespace "$namespace" --create-namespace "$@"
}

ensure_gitea_release() {
  if kubectl get deployment gitea -n gitea >/dev/null 2>&1; then
    log "Gitea deployment already exists; skipping Helm install"
    add_summary "Gitea already deployed"
  else
    helm_upgrade gitea charts/gitea gitea -f charts/gitea/values-local.yaml
    add_summary "Installed Gitea release"
  fi
  wait_for_deployment gitea gitea
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

get_gitea_pod() {
  kubectl get pods -n gitea -l app.kubernetes.io/name=gitea -o jsonpath='{.items[0].metadata.name}'
}

ensure_gitea_user() {
  local pod=$1
  if kubectl exec -n gitea -c gitea "$pod" -- gitea admin user list | grep -qw "$GITEA_USER"; then
    log "Gitea user $GITEA_USER already exists"
  else
    log "Creating Gitea admin user $GITEA_USER"
    kubectl exec -n gitea -c gitea "$pod" -- gitea admin user create --username "$GITEA_USER" --password "$GITEA_PASSWORD" --email "$GITEA_EMAIL" --admin --must-change-password=false
    add_summary "Created Gitea admin user"
  fi
}

ensure_port_forward() {
  local label=$1
  local match=$2
  local command=$3
  local logfile=$4

  if pgrep -f "$match" >/dev/null 2>&1; then
    log "$label port-forward already running"
    add_summary "$label port-forward active"
  else
    log "Starting $label port-forward"
    nohup bash -c "$command" >"$logfile" 2>&1 &
    sleep 1
    if pgrep -f "$match" >/dev/null 2>&1; then
      add_summary "Started $label port-forward"
    else
      log "WARNING: Failed to start $label port-forward (see $logfile)"
    fi
  fi
}

wait_for_url() {
  local url=$1
  local name=$2
  for _ in {1..30}; do
    if curl -sfL "$url" >/dev/null 2>&1; then
      log "$name endpoint reachable"
      return 0
    fi
    sleep 2
  done
  log "WARNING: $name endpoint did not become reachable"
  return 1
}

create_gitea_repo() {
  local token=$1
  local response
  response=$(curl -s -o "$LOG_DIR/create_repo.json" -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -H "Authorization: token $token" \
    -X POST http://127.0.0.1:8090/api/v1/user/repos \
    -d '{"name":"agentic-k8s","private":false}')
  if [[ "$response" == "201" ]]; then
    log "Created repository $GITEA_USER/agentic-k8s in Gitea"
    add_summary "Seeded Gitea repository"
  elif [[ "$response" == "409" ]]; then
    log "Gitea repository already exists"
  else
    log "WARNING: Failed to create Gitea repository (HTTP $response). Details: $LOG_DIR/create_repo.json"
  fi
}

ensure_repo_secret() {
  local existing_token
  if kubectl get secret "$GITEA_TOKEN_SECRET_NAME" -n argocd >/dev/null 2>&1; then
    existing_token=$(kubectl get secret "$GITEA_TOKEN_SECRET_NAME" -n argocd -o jsonpath='{.data.password}' | base64 -d)
    if curl -sf -H "Authorization: token $existing_token" http://127.0.0.1:8090/api/v1/user >/dev/null 2>&1; then
      printf '[bootstrap] %s\n' "Reusing existing Argo CD repository secret" >&2
      printf '%s' "$existing_token"
      return 0
    else
      printf '[bootstrap] %s\n' "Existing Argo CD repository token invalid; generating a new one" >&2
    fi
  fi

  local pod token_name output token
  pod=$(get_gitea_pod)
  token_name="bootstrap-$(date +%s)"
  output=$(kubectl exec -n gitea -c gitea "$pod" -- gitea admin user generate-access-token --username "$GITEA_USER" --token-name "$token_name" 2>&1)
  if [[ $? -ne 0 ]]; then
    printf '[bootstrap] ERROR: %s\n' "Unable to create Gitea token. Output: $output" >&2
    exit 1
  fi
  token=$(echo "$output" | awk -F': ' 'NF>1 {print $2}' | tr -d '\r\n')
  if [[ -z "$token" ]]; then
    printf '[bootstrap] ERROR: %s\n' "Could not parse Gitea token output: $output" >&2
    exit 1
  fi

  cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Secret
metadata:
  name: $GITEA_TOKEN_SECRET_NAME
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  name: agentic-k8s
  url: http://gitea-http.gitea.svc.cluster.local:3000/$GITEA_USER/agentic-k8s.git
  username: $GITEA_USER
  password: $token
EOF
  add_summary "Created Argo CD repository secret"
  printf '%s' "$token"
}

push_repository() {
  local token=$1
  local remote_url="http://$GITEA_USER:$token@127.0.0.1:8090/$GITEA_USER/agentic-k8s.git"
  if git -C "$REPO_ROOT" remote get-url gitea >/dev/null 2>&1; then
    git -C "$REPO_ROOT" remote set-url gitea "$remote_url"
  else
    git -C "$REPO_ROOT" remote add gitea "$remote_url"
  fi
  if git -C "$REPO_ROOT" push gitea main >/dev/null 2>&1; then
    add_summary "Pushed repository to local Gitea"
  else
    log "WARNING: Failed to push repository to Gitea"
  fi
}

wait_for_application() {
  local name=$1
  for _ in {1..60}; do
    local sync health
    sync=$(kubectl -n argocd get applications.argoproj.io "$name" -o jsonpath='{.status.sync.status}' 2>/dev/null || true)
    health=$(kubectl -n argocd get applications.argoproj.io "$name" -o jsonpath='{.status.health.status}' 2>/dev/null || true)
    if [[ "$sync" == "Synced" && "$health" == "Healthy" ]]; then
      log "Argo CD application $name is Synced/Healthy"
      add_summary "Argo CD application $name synced"
      return 0
    fi
    sleep 5
  done
  log "WARNING: Argo CD application $name did not reach Synced/Healthy"
  return 1
}

main() {
  cd "$REPO_ROOT"

  require_command curl
  require_command git
  require_command sudo

  ensure_k3s
  ensure_kubectl
  ensure_helm

  wait_for_nodes

  ensure_gitea_release

  ensure_port_forward "Gitea" "kubectl port-forward.*gitea-http.*8090:3000" "$GITEA_PORT_FORWARD_CMD" "$LOG_DIR/gitea-port-forward.log"
  wait_for_url http://127.0.0.1:8090/api/swagger.json "Gitea" || true

  local gitea_pod
  gitea_pod=$(get_gitea_pod)
  ensure_gitea_user "$gitea_pod"

  local repo_token
  repo_token=$(ensure_repo_secret)
  create_gitea_repo "$repo_token"
  push_repository "$repo_token"

  helm_upgrade argocd charts/argo-cd argocd -f charts/argo-cd/values-local.yaml
  wait_for_deployment argocd argocd-server
  wait_for_deployment argocd argocd-repo-server
  wait_for_statefulset argocd argocd-application-controller || true

  ensure_port_forward "Argo CD HTTP" "kubectl port-forward.*argocd-server.*8093:80" "$ARGO_HTTP_PORT_FORWARD_CMD" "$LOG_DIR/argocd-http-port-forward.log"
  ensure_port_forward "Argo CD TLS" "kubectl port-forward.*argocd-server.*8083:443" "$ARGO_TLS_PORT_FORWARD_CMD" "$LOG_DIR/argocd-tls-port-forward.log"
  ensure_port_forward "NGINX example" "kubectl port-forward.*nginx-example.*8081:80" "$NGINX_PORT_FORWARD_CMD" "$LOG_DIR/nginx-port-forward.log"
  helm_upgrade firefox charts/firefox tools
  wait_for_deployment tools firefox
  ensure_port_forward "Firefox" "kubectl port-forward.*svc/firefox.*5801:5800" "$FIREFOX_PORT_FORWARD_CMD" "$LOG_DIR/firefox-port-forward.log"

  kubectl apply -f argocd >/dev/null
  wait_for_application gitea || true
  wait_for_application nginx-example || true

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

  printf '\nAccess information:\n'
  printf ' - Gitea UI:      http://127.0.0.1:8090/ (credentials %s / %s)\n' "$GITEA_USER" "$GITEA_PASSWORD"
  printf ' - Argo CD UI:    http://127.0.0.1:8093/\n'
  printf ' - Argo CD gRPC:  https://127.0.0.1:8083/\n'
  printf ' - Argo CD admin password: %s\n' "$argocd_password"
  printf ' - NGINX example: http://127.0.0.1:8081/\n'
  printf ' - Firefox (web): http://127.0.0.1:5801/ (password firefox)\n'
  printf '\nPort-forward logs: %s\n' "$LOG_DIR"
}

main "$@"
