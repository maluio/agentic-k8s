"""LLM tool functions for interacting with kubectl.

Expose these functions with the llm CLI by passing:

    llm --functions tools/kubectl_llm.py "..."

The kubectl() function is designed to be safe to call from models: it accepts a
string of kubectl arguments, runs the command and returns stdout/stderr.  It
never prompts for interactive input and reports failures in the returned text
so the model can react accordingly.
"""

import shlex
import subprocess
from pathlib import Path

import yaml
def kubectl(
    command: str,
    namespace: str | None = None,
    context: str | None = None,
    timeout: float | None = None,
) -> str:
    """Run ``kubectl`` with the supplied arguments and return the output.

    Parameters
    ----------
    command:
        The kubectl arguments, e.g. ``"get pods"`` or ``"describe pod my-pod"``.
    namespace:
        Optional namespace to target (adds ``--namespace`` automatically).
    context:
        Optional kubeconfig context (adds ``--context`` automatically).
    timeout:
        Optional timeout (seconds) for the kubectl invocation.

    Returns
    -------
    str
        Combined stdout and stderr from the kubectl invocation. Non-zero exit
        codes are included in the returned text so the model sees the failure
        message instead of raising an exception.
    """

    base_cmd = ["kubectl"]
    if context:
        base_cmd.extend(["--context", context])
    if namespace:
        base_cmd.extend(["--namespace", namespace])

    try:
        extra_args = shlex.split(command)
    except ValueError as exc:
        return f"Failed to parse command '{command}': {exc}"

    full_cmd = base_cmd + extra_args

    try:
        completed = subprocess.run(
            full_cmd,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except FileNotFoundError:
        return "kubectl executable not found on PATH."
    except subprocess.TimeoutExpired:
        return (
            "kubectl command timed out after"
            f" {timeout} seconds: {' '.join(full_cmd)}"
        )

    output_parts = []
    if completed.stdout:
        output_parts.append(completed.stdout.strip())
    if completed.stderr:
        output_parts.append(completed.stderr.strip())

    if completed.returncode != 0:
        output_parts.append(
            f"kubectl exited with status {completed.returncode}: {' '.join(full_cmd)}"
        )

    return "\n".join(part for part in output_parts if part) or "(no output)"


def read_argocd(argocd_app_name: str) -> str:
    """Read an ArgoCD application manifest from the agent/manifests directory.

    This function reads ArgoCD application YAML files stored locally in the
    agent/manifests directory. The naming convention is that the ArgoCD
    application name corresponds directly to the YAML filename.

    Parameters
    ----------
    argocd_app_name:
        The name of the ArgoCD application. This should match the filename
        (without extension) in agent/manifests/. For example, if the app name
        is "nginx-example", the function will look for either
        "nginx-example.yaml" or "nginx-example.yml".

    Returns
    -------
    str
        The contents of the YAML manifest file, or an error message if the
        file is not found or cannot be read.

    Examples
    --------
    >>> read_argocd("nginx-example")
    'apiVersion: argoproj.io/v1alpha1\\nkind: Application\\n...'

    >>> read_argocd("non-existent-app")
    'ArgoCD manifest not found: non-existent-app...'
    """
    # This function runs inside the agent Docker container where paths are predictable
    # The manifests directory is always at /workspace/agent/manifests
    manifests_dir = Path("/workspace/agent/manifests")

    if not manifests_dir.exists():
        return (
            f"Manifests directory not found at {manifests_dir}. "
            f"Ensure the container has the correct volume mounts."
        )

    # Try both .yaml and .yml extensions
    for extension in [".yaml", ".yml"]:
        manifest_path = manifests_dir / f"{argocd_app_name}{extension}"
        if manifest_path.exists():
            try:
                return manifest_path.read_text()
            except OSError as exc:
                return f"Failed to read ArgoCD manifest '{argocd_app_name}': {exc}"

    # If we get here, the file wasn't found with either extension
    return (
        f"ArgoCD manifest not found: {argocd_app_name}\n"
        f"Looked for {argocd_app_name}.yaml or {argocd_app_name}.yml in {manifests_dir}"
    )


def write_argocd(manifest_content: str) -> str:
    """Write an ArgoCD application manifest to the agent/manifests directory.

    This function writes ArgoCD application YAML manifests to the local
    agent/manifests directory. It parses the YAML to extract the application
    name from metadata.name and uses that as the filename.

    Parameters
    ----------
    manifest_content:
        The complete YAML content of the ArgoCD application manifest as a
        string. Must be valid YAML with metadata.name field.

    Returns
    -------
    str
        Success message with the written filename, or an error message if
        the write operation fails or the YAML is invalid.

    Examples
    --------
    >>> manifest = '''
    ... apiVersion: argoproj.io/v1alpha1
    ... kind: Application
    ... metadata:
    ...   name: my-app
    ...   namespace: argocd
    ... spec:
    ...   project: default
    ... '''
    >>> write_argocd(manifest)
    'Successfully wrote ArgoCD manifest to my-app.yaml'

    >>> write_argocd("invalid: yaml: content:")
    'Failed to parse YAML manifest: ...'
    """
    # This function runs inside the agent Docker container where paths are predictable
    # The manifests directory is always at /workspace/agent/manifests
    manifests_dir = Path("/workspace/agent/manifests")

    if not manifests_dir.exists():
        return (
            f"Manifests directory not found at {manifests_dir}. "
            f"Ensure the container has the correct volume mounts."
        )

    # Parse and validate the YAML
    try:
        manifest_data = yaml.safe_load(manifest_content)
    except yaml.YAMLError as exc:
        return f"Failed to parse YAML manifest: {exc}"

    # Validate that it's a dict with metadata
    if not isinstance(manifest_data, dict):
        return "Invalid manifest: YAML must be a dictionary/object"

    if "metadata" not in manifest_data:
        return "Invalid manifest: missing 'metadata' field"

    if not isinstance(manifest_data["metadata"], dict):
        return "Invalid manifest: 'metadata' must be a dictionary/object"

    if "name" not in manifest_data["metadata"]:
        return "Invalid manifest: missing 'metadata.name' field"

    # Extract the application name
    app_name = manifest_data["metadata"]["name"]
    if not app_name or not isinstance(app_name, str):
        return f"Invalid manifest: 'metadata.name' must be a non-empty string, got: {app_name}"

    # Sanitize the filename (remove path separators and other unsafe characters)
    safe_app_name = app_name.replace("/", "-").replace("\\", "-").replace("..", "")
    if safe_app_name != app_name:
        return (
            f"Invalid application name '{app_name}': "
            f"name contains unsafe characters. Use alphanumeric, dash, or underscore only."
        )

    # Write the manifest file
    manifest_path = manifests_dir / f"{safe_app_name}.yaml"
    try:
        manifest_path.write_text(manifest_content)
        return f"Successfully wrote ArgoCD manifest to {safe_app_name}.yaml"
    except OSError as exc:
        return f"Failed to write ArgoCD manifest '{safe_app_name}.yaml': {exc}"


__all__ = ["kubectl", "read_argocd", "write_argocd"]
