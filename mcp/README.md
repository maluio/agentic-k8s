# MCP Experiments

## Option 1: Use the custom MCP server (server.py)

### Using the custom client (client.py)

```bash
uv run mcp/client.py mcp/server.py
```

Example output:

```bash
$ uv run mcp/client.py mcp/server.py
[11/12/25 10:02:07] INFO     Processing request of type ListToolsRequest server.py:674

Connected to server with tools: ['get_pods']

MCP Client Started!
Type your queries or 'quit' to exit.

Query: which pods are running in the kube-system namespace?
[11/12/25 10:02:30] INFO     Processing request of type ListToolsRequest server.py:674
[11/12/25 10:02:33] INFO     Processing request of type CallToolRequest server.py:674

[Calling tool get_pods with args {'namespace': 'kube-system'}]
The following pods are running in the `kube-system` namespace:

1. `coredns-64fd4b4794-5zlq6`
   - Status: Running
   - IP: 10.42.0.32
   - Node: lima-agentic-k8s

2. `local-path-provisioner-774c6665dc-bj6rm`
   - Status: Running
   - IP: 10.42.0.37
   - Node: lima-agentic-k8s

3. `metrics-server-7bfffcd44-9bcfj`
   - Status: Running
   - IP: 10.42.0.38
   - Node: lima-agentic-k8s

4. `svclb-traefik-1a05b14a-sf9kh`
   - Status: Running
   - IP: 10.42.0.29
   - Node: lima-agentic-k8s

5. `traefik-c98fdf6fb-lrks4`
   - Status: Running
   - IP: 10.42.0.30
   - Node: lima-agentic-k8s

Additionally, there are two more pods which have already succeeded:

- `helm-install-traefik-crd-zthtv`: Status - Succeeded
- `helm-install-traefik-rscmt`: Status - Succeeded
```

### Using Claude Code as MCP client

```bash
claude mcp add --transport stdio kubernetes -- uv run $(pwd)/mcp/server.py
```

There is a helper script to reset Claude Code's MCP config:

```bash
./mcp/helper.py claude-reset-mcp
```

## Option 2: Connect (via SSH) to Kubernetes MCP Server

[Kubernetes MCP Server](https://github.com/containers/kubernetes-mcp-server) can be run in several ways, we run it via `uv`:

```bash
uvx kubernetes-mcp-server
```

### Using Claude Desktop as MCP client

[Claude's docs on how to connect to a local server](https://modelcontextprotocol.io/docs/develop/connect-local-servers)

This config connects Claude Desktop to the VM via SSH, runs the MCP server in STDIO mode via uv's uvx:

```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "ssh",
      "args": [
        "user@vm",
        "uvx",
        "kubernetes-mcp-server"
      ]
    }
  }
}
```

![Claude Desktop connected to Kubernetes MCP Server via SSH](claude_desktop.png)

#### Why via SSH?

Kubernetes MCP Server supports running as a remote server but it's cumbersome to connect Claude Desktop to a MCP.

#### Follow logs in real-time

```bash
# With Claude Desktop running on MacOS
tail -n 20 -F ~/Library/Logs/Claude/mcp*.log
```

### Using Claude Code as MCP client

```bash
claude mcp add --scope project --transport stdio kubernetes -- uvx kubernetes-mcp-server
```