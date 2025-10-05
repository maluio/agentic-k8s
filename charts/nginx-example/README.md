# nginx-example Helm Chart

This chart deploys a minimal NGINX Deployment and Service that can be used to validate a local Kubernetes environment.

## Prerequisites
- Kubernetes cluster (e.g., via `scripts/install-k3s.sh`)
- `kubectl` configured for the cluster
- Helm CLI installed (`scripts/install-helm.sh`)

## Installation
```bash
helm install nginx-example charts/nginx-example
```

## Verification
```bash
kubectl get pods -l app.kubernetes.io/instance=nginx-example
kubectl get svc nginx-example
```

To test HTTP access from your workstation without relying on port-forwarding, install the chart with a NodePort service (for example `--set service.type=NodePort`). After deployment, run `kubectl get svc nginx-example -o wide` to see the allocated NodePort, then browse to `http://<node-ip>:<node-port>/`.

## Configuration
Common parameters that can be overridden with `--set` or a custom `values.yaml`:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of NGINX replicas | `1` |
| `image.repository` | Container image repository | `nginx` |
| `image.tag` | Container image tag (defaults to chart appVersion) | `""` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port exposed by Service | `80` |
| `containerPort` | Container port exposed by NGINX | `80` |

Example override file:
```yaml
replicaCount: 2
service:
  type: NodePort
  port: 8080
```
Apply with:
```bash
helm install nginx-example charts/nginx-example -f my-values.yaml
```

## Uninstall
```bash
helm uninstall nginx-example
```
