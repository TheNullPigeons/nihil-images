#!/bin/bash

# Start a lightweight browser-based UI (VNC + noVNC) on demand.
# This script is intentionally lazy: it installs the required packages on first run
# and only runs when explicitly requested via NIHIL_BROWSER_UI=1.

set -e

PORT="${NIHIL_BROWSER_UI_PORT:-6901}"

MARKER="/opt/nihil/.browser_ui_installed"

install_browser_ui_deps() {
    if [[ -f "$MARKER" ]]; then
        return 0
    fi

    echo "[NIHIL] Installing browser UI dependencies (this may take a while)..."
    if command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm
        pacman -S --noconfirm --needed \
            xorg-server-xvfb \
            x11vnc \
            novnc \
            openbox || true
    else
        echo "[NIHIL] browser-ui: unsupported base OS (expected Arch/pacman)."
        return 1
    fi

    mkdir -p "$(dirname "$MARKER")"
    touch "$MARKER"
}

start_browser_ui() {
    export DISPLAY=":1"

    # Start Xvfb if not already running
    if ! pgrep -x Xvfb >/dev/null 2>&1; then
        Xvfb :1 -screen 0 1280x720x24 >/tmp/nihil_xvfb.log 2>&1 &
        sleep 1
    fi

    # Start a minimal window manager
    if command -v openbox >/dev/null 2>&1; then
        openbox >/tmp/nihil_openbox.log 2>&1 &
    fi

    # Start x11vnc on port 5901 (no password, container is expected to be local-only)
    if ! pgrep -x x11vnc >/dev/null 2>&1; then
        x11vnc -display :1 -rfbport 5901 -nopw -forever -shared >/tmp/nihil_x11vnc.log 2>&1 &
    fi

    # Start noVNC/websockify HTTP proxy on $PORT
    if command -v websockify >/dev/null 2>&1; then
        local web_dir="/usr/share/novnc"
        if [[ -d "$web_dir" ]]; then
            websockify --web "$web_dir" "$PORT" localhost:5901 >/tmp/nihil_browser_ui.log 2>&1 &
            echo "[NIHIL] Browser UI available on port $PORT (noVNC)."
        else
            echo "[NIHIL] browser-ui: noVNC web assets not found at $web_dir"
        fi
    else
        echo "[NIHIL] browser-ui: websockify not installed; HTTP access disabled"
    fi
}

install_browser_ui_deps || exit 0
start_browser_ui

