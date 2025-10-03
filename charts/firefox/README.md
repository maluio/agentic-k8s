# Firefox Helm Chart

Packages the `jlesage/firefox` container to provide a browser UI reachable through the cluster. A companion sidecar serves a lightweight HTML landing page of useful links, and Firefox is configured to open it on startup.

## Installation

```bash
helm install firefox charts/firefox
```

## Access

The chart exposes a web UI (noVNC) on port 5800. When installed through the project bootstrap, a port-forward is created so you can browse to `http://127.0.0.1:5801/`. The default credentials use the VNC password defined in `values.yaml` (defaults to `firefox`).

Each session opens a dashboard served by the `firefox-dashboard` sidecar inside the pod. The default configuration enumerates the URLs exposed by the bootstrap script using in-cluster service hostnames so the remote browser can connect without additional tunnels. Bootstrap passes the current Argo CD admin password via the `dashboard.argoCdPassword` value so the page highlights it next to the login instructions, complete with a copy-to-clipboard button to avoid whitespace issues; if you rotate the password, rerun bootstrap (or supply an override values file) so the dashboard stays in sync. Customize the entries by overriding the `dashboard.links` array in `values.yaml` (each entry provides `name`, `url`, and `description` fields). The `dashboard` block also lets you change the title text, description, sidecar image, listening port, and the displayed password if you need different content or tooling.
