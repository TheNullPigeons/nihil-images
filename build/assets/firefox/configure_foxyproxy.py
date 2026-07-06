#!/usr/bin/env python3
"""
Pre-seed FoxyProxy with Burp Suite proxy (127.0.0.1:8080) via marionette.

Firefox must be running with:
  --headless --marionette --remote-allow-system-access --profile <dir>

FoxyProxy must already be installed (force_installed via policies.json).
The script polls until FoxyProxy is active, then sets mode + proxy.

Technical note: browser.storage.local Promises live in the extension's privileged
sandbox and cannot be awaited from the marionette content sandbox. We use
wrappedJSObject.browser to access the API, fire the operation with document.title
as a cross-sandbox signal to know when it completes.
"""
import time
import sys
import json

FOXYPROXY_ID = "foxyproxy@eric.h.jung"
MAX_WAIT_SEC = 120

BURP_PROXY = {
    "active": True,
    "title": "Burp Suite",
    "type": "http",
    "hostname": "127.0.0.1",
    "port": 8080,
    "username": "",
    "password": "",
    "cc": "",
    "city": "",
    "color": "#FF6633",
    "pac": "",
    "pacString": "",
    "proxyDNS": False,
    "include": [],
    "exclude": [],
    "tabProxy": [],
}


def wait_for_marionette(port=2828, timeout=60):
    import socket
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            s = socket.create_connection(("127.0.0.1", port), timeout=2)
            s.close()
            return True
        except OSError:
            time.sleep(2)
    return False


def get_foxyproxy_uuid(client):
    client.set_context(client.CONTEXT_CHROME)
    uuid = client.execute_script("""
        for (const p of WebExtensionPolicy.getActiveExtensions()) {
            if (p.id === arguments[0]) return p.mozExtensionHostname;
        }
        return null;
    """, script_args=[FOXYPROXY_ID])
    client.set_context(client.CONTEXT_CONTENT)
    return uuid


def wait_for_foxyproxy(client, timeout=MAX_WAIT_SEC):
    print(f"[*] Waiting for FoxyProxy to be installed (up to {timeout}s)...")
    deadline = time.time() + timeout
    while time.time() < deadline:
        uuid = get_foxyproxy_uuid(client)
        if uuid:
            return uuid
        time.sleep(3)
    return None


def poll_title(client, expected, timeout=15):
    deadline = time.time() + timeout
    while time.time() < deadline:
        t = client.execute_script("return document.title;")
        if t == expected:
            return True
        if t and t.startswith("err:"):
            return t
        time.sleep(0.5)
    return False


def configure_foxyproxy(client, uuid):
    options_url = f"moz-extension://{uuid}/content/options.html"
    print(f"[*] Navigating to {options_url}")
    try:
        client.navigate(options_url)
    except Exception as e:
        print(f"[!] Navigate raised (alert dismissed, continuing): {type(e).__name__}")

    time.sleep(2)

    burp_json = json.dumps(BURP_PROXY)
    client.execute_script(f"""
        document.title = 'pending';
        const burp = {burp_json};
        const b = window.wrappedJSObject.browser;
        b.storage.local.get(null).then(function(current) {{
            var data = current.data || [];
            if (!data.some(function(p) {{ return p.hostname === burp.hostname && p.port === burp.port; }})) {{
                data.push(burp);
            }}
            return b.storage.local.set({{
                mode:        burp.hostname + ':' + burp.port,
                sync:        current.sync        || false,
                autoBackup:  current.autoBackup  || false,
                passthrough: current.passthrough || '',
                theme:       current.theme       || '',
                container:   current.container   || {{}},
                commands:    current.commands    || {{}},
                data:        data,
            }});
        }}).then(function() {{
            document.title = 'done';
        }}).catch(function(e) {{
            document.title = 'err:' + String(e);
        }});
    """)

    result = poll_title(client, "done", timeout=15)
    if result is True:
        print("[+] Storage written successfully")
    else:
        print(f"[!] Storage write failed or timed out: {result}")

    # Verify
    client.execute_script("""
        document.title = 'verifying';
        window.wrappedJSObject.browser.storage.local.get(['mode','data']).then(function(r) {
            document.title = JSON.stringify({mode: r.mode, count: (r.data||[]).length});
        });
    """)
    time.sleep(2)
    title = client.execute_script("return document.title;")
    try:
        info = json.loads(title)
        print(f"[+] Verify: mode={info.get('mode')}, proxies={info.get('count')}")
    except Exception:
        print(f"[!] Verify title: {title}")


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 2828

    print(f"[*] Waiting for marionette on port {port}...")
    if not wait_for_marionette(port):
        print("[!] Marionette not available")
        sys.exit(1)

    from marionette_driver.marionette import Marionette

    client = Marionette("localhost", port=port)
    client.start_session({"unhandledPromptBehavior": "dismiss"})
    print("[*] Marionette connected")

    uuid = wait_for_foxyproxy(client)
    if not uuid:
        print("[!] FoxyProxy not loaded after timeout")
        client.delete_session()
        sys.exit(1)
    print(f"[*] FoxyProxy UUID: {uuid}")

    configure_foxyproxy(client, uuid)

    client.delete_session()
    print("[+] FoxyProxy configuration complete.")


if __name__ == "__main__":
    main()
