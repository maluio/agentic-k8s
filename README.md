# Agentic K8S Experiment

An experiment to manage a Kubernetes cluster through a llm chat interface.

* The bootstrap scripts install ...
  * a k3s single node Kubernetes "cluster"
  * ArgoCD running in that cluster
  * A `k8s-agent-root` ArgoCD application that manages child applications
* The docker compose setup runs the [LLM cli tool](https://llm.datasette.io/en/stable/index.html) in a container
  * users manage ArgoCD child application throughs `llm chat` or `llm prompt`

## Prerequisites

* a Linux VM (tested with Ubuntu 24.04 as guest os)
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
- ArgoCD
- Read-only kubeconfig for agent workflows
- `k8s-agent-root` ArgoCD application (watches `agent/manifests/`)

## Usage

### Start the Agent Container

```bash
export OPENAI_API_KEY=<your key>
docker compose up -d
docker compose exec agent bash
```

### Use LLM to Manage K8S

Inside the container, use the `llm` command with the k8s.py functions:

```bash
# Use the k8s-agent template and funtions, set chain-limit to unlimit tool calls
llm chat -t k8s-agent --functions agent/llm_tools/k8s.py --chain-limit 0
```

A chat prompt starts. You can now prompt to make changes to the cluster.

```bash
root@dev:/workspace# llm chat -t k8s-agent --functions agent/llm_tools/k8s.py --chain-limit 0
Chatting with gpt-5
Type 'exit' or 'quit' to exit
Type '!multi' to enter multiple lines, then '!end' to finish
Type '!edit' to open your default editor and modify the prompt
Type '!fragment <my_fragment> [<another_fragment> ...]' to insert one or more fragments
> what's the state?
Here’s the current ArgoCD application state:

- k8s-agent-root: Synced, Healthy
- nginx-example: Synced, Degraded (rev 15.14.1)
- nginx-example-2: Synced, Degraded (rev 15.14.1)
- postgresql: Synced, Progressing (rev 15.5.0)

Want me to pull details on why nginx-example/nginx-example-2 are Degraded or which resources in postgresql are still progressing?
```