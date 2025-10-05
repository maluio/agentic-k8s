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

By default the Argo CD server is exposed inside the cluster. To reach the UI from your workstation, port-forward the service:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Then open `https://localhost:8080` in your browser and sign in with user `admin` and the password printed in the bootstrap summary (you can also retrieve it manually with `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`).

From there you can add your own Git repositories and Application definitions directly through the Argo CD UI or CLI.
