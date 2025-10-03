# agentic-k8s

Agentic Kubernetes lab experiments live here. The repository focuses on delivering a reproducible local environment that mirrors the project’s tooling in a single bootstrap.

## Bootstrap the Environment

```bash
./scripts/bootstrap.sh
```

Running the script on a Linux host with `systemd` provisions everything this lab expects. The bootstrap is idempotent—reruns skip work that’s already complete, refresh Helm releases, and restart the Firefox port-forward if needed. You may be prompted for `sudo` to install K3s.

After the script completes it prints:
- Gitea credentials (`agentadmin / agentadmin123!`) for use via the Firefox landing page
- Argo CD access details and the current admin password (reach it through the Firefox landing page or a manual port-forward if you prefer)
- Confirmation that the sample nginx deployment is ready inside the cluster
- A Firefox browser UI at `http://127.0.0.1:5801/` (password `firefox`) that opens a landing page of cluster links

Port-forward logs are written to `${TMPDIR:-/tmp}/agentic-k8s` so you can inspect them if the Firefox tunnel drops (for example when coordinating with Tailscale Serve).

## What Bootstrap Installs

- [K3s](https://k3s.io/) single-node Kubernetes cluster
- Pinned `kubectl` and `helm` CLIs
- Local [Gitea](https://gitea.com/) instance with this repository pushed and an admin user seeded
- [Argo CD](https://argo-cd.readthedocs.io/) plus Applications that track the vendored charts
- Sample `nginx-example` Helm chart deployment for quick smoke tests
- Browser UI (Firefox via jlesage) for accessing cluster services, including a sidecar-served landing page of useful links
- Firefox port-forward for the remote browser experience (other services are reachable via in-cluster DNS from that browser)

That’s the entirety of the workflow—clone the repo, run `./scripts/bootstrap.sh`, and start building on the local cluster.

### Firefox landing page

The Firefox chart now ships with a sidecar that serves a lightweight HTML dashboard listing the endpoints the bootstrap process exposes (Gitea, Argo CD HTTP/gRPC, nginx example, Firefox, and any additional links you add). The default entries use in-cluster service hostnames so the remote Firefox session can reach them without port-forwards, and the Argo CD tile includes the admin login hint plus the command to retrieve the current password. The Firefox container is configured with `FF_OPEN_URL` so each browser session opens the dashboard first.

To customize the page, supply your own values file when installing or updating the chart and override the `dashboard.links` array (each item supports `name`, `url`, and `description`). Use cluster DNS names for services you plan to open from the remote browser, or swap to port-forwarded URLs if you prefer to open them locally. You can also tweak the title, description text, and the sidecar image/port through the `dashboard` block. Example:

```bash
helm upgrade --install firefox charts/firefox \
  --namespace tools \
  --values charts/firefox/values.yaml \
  --set dashboard.links[0].url=http://127.0.0.1:3000/
```
