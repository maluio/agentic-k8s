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
