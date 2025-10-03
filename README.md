# agentic-k8s

A lab to research agentic k8s

## Local Kubernetes Setup

Use the helper scripts under `scripts/` to bootstrap a local Kubernetes environment for development.

### Install K3s

The project standardizes on [K3s](https://k3s.io/) for local clusters.

**Prerequisites**
- Linux host with `systemd`
- Supported CPU (`x86_64` or `arm64/aarch64`)
- `curl` available on the PATH
- Root access (`sudo`)

**Install / Upgrade**

```bash
sudo ./scripts/install-k3s.sh
```

The script downloads the official K3s installer, ensures the `k3s` service is running, and syncs the kubeconfig to the invoking user (default: `~/.kube/config`). After the run, export the kubeconfig and verify the cluster:

```bash
export KUBECONFIG=$HOME/.kube/config
k3s kubectl get nodes
```

You can safely re-run the script to upgrade to a newer channel/version by setting `K3S_CHANNEL` or `K3S_VERSION` environment variables before invocation.

**Uninstall**

To remove the local cluster, use the cleanup script that K3s installs:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

This stops the service and removes binaries, data directories, and kubeconfig.

### Install kubectl

Install the Kubernetes CLI that matches the project target version, then verify connectivity to the local cluster provisioned by the K3s script.

**Prerequisites**
- `curl`
- Local kubeconfig (default: `~/.kube/config` created by the K3s installer)
- Write access to the target install directory (default requires `sudo`)

**Install / Upgrade**

```bash
sudo ./scripts/install-kubectl.sh
```

The script downloads the pinned kubectl release (`v1.30.3` by default), places it under `/usr/local/bin`, and runs `kubectl get nodes` with your kubeconfig to ensure the CLI can reach the cluster.

Customize behavior with environment variables:

- `KUBECTL_VERSION` (e.g., `v1.29.6`) to install a different release
- `KUBECTL_INSTALL_DIR` to install somewhere writable without sudo
- `KUBECONFIG` to point at a non-default kubeconfig before the verification step

If connectivity fails, confirm the local K3s cluster is running (`sudo systemctl status k3s`) and that your kubeconfig points to the right endpoint.

### Install Helm

Install the Helm CLI so you can package and deploy charts to the local Kubernetes cluster.

**Prerequisites**
- `curl` and `tar`
- Write access to the target install directory (default requires `sudo`)

**Install / Upgrade**

```bash
sudo ./scripts/install-helm.sh
```

The script downloads the pinned Helm release (`v3.15.2` by default), puts the binary under `/usr/local/bin`, and verifies the reported version matches the expected release.

Customize via environment variables:

- `HELM_VERSION` (e.g., `v3.14.4`) to install a different release
- `HELM_INSTALL_DIR` to install Helm into an alternate writable directory without sudo

If you see version mismatches, ensure the requested version exists on [get.helm.sh](https://get.helm.sh/) and that your PATH does not resolve to a different Helm binary.

### Deploy the NGINX Example Chart

With the local cluster and tooling ready, install the sample chart located in `charts/nginx-example`:

```bash
helm install nginx-example charts/nginx-example
```

Verify the release and expose it locally:

```bash
kubectl get pods -l app.kubernetes.io/instance=nginx-example
kubectl get svc nginx-example
kubectl port-forward svc/nginx-example 8081:80
# open http://127.0.0.1:8081/
```

See `charts/nginx-example/README.md` for configuration options and uninstall instructions.

### One-Shot Bootstrap

To provision a fresh developer environment—including K3s, kubectl, Helm, the vendored charts, Argo CD applications, and the standard port-forwards—run the bundled bootstrap script from the repo root:

```bash
./scripts/bootstrap.sh
```

The script is idempotent: rerunning it will skip components that are already installed, redeploy Helm releases as needed, ensure Argo CD is configured, and restart any missing port-forwards. A summary is printed at the end listing what was installed or reused along with:

- Gitea URL (`http://127.0.0.1:8090/`) and seeded credentials (`agentadmin / agentadmin123!`)
- Argo CD UI (`http://127.0.0.1:8093/`), gRPC endpoint (`https://127.0.0.1:8083/`), and the current admin password sourced from the cluster secret
- NGINX example ingress via `http://127.0.0.1:8081/`

Port-forward logs are written to `${TMPDIR:-/tmp}/agentic-k8s`. Because the bootstrap touches K3s, you may be prompted for `sudo` privileges during the first run.
