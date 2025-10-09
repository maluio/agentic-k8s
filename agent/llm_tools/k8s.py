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


__all__ = ["kubectl"]
