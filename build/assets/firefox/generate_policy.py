#!/usr/bin/env python3
"""Generate Firefox policies.json from template, fetching extension GUIDs from addons.mozilla.org."""

import json
import os
import re
import urllib.request

TEMPLATE_PATH = "/opt/nihil/build/assets/firefox/policies.json.template"
POLICY_PATH = "/usr/lib/firefox/distribution/policies.json"

EXTENSIONS = [
    {"slug": "foxyproxy-standard", "pin": True,  "mode": "force_installed"},
    {"slug": "cookie-editor",      "pin": True,  "mode": "normal_installed"},
    {"slug": "wappalyzer",         "pin": False, "mode": "normal_installed"},
    {"slug": "multi-account-containers", "pin": False, "mode": "normal_installed"},
    {"slug": "uaswitcher",         "pin": False, "mode": "normal_installed"},
]


def get_extension_guid(slug: str) -> str:
    url = f"https://addons.mozilla.org/en-US/firefox/addon/{slug}/"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        html = resp.read().decode()
    m = re.search(r'"guid":"([^"]+)"', html)
    if not m:
        raise RuntimeError(f"GUID not found for {slug}")
    return m.group(1)


def main():
    with open(TEMPLATE_PATH) as f:
        policy = json.load(f)

    ext_settings = policy["policies"].setdefault("ExtensionSettings", {})

    for ext in EXTENSIONS:
        slug = ext["slug"]
        try:
            guid = get_extension_guid(slug)
            print(f"[+] {slug}: {guid}")
        except Exception as e:
            print(f"[!] Failed to get GUID for {slug}: {e}")
            continue

        cfg = {
            "installation_mode": ext["mode"],
            "install_url": f"https://addons.mozilla.org/firefox/downloads/latest/{slug}/latest.xpi",
        }
        if ext.get("pin"):
            cfg["default_area"] = "navbar"

        ext_settings[guid] = cfg

    os.makedirs(os.path.dirname(POLICY_PATH), exist_ok=True)
    with open(POLICY_PATH, "w") as f:
        json.dump(policy, f, indent=2)
    print(f"[+] Policy written to {POLICY_PATH}")


if __name__ == "__main__":
    main()
