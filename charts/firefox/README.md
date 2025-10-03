# Firefox Helm Chart

Packages the `jlesage/firefox` container to provide a browser UI reachable through the cluster.

## Installation

```bash
helm install firefox charts/firefox
```

## Access

The chart exposes a web UI (noVNC) on port 5800. When installed through the project bootstrap, a port-forward is created so you can browse to `http://127.0.0.1:5801/`. The default credentials use the VNC password defined in `values.yaml` (defaults to `firefox`).
