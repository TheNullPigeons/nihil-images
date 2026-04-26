#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Install Firefox extensions and configure the Nihil profile at image build time."""

import json
import re
import shutil
import subprocess
import zipfile
from glob import glob
from pathlib import Path
from time import sleep

import requests

PROFILE_NAME = "Nihil"
PROFILE_DIR = "/root/.mozilla/firefox/nihil.Nihil"
PROFILE_GLOB = "/root/.mozilla/firefox/**.Nihil/"
FIREFOX = shutil.which("firefox") or "/usr/sbin/firefox"
FIREFOX_CMD = [FIREFOX, "--no-sandbox"]

ADDON_URLS = [
    "https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/",
    "https://addons.mozilla.org/en-US/firefox/addon/uaswitcher/",
    "https://addons.mozilla.org/en-US/firefox/addon/cookie-editor/",
    "https://addons.mozilla.org/en-US/firefox/addon/wappalyzer/",
    "https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/",
]

RE_DOWNLOAD = r"(https://addons\.mozilla\.org/firefox/downloads/file/[0-9]+/)([a-zA-Z0-9\-_.]+\.xpi)"
RE_ID = r'"id":\s*"([^"]+)"'


def get_profile_path() -> str:
    matches = glob(PROFILE_GLOB)
    if not matches:
        raise RuntimeError(f"Firefox profile {PROFILE_NAME!r} not found")
    return matches[0]


def get_download_link(url: str):
    r = requests.get(url, timeout=30)
    m = re.search(RE_DOWNLOAD, r.text)
    if not m:
        raise RuntimeError(f"No download link found at {url}")
    return "".join(m.groups()), m.group(2)


def download_addon(link: str, name: str) -> str:
    dest = f"/tmp/{name}"
    r = requests.get(link, timeout=60)
    Path(dest).write_bytes(r.content)
    return dest


def get_addon_id(xpi_path: str) -> str:
    with zipfile.ZipFile(xpi_path) as z:
        manifest = z.read("manifest.json").decode()
    m = re.search(RE_ID, manifest)
    if not m:
        raise RuntimeError(f"Could not find addon id in {xpi_path}")
    return m.group(1)


def install_addon(xpi_path: str, addon_id: str):
    profile = get_profile_path()
    ext_dir = Path(profile) / "extensions"
    ext_dir.mkdir(parents=True, exist_ok=True)
    shutil.move(xpi_path, str(ext_dir / f"{addon_id}.xpi"))


def create_profile():
    print(f"[*] Creating Firefox profile {PROFILE_NAME!r}")
    Path(PROFILE_DIR).mkdir(parents=True, exist_ok=True)
    # Register profile in profiles.ini
    profiles_ini = Path("/root/.mozilla/firefox/profiles.ini")
    profiles_ini.parent.mkdir(parents=True, exist_ok=True)
    if not profiles_ini.exists():
        profiles_ini.write_text(
            "[General]\nStartWithLastProfile=1\n\n"
            f"[Profile0]\nName={PROFILE_NAME}\nIsRelative=0\nPath={PROFILE_DIR}\nDefault=1\n"
        )
    print("[+] Profile created")


def init_profile():
    print("[*] Initialising Firefox profile (headless run)")
    p = subprocess.Popen(
        FIREFOX_CMD + ["--profile", PROFILE_DIR, "--headless"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    profile = get_profile_path()
    for _ in range(60):
        if (Path(profile) / "sessionstore-backups").exists():
            break
        sleep(1)
    p.kill()
    p.wait()
    if not (Path(profile) / "extensions.json").is_file():
        raise RuntimeError("Profile initialisation failed")
    print("[+] Profile initialised")


def enable_addons(addon_ids: list):
    profile = get_profile_path()
    ext_json = Path(profile) / "extensions.json"
    if not ext_json.is_file():
        print("[!] extensions.json not found, skipping activation")
        return
    data = json.loads(ext_json.read_text())
    for addon in data.get("addons", []):
        if addon.get("id") in addon_ids:
            addon["active"] = True
            addon["userDisabled"] = False
            addon["seen"] = True
    ext_json.write_text(json.dumps(data))
    print("[+] Extensions activated")


def finalize_profile():
    print("[*] Finalising profile (second headless run)")
    profile = get_profile_path()
    lz4 = Path(profile) / "addonStartup.json.lz4"
    if lz4.exists():
        lz4.unlink()
    p = subprocess.Popen(
        FIREFOX_CMD + ["--profile", PROFILE_DIR, "--headless"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    for _ in range(60):
        if lz4.exists():
            break
        sleep(1)
    p.kill()
    p.wait()
    print("[+] Profile finalised")


if __name__ == "__main__":
    create_profile()

    installed_ids = []
    for url in ADDON_URLS:
        try:
            link, name = get_download_link(url)
            xpi_path = download_addon(link, name)
            addon_id = get_addon_id(xpi_path)
            install_addon(xpi_path, addon_id)
            installed_ids.append(addon_id)
            print(f"[+] Installed: {name} ({addon_id})")
        except Exception as e:
            print(f"[!] Failed to install {url}: {e}")

    init_profile()
    enable_addons(installed_ids)
    finalize_profile()

    print("[+] Firefox setup complete")
