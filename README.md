# Agentic k8s

LLM-powered GitOps workflow for Kubernetes using ArgoCD. An LLM agent manages ArgoCD application manifests by writing them to the repository, automatically committing and pushing changes for manual sync.

## What Gets Installed

The bootstrap script (`cluster/scripts/bootstrap.sh`) installs:

- k3s Kubernetes cluster
- kubectl CLI
- ArgoCD
- Read-only kubeconfig for agent workflows
- `k8s-agent-root` ArgoCD application (watches `agent/manifests/`)

## Usage

### Start the Agent Container

```bash
docker compose up -d
docker compose exec agent bash
```

### Use LLM to Manage ArgoCD Manifests

Inside the container, use the `llm` command with the k8s.py functions:

```bash

# Use the k8s-agent template and funtions, set chain-limit to unlimit tool calls
llm chat -t k8s-agent --functions agent/llm_tools/k8s.py --chain-limit 0
```

The `write_argocd` function automatically:
1. Writes the manifest to `agent/manifests/{app-name}.yaml`
2. Commits the change with message: "Add/update ArgoCD manifest for {app-name}"
3. Pushes to the repository
4. ArgoCD detects the change (manual sync required)

### Available Functions

- `kubectl(command)` - Run kubectl commands
- `read_argocd(app_name)` - Read manifest from agent/manifests/
- `write_argocd(manifest_content)` - Write manifest, commit, and push

## Architecture

```
LLM Agent → write_argocd() → agent/manifests/*.yaml → git commit/push → GitHub
                                                                           ↓
                                                    ArgoCD ← k8s-agent-root App
                                                      ↓
                                                   Kubernetes Cluster
```

ArgoCD's `k8s-agent-root` application uses **manual sync policy**, giving you control over when changes are applied to the cluster.
