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
CHARTS_REPO_NAME="agentic-k8s-charts"
CHARTS_REPO_SECRET_NAME="repo-agentic-k8s-charts"

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
  local pod status
  pod=$(get_gitea_pod)
  status=$(kubectl exec -n gitea -c gitea "$pod" -- \
    curl -sS -o /dev/null -w '%{http_code}' \
      -u "$GITEA_USER:$GITEA_PASSWORD" \
      -H 'Content-Type: application/json' \
      -d '{"name":"agentic-k8s","private":false,"default_branch":"main"}' \
      http://127.0.0.1:3000/api/v1/user/repos 2>/dev/null || true)

  if [[ -z "$status" ]]; then
    status="000"
  fi

  case "$status" in
    201)
      log "Created repository $GITEA_USER/agentic-k8s in Gitea"
      add_summary "Seeded Gitea repository"
      ;;
    409)
      log "Gitea repository already exists"
      ;;
    *)
      log "WARNING: Failed to create Gitea repository via API (HTTP $status)"
      ;;
  esac
}

ensure_repo_secret() {
  local token
  if kubectl get secret "$GITEA_TOKEN_SECRET_NAME" -n argocd >/dev/null 2>&1; then
    token=$(kubectl get secret "$GITEA_TOKEN_SECRET_NAME" -n argocd -o jsonpath='{.data.password}' | base64 -d)
  fi

  if [[ -z "$token" ]]; then
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - >/dev/null

    local pod token_name output
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
    add_summary "Created Argo CD repository token"
  else
    printf '[bootstrap] %s\n' "Reusing existing Argo CD repository token" >&2
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

  cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Secret
metadata:
  name: $CHARTS_REPO_SECRET_NAME
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  name: $CHARTS_REPO_NAME
  url: http://gitea-http.gitea.svc.cluster.local:3000/$GITEA_USER/$CHARTS_REPO_NAME.git
  username: $GITEA_USER
  password: $token
EOF

  add_summary "Ensured Argo CD repository secrets"
}

push_repository() {
  local pod tmp_bare repo_parent
  pod=$(get_gitea_pod)
  tmp_bare=$(mktemp -d "$LOG_DIR/agentic-k8s-XXXXXX.git")
  repo_parent="/data/git/gitea-repositories/$GITEA_USER"

  if ! git clone --bare "$REPO_ROOT" "$tmp_bare" >/dev/null 2>&1; then
    log "WARNING: Failed to prepare bare repository for Gitea"
    rm -rf "$tmp_bare"
    return
  fi

  if ! tar -C "$tmp_bare" -cf - . | kubectl exec -i -n gitea -c gitea "$pod" -- bash -c "
    set -euo pipefail
    repo_path=\"$repo_parent/agentic-k8s.git\"
    mkdir -p \"\$(dirname \"\$repo_path\")\"
    rm -rf \"\$repo_path\"
    mkdir -p \"\$repo_path\"
    tar -C \"\$repo_path\" -xf -
    chown -R git:git \"\$repo_path\"
  " >/dev/null 2>&1; then
    log "WARNING: Failed to transfer repository into Gitea"
    rm -rf "$tmp_bare"
    return
  fi

  rm -rf "$tmp_bare"
  add_summary "Pushed repository to local Gitea"
}

