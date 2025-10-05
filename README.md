# agentic-k8s

Agentic Kubernetes lab experiments live here. The repository focuses on delivering a reproducible local environment that mirrors the project’s tooling in a single bootstrap.

## Bootstrap the Environment

```bash
./scripts/bootstrap.sh
```

Running the script on a Linux host with `systemd` provisions everything this lab expects. The bootstrap is idempotent—reruns skip work that’s already complete, refresh Helm releases, and keep the Firefox NodePort service configured. You may be prompted for `sudo` to install K3s.

After the script completes it prints:
- Gitea credentials (`agentadmin / agentadmin123!`) for use via the Firefox landing page
- Argo CD access details (the admin password is surfaced directly on the Firefox landing page so you can sign in immediately)
- Confirmation that the sample nginx deployment is ready inside the cluster
- A Firefox browser UI reachable on the NodePort the script prints (default `http://127.0.0.1:30800/`, password `firefox`) that opens a landing page of cluster links

Firefox no longer relies on `kubectl port-forward`; the service is exposed via a dedicated NodePort so reconnecting only requires browsing to the printed address.

## What Bootstrap Installs

- [K3s](https://k3s.io/) single-node Kubernetes cluster
- Pinned `kubectl` and `helm` CLIs
- Local [Gitea](https://gitea.com/) instance with this repository pushed and an admin user seeded
- [Argo CD](https://argo-cd.readthedocs.io/) plus Applications that track the vendored charts
- Sample `nginx-example` Helm chart deployment for quick smoke tests
- A long-running `agent` utility pod equipped with Git and preloaded Gitea credentials for in-cluster workflows
- A dedicated `agentic-k8s-charts` GitOps repository inside Gitea that Argo CD watches for chart updates
- Browser UI (Firefox via jlesage) for accessing cluster services, including a sidecar-served landing page of useful links
- Firefox NodePort service for the remote browser experience (other services are reachable via in-cluster DNS from that browser)

That’s the entirety of the workflow—clone the repo, run `./scripts/bootstrap.sh`, and start building on the local cluster.

### Agent Git workspace

Need a shell inside the cluster with Git ready to talk to Gitea? Rely on the `agent` Deployment that ships with bootstrap:

```bash
kubectl -n tools exec -it deploy/agent -- sh
```

The container configures `git config --global` on start-up and writes a credential helper entry that points at `gitea-http.gitea.svc.cluster.local:3000` using the `agentadmin / agentadmin123!` account. That means you can immediately clone, pull, and push HTTP remotes without manually entering credentials.

### GitOps chart updates

Argo CD now tracks the `agentic-k8s-charts` repository that bootstrap seeds inside Gitea. To ship a chart tweak from the in-cluster agent pod:

```bash
# Inside the agent shell
cd /tmp
git clone http://gitea-http.gitea.svc.cluster.local:3000/agentadmin/agentic-k8s-charts.git
cd agentic-k8s-charts
# edit the charts/ tree (for example bump the agent image tag)
git status
git commit -am "Describe your change"
git push
```

Argo CD automatically reconciles the Applications after the push. Watch the status with `kubectl -n argocd get applications.argoproj.io` or use the Firefox dashboard link. If you override the Gitea credentials when installing the chart, the pod regenerates the Git configuration on restart, so exec back in after an upgrade or rollout to pick up the new values.

### Firefox landing page

The Firefox chart now ships with a sidecar that serves a lightweight HTML dashboard listing the endpoints the bootstrap process exposes (Gitea, Argo CD HTTP/gRPC, nginx example, Firefox, and any additional links you add). The default entries use in-cluster service hostnames so the remote Firefox session can reach them without port-forwards. Bootstrap also reads the Argo CD admin password and injects it into the dashboard so you can log in immediately; a copy-to-clipboard button avoids stray whitespace when you grab the value, and the tile still links the kubectl command in case you rotate the secret manually. The Firefox container is configured with `FF_OPEN_URL` so each browser session opens the dashboard first.

To customize the page, supply your own values file when installing or updating the chart and override the `dashboard.links` array (each item supports `name`, `url`, and `description`). Use cluster DNS names for services you plan to open from the remote browser, or swap to NodePort or ingress URLs if you prefer to open them locally. You can also tweak the title, description text, and the sidecar image/port through the `dashboard` block. Example:

```bash
helm upgrade --install firefox charts/firefox \
  --namespace tools \
  --values charts/firefox/values.yaml \
  --set dashboard.links[0].url=http://127.0.0.1:3000/
```

> Security note: The Argo CD password is displayed inside the cluster-bound Firefox session and the local NodePort that exposes it. That matches the assumptions for this single-user lab environment. If you rotate the password (for example with `kubectl -n argocd delete secret argocd-initial-admin-secret`) rerun `./scripts/bootstrap.sh` so the dashboard reflects the new value.
