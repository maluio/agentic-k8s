# agent Helm Chart

Deploys a lightweight utility Deployment that keeps a Git-ready shell available inside the cluster. The container uses `alpine/git` and boots with credentials pointed at the in-cluster Gitea service so you can clone, pull, and push without additional setup.

## Prerequisites
- Kubernetes cluster (e.g., via `scripts/install-k3s.sh` + `scripts/bootstrap.sh`)
- `kubectl` and Helm configured for the cluster
- Gitea available at the in-cluster hostname (defaults to the bootstrap-provisioned `gitea-http.gitea.svc.cluster.local:3000`)

## Installation
```bash
helm install agent charts/agent --namespace tools --create-namespace
```

## Usage
Open a shell inside the pod:
```bash
kubectl -n tools exec -it deploy/agent -- sh
```
A `.git-credentials` file is pre-populated with the username/password from `values.yaml`, and Git user metadata is configured automatically. Clone the GitOps repository seeded by bootstrap and iterate:

```bash
git clone http://gitea-http.gitea.svc.cluster.local:3000/agentadmin/agentic-k8s-charts.git
cd agentic-k8s-charts
# make chart changes, commit, and push
```

## Configuration
Key values you might override:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of agent pods | `1` |
| `image.repository` | Container image | `alpine/git` |
| `image.tag` | Image tag | `2.49.1` |
| `gitea.host` | Host:port for the in-cluster Gitea HTTP service | `gitea-http.gitea.svc.cluster.local:3000` |
| `gitea.user` | Username written to Git config and credentials helper | `agentadmin` |
| `gitea.password` | Password persisted to `~/.git-credentials` | `agentadmin123!` |
| `gitea.email` | Email used for Git commits | `agentadmin@example.com` |
| `loopMessage` | Log message printed when the pod enters its idle loop | `Agent pod idle. Exec in for Git operations.` |

Apply overrides with a custom values file:
```yaml
gitea:
  user: developer
  password: supersecret
```

Install with:
```bash
helm install agent charts/agent --namespace tools -f my-values.yaml
```

## Uninstall
```bash
helm uninstall agent --namespace tools
```
