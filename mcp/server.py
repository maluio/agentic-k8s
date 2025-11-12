#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.12"
# dependencies = ["mcp[cli]", "kubernetes"]
# ///

# From https://modelcontextprotocol.io/docs/develop/build-server

from typing import Any
from mcp.server.fastmcp import FastMCP
from kubernetes import client, config
import json

# Initialize FastMCP server
mcp = FastMCP("kubernetes")

@mcp.tool()
async def get_pods(namespace: str) -> str:
    """Get pods for a given namespace.

    Args:
        namespace: The Kubernetes namespace
    """
    try:
        # Load kubernetes configuration
        config.load_kube_config()

        # Create API client
        v1 = client.CoreV1Api()

        # List pods in the namespace
        pods = v1.list_namespaced_pod(namespace=namespace)

        # Format the response
        pod_list = []
        for pod in pods.items:
            pod_info = {
                "name": pod.metadata.name,
                "namespace": pod.metadata.namespace,
                "status": pod.status.phase,
                "ip": pod.status.pod_ip,
                "node": pod.spec.node_name,
                "containers": [
                    {
                        "name": container.name,
                        "image": container.image,
                        "ready": any(
                            cs.name == container.name and cs.ready
                            for cs in (pod.status.container_statuses or [])
                        )
                    }
                    for container in pod.spec.containers
                ]
            }
            pod_list.append(pod_info)

        return json.dumps(pod_list, indent=2)

    except Exception as e:
        return f"Error getting pods: {str(e)}"

def main():
    # Initialize and run the server
    mcp.run(transport='stdio')

if __name__ == "__main__":
    main()
