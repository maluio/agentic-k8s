# agentic-k8s

Agentic Kubernetes lab experiments live here. The repository focuses on delivering a reproducible local environment that mirrors the project’s tooling in a single bootstrap.

## Bootstrap the Environment

```bash
./scripts/bootstrap.sh
```

Running the script on a Linux host with `systemd` provisions everything this lab expects. The bootstrap is idempotent—reruns skip work that’s already complete, refresh Helm releases, and restart any missing port-forwards. You may be prompted for `sudo` to install K3s.

After the script completes it prints:
- URLs and credentials for Gitea (`http://127.0.0.1:8090/`, `agentadmin / agentadmin123!`)
- Argo CD access points (`http://127.0.0.1:8093/`, `https://127.0.0.1:8083/`) and the current admin password
- Confirmation that the sample nginx deployment is reachable at `http://127.0.0.1:8081/`
- A Firefox browser UI at `http://127.0.0.1:5801/` (password `firefox`)

Port-forward logs are written to `${TMPDIR:-/tmp}/agentic-k8s` so you can inspect them if a tunnel drops (for example when coordinating with Tailscale Serve).

## What Bootstrap Installs

- [K3s](https://k3s.io/) single-node Kubernetes cluster
- Pinned `kubectl` and `helm` CLIs
- Local [Gitea](https://gitea.com/) instance with this repository pushed and an admin user seeded
- [Argo CD](https://argo-cd.readthedocs.io/) plus Applications that track the vendored charts
- Sample `nginx-example` Helm chart deployment for quick smoke tests
- Browser UI (Firefox via jlesage) for accessing cluster services
- Standard port-forwards for Gitea (8090), Argo CD HTTP (8093) and gRPC (8083), the nginx service (8081), and Firefox (5801)

That’s the entirety of the workflow—clone the repo, run `./scripts/bootstrap.sh`, and start building on the local cluster.
