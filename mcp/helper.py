#!/usr/bin/env python3
"""
Helper CLI for managing Claude MCP configurations.
"""

import argparse
import os
import sys
from pathlib import Path


def remove_mcp_configs():
    """Remove MCP configurations from all possible scopes."""
    removed = []
    errors = []

    # Define all possible MCP config locations
    config_locations = [
        # Global config
        Path.home() / ".config" / "claude" / "mcp.json",
        # Project-specific (current directory)
        Path.cwd() / ".mcp.json",
        # Alternative global locations
        Path.home() / ".claude" / "mcp.json",
        # Legacy locations (if any)
        Path.home() / ".config" / "claude-code" / "mcp.json",
    ]

    print("Searching for MCP configurations to remove...")

    for config_path in config_locations:
        if config_path.exists():
            try:
                config_path.unlink()
                removed.append(str(config_path))
                print(f"  ✓ Removed: {config_path}")
            except Exception as e:
                errors.append(f"{config_path}: {str(e)}")
                print(f"  ✗ Error removing {config_path}: {e}")
        else:
            print(f"  - Not found: {config_path}")

    print("\n" + "="*60)
    if removed:
        print(f"Removed {len(removed)} MCP configuration(s):")
        for path in removed:
            print(f"  - {path}")
    else:
        print("No MCP configurations found to remove.")

    if errors:
        print(f"\n{len(errors)} error(s) occurred:")
        for error in errors:
            print(f"  - {error}")
        return 1

    return 0


def main():
    parser = argparse.ArgumentParser(
        description="Helper CLI for managing Claude MCP configurations",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s claude-reset-mcp    Remove all MCP configurations
        """
    )

    parser.add_argument(
        'action',
        choices=['claude-reset-mcp'],
        help='Action to perform'
    )

    args = parser.parse_args()

    if args.action == 'claude-reset-mcp':
        return remove_mcp_configs()

    return 0


if __name__ == "__main__":
    sys.exit(main())
