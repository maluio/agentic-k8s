# agentic-k8s

This repository provides a minimal bootstrap for experimenting with Kubernetes automation. The `bootstrap.sh` script provisions a local single-node K3s cluster and installs Argo CD using the official upstream manifests so you can deploy GitOps experiments immediately.

## Bootstrap the Environment

```bash
./scripts/bootstrap.sh
```

The script assumes a Linux host with `systemd`. It is idempotent—rerunning the bootstrap will reinstall any missing prerequisites and reapply the Argo CD manifests. You may be prompted for `sudo` while K3s is installed or restarted.

After the script completes it prints:
- Whether K3s or kubectl were installed or reused
- Confirmation that the Argo CD components reached a healthy state
- The Argo CD admin password and a suggested port-forward command for logging in locally
- The filesystem path to an `agent/kubeconfig` file with read-only credentials

### Reset the Cluster

Need a clean slate? Run:

```bash
./scripts/reset.sh
```

The helper removes K3s from the node (using the standard `k3s-killall.sh`/`k3s-uninstall.sh` scripts) and deletes your local `~/.kube/config` copy so the next bootstrap starts fresh. You may be prompted for `sudo` during the reset.

## What Bootstrap Installs

- [K3s](https://k3s.io/) single-node Kubernetes cluster
- Pinned `kubectl` CLI (if it is not already on your PATH)
- [Argo CD](https://argo-cd.readthedocs.io/) installed via the upstream `install.yaml`

That’s the entirety of the workflow—clone the repo, run `./scripts/bootstrap.sh`, and start deploying workloads with Argo CD.

### Accessing Argo CD

The bootstrap script patches the `argocd-server` Service to `NodePort`, defaulting the HTTPS endpoint to `32443`. After the summary prints the node IP you can browse directly to `https://<node-ip>:32443` and sign in with user `admin` and the password reported in the output (or retrieved manually with `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`).

Want to confirm the assigned port or the node IP? Run:

```bash
kubectl -n argocd get svc argocd-server -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}'
kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
```

If you prefer a local tunnel instead, you can still port-forward the service:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

From there you can add your own Git repositories and Application definitions directly through the Argo CD UI or CLI.

### Accessing Gitea

Bootstrap now deploys Gitea via Argo CD using the upstream Gitea Helm chart configured for SQLite and exposes the HTTP service on NodePort `32330`. Once bootstrap finishes, use the printed node IP to reach `http://<node-ip>:32330`. To double-check the port or IP, run:

```bash
kubectl -n gitea get svc gitea-http -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}'
kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
```

The bootstrap config seeds an admin account (`bn_user` / `changeme`) for first-time access. You can update the password from the web UI once logged in.

### Agent Kubeconfig

The bootstrap script writes a read-only kubeconfig to `agent/kubeconfig`. Use this configuration when you need to grant automation (or a human operator) inspect-only access to the cluster without risking mutating changes. The credentials are bound to a Kubernetes service account mapped to the built-in `view` ClusterRole.
