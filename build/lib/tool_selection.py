"""Resolve catalogue identities to explicit installers before running any of them."""

import json
from pathlib import Path
import re
import sys


def tool_key(name):
    return name.lower().replace("_", "-")


def plan_tools(manifest, selection=None):
    if not isinstance(manifest, dict) or not isinstance(selection, (dict, type(None))):
        raise ValueError("Tool manifest and selection must be JSON objects")
    selection = {} if selection is None else selection
    for field in ("enabled_tools", "disabled_tools"):
        values = selection.get(field, [])
        if not isinstance(values, list) or any(not isinstance(n, str) for n in values):
            raise ValueError(f"{field} must be a list of tool names")
    enabled = {tool_key(n) for n in selection.get("enabled_tools", [])}
    disabled = {tool_key(n) for n in selection.get("disabled_tools", [])}
    entries = []
    providers = {}
    for module, tools in manifest.items():
        if not re.fullmatch(r"(?:core_tools|mod_[a-z0-9_]+)", module) or not isinstance(tools, list):
            raise ValueError(f"Invalid module: {module}")
        for tool in tools:
            name, installer = tool["name"], tool["installer"]
            if not isinstance(name, str) or not name or any(c in name for c in "|\n\r"):
                raise ValueError("Invalid tool name")
            if not isinstance(installer, str) or not re.fullmatch(r"install_[a-zA-Z0-9_-]+", installer):
                raise ValueError(f"Invalid installer for {name}")
            key = tool_key(name)
            if key in providers and providers[key] != installer:
                raise ValueError(f"Conflicting installers for {name}")
            providers[key] = installer
            active = module == "core_tools" or (
                key in enabled if "enabled_tools" in selection else key not in disabled
            )
            entries.append((module, name, installer, active))
    unknown = (enabled | disabled) - providers.keys()
    if unknown:
        raise ValueError(f"Unknown selected tools: {', '.join(sorted(unknown))}")
    return entries


def main():
    root = Path(sys.argv[1])
    manifest = json.loads((root / "config/tools.json").read_text())
    path = root / "config/tool-selection.json"
    selection = json.loads(path.read_text()) if path.exists() else None
    entries = plan_tools(manifest, selection)
    for module, name, installer, active in entries:
        print(f"tool|{tool_key(name)}|{int(active)}")
        print(f"function|{installer}|")
        if active:
            print(f"installer|{module}|{installer}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"Invalid tool configuration: {exc}", file=sys.stderr)
        sys.exit(1)
