# Zellij Helm Chart

Deploys a single Zellij server intended for shared terminal sessions inside the lab cluster.

## Installation

```bash
helm install zellij charts/zellij
```

## Access

The release exposes a ClusterIP service on TCP port 5555. Adjust the chart values to use `NodePort` or `LoadBalancer` if you need network access beyond the local cluster. When running via the bootstrap script, a port-forward is started automatically.
