# Agentic K8S Experiments

## Prerequisites

* a Linux VM (tested with Ubuntu 24.04 as guest OS)
* Docker running in the VM
* an OpenAI API key

## Getting started

```bash
# In the VM run
./cluster/scripts/bootstrap.sh
```

### What Gets Installed?

The bootstrap script (`cluster/scripts/bootstrap.sh`) installs:

- k3s Kubernetes cluster
- kubectl CLI
- helm (Kubernetes package manager)
- k9s (terminal UI for Kubernetes)
- ArgoCD
- Read-only kubeconfig for agentic workflows
- `k8s-agent-root` ArgoCD application (watches `cluster/argocd/manifests/`)


## Experiments

* [Using the LLM python cli to manage ArgoCD manifests](./llm-py/README.md)
* [Playing with MCP server and clients](./mcp/README.md)