create_charts_repo() {
  local pod status
  pod=$(get_gitea_pod)
  status=$(kubectl exec -n gitea -c gitea "$pod" -- \
    curl -sS -o /dev/null -w '%{http_code}' \
      -u "$GITEA_USER:$GITEA_PASSWORD" \
      -H 'Content-Type: application/json' \
      -d '{"name":"'"$CHARTS_REPO_NAME"'","private":false,"default_branch":"main"}' \
      http://127.0.0.1:3000/api/v1/user/repos 2>/dev/null || true)

  if [[ "$status" == "201" ]]; then
    add_summary "Created repository $GITEA_USER/$CHARTS_REPO_NAME in Gitea"
  elif [[ "$status" == "409" ]]; then
    printf '[bootstrap] %s\n' "Repository $GITEA_USER/$CHARTS_REPO_NAME already exists" >&2
  else
    printf '[bootstrap] WARNING: Unexpected response creating $CHARTS_REPO_NAME repository (HTTP %s)\n' "$status" >&2
  fi
}

push_charts_repository() {
  local pod repo_parent tmp_existing tmp_work tmp_bare
  pod=$(get_gitea_pod)
  repo_parent="/data/git/gitea-repositories/$GITEA_USER"
  tmp_existing=$(mktemp -d "$LOG_DIR/$CHARTS_REPO_NAME-existing-XXXXXX.git")
  tmp_work=$(mktemp -d "$LOG_DIR/$CHARTS_REPO_NAME-work-XXXXXX")

  if kubectl exec -n gitea -c gitea "$pod" -- test -d "$repo_parent/$CHARTS_REPO_NAME.git"; then
    if ! kubectl exec -n gitea -c gitea "$pod" -- tar -C "$repo_parent/$CHARTS_REPO_NAME.git" -cf - . | tar -C "$tmp_existing" -xf - >/dev/null 2>&1; then
      log "WARNING: Failed to copy existing $CHARTS_REPO_NAME repository"
      rm -rf "$tmp_existing" "$tmp_work"
      return
    fi
    if ! git clone "$tmp_existing" "$tmp_work" >/dev/null 2>&1; then
      log "WARNING: Failed to clone staged $CHARTS_REPO_NAME repository"
      rm -rf "$tmp_existing" "$tmp_work"
      return
    fi
    pushd "$tmp_work" >/dev/null
    if ! git checkout main >/dev/null 2>&1; then
      log "WARNING: Failed to checkout main branch for $CHARTS_REPO_NAME"
      popd >/dev/null
      rm -rf "$tmp_existing" "$tmp_work"
      return
    fi
  else
    rm -rf "$tmp_existing"
    tmp_existing=""
    pushd "$tmp_work" >/dev/null
    if ! git init >/dev/null 2>&1; then
      log "WARNING: Failed to init $CHARTS_REPO_NAME staging repo"
      popd >/dev/null
      rm -rf "$tmp_work"
      return
    fi
    if ! git checkout -b main >/dev/null 2>&1; then
      log "WARNING: Failed to create main branch for $CHARTS_REPO_NAME"
      popd >/dev/null
      rm -rf "$tmp_work"
      return
    fi
  fi

  rm -rf "$tmp_work/charts"
  if ! tar -C "$REPO_ROOT" -cf - charts | tar -C "$tmp_work" -xf - >/dev/null 2>&1; then
    log "WARNING: Failed to stage charts content for $CHARTS_REPO_NAME"
    popd >/dev/null
    rm -rf "$tmp_existing" "$tmp_work"
    return
  fi

  git config user.name "$GITEA_USER"
  git config user.email "$GITEA_EMAIL"
  git add charts >/dev/null 2>&1

  if git diff --cached --quiet; then
    log "$CHARTS_REPO_NAME already up to date"
    popd >/dev/null
    rm -rf "$tmp_existing" "$tmp_work"
    return
  fi

  if ! git commit -m "Sync charts from bootstrap" >/dev/null 2>&1; then
    log "WARNING: Failed to commit charts content"
    popd >/dev/null
    rm -rf "$tmp_existing" "$tmp_work"
    return
  fi

  if [[ -n "$tmp_existing" ]]; then
    if ! git push origin main >/dev/null 2>&1; then
      log "WARNING: Failed to update staged $CHARTS_REPO_NAME repo"
      popd >/dev/null
      rm -rf "$tmp_existing" "$tmp_work"
      return
    fi
    popd >/dev/null
    tmp_bare="$tmp_existing"
  else
    tmp_bare=$(mktemp -d "$LOG_DIR/$CHARTS_REPO_NAME-XXXXXX.git")
    if ! git clone --bare "$tmp_work" "$tmp_bare" >/dev/null 2>&1; then
      log "WARNING: Failed to create bare $CHARTS_REPO_NAME repo"
      popd >/dev/null
      rm -rf "$tmp_work" "$tmp_bare"
      return
    fi
    popd >/dev/null
  fi

  if ! tar -C "$tmp_bare" -cf - . | kubectl exec -i -n gitea -c gitea "$pod" -- bash -c "
    set -euo pipefail
    repo_path=\"$repo_parent/$CHARTS_REPO_NAME.git\"
    mkdir -p \"\$(dirname \"\$repo_path\")\"
    rm -rf \"\$repo_path\"
    mkdir -p \"\$repo_path\"
    tar -C \"\$repo_path\" -xf -
    chown -R git:git \"\$repo_path\"
  " >/dev/null 2>&1; then
    log "WARNING: Failed to transfer $CHARTS_REPO_NAME into Gitea"
    rm -rf "$tmp_work" "$tmp_bare"
    return
  fi

  rm -rf "$tmp_work" "$tmp_bare"
  add_summary "Synced $CHARTS_REPO_NAME repository to Gitea"
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

  local gitea_pod
  gitea_pod=$(get_gitea_pod)
  ensure_gitea_user "$gitea_pod"

  ensure_repo_secret
  create_gitea_repo
  push_repository
  create_charts_repo
  push_charts_repository

  helm_upgrade argocd charts/argo-cd argocd -f charts/argo-cd/values-local.yaml
  wait_for_deployment argocd argocd-server
  wait_for_deployment argocd argocd-repo-server
  wait_for_statefulset argocd argocd-application-controller || true

  local argocd_password
  argocd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)
  if [[ -n "$argocd_password" ]]; then
    add_summary "Retrieved Argo CD admin credentials"
  else
    argocd_password="<unknown>"
    log "WARNING: Unable to read Argo CD admin password"
  fi

  kubectl apply -f argocd >/dev/null
  wait_for_application gitea || true
  wait_for_application nginx-example || true
  wait_for_application agent || true

  printf '\nBootstrap summary:\n'
  for entry in "${SUMMARY[@]}"; do
    printf ' - %s\n' "$entry"
  done

  printf '\nAccess information:\n'
  printf ' - Gitea UI:      http://gitea-http.gitea.svc.cluster.local:3000/ (credentials %s / %s)\n' "$GITEA_USER" "$GITEA_PASSWORD"
  printf ' - Argo CD UI:    https://argocd-server.argocd.svc.cluster.local/ (admin user)\n'
  printf ' - Argo CD gRPC:  In-cluster service argocd-server.argocd.svc.cluster.local:443\n'
  printf ' - Argo CD admin password: %s\n' "$argocd_password"
  printf ' - NGINX example: http://nginx-example.default.svc.cluster.local/\n'
}

main "$@"
