# agentic-k8s

Agentic Kubernetes lab experiments live here. The repository focuses on delivering a reproducible local environment that mirrors the project’s tooling in a single bootstrap.

## Bootstrap the Environment

```bash
./scripts/bootstrap.sh
```

Running the script on a Linux host with `systemd` provisions everything this lab expects. The bootstrap is idempotent—reruns skip work that’s already complete and refresh Helm releases. You may be prompted for `sudo` to install K3s.

After the script completes it prints:
- Gitea credentials (`agentadmin / agentadmin123!`) for use from in-cluster workflows
- Argo CD access details (the admin password is surfaced directly in the summary so you can sign in immediately)
- Confirmation that the sample nginx deployment is ready inside the cluster

### Reset the Cluster

Need a clean slate? Run:

```bash
./scripts/reset.sh
```

The helper uninstalls K3s and removes your local `~/.kube/config` copy so the next bootstrap starts from scratch. You may be prompted for `sudo` to complete the reset.

## What Bootstrap Installs

- [K3s](https://k3s.io/) single-node Kubernetes cluster
- Pinned `kubectl` and `helm` CLIs
- Local [Gitea](https://gitea.com/) instance with this repository pushed and an admin user seeded
- [Argo CD](https://argo-cd.readthedocs.io/) plus Applications that track the vendored charts
- Sample `nginx-example` Helm chart deployment for quick smoke tests
- A long-running `agent` utility pod equipped with Git and preloaded Gitea credentials for in-cluster workflows
- A dedicated `agentic-k8s-charts` GitOps repository inside Gitea that Argo CD watches for chart updates

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

Argo CD automatically reconciles the Applications after the push. Watch the status with `kubectl -n argocd get applications.argoproj.io` or the Argo CD CLI/HTTP endpoint. If you override the Gitea credentials when installing the chart, the pod regenerates the Git configuration on restart, so exec back in after an upgrade or rollout to pick up the new values.

### Accessing service endpoints

Bootstrap now focuses on in-cluster workflows. Services expose cluster DNS names such as `http://gitea-http.gitea.svc.cluster.local:3000/` and `https://argocd-server.argocd.svc.cluster.local/`. Use the `agent` pod (or another in-cluster workload) to interact with those URLs directly. If you need local workstation access, layer on your preferred exposure mechanism (for example, create a temporary `kubectl port-forward` or configure a NodePort/Ingress in your own values override).
