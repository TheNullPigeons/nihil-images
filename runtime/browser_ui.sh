#!/bin/bash

# Start a lightweight browser-based UI (VNC + noVNC) on demand.
# This script is intentionally lazy: it installs the required packages on first run
# and only runs when explicitly requested via NIHIL_BROWSER_UI=1.

set -e

PORT="${NIHIL_BROWSER_UI_PORT:-6901}"

MARKER="/opt/nihil/.browser_ui_installed"
NOVNC_DIR="/opt/nihil/novnc"
OPENBOX_CONFIG_DIR="/root/.config/openbox"

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
            openbox \
            xfce4-terminal \
            feh \
            python-pip \
            python-pipx || true
    else
        echo "[NIHIL] browser-ui: unsupported base OS (expected Arch/pacman)."
        return 1
    fi

    # Install websockify if not present
    if ! command -v websockify >/dev/null 2>&1; then
        echo "[NIHIL] Trying to install websockify via pacman..."
        pacman -S --noconfirm --needed websockify python-websockify >/tmp/nihil_websockify_pacman.log 2>&1 || true
    fi

    if ! command -v websockify >/dev/null 2>&1; then
        if command -v pipx >/dev/null 2>&1; then
            echo "[NIHIL] Trying to install websockify via pipx..."
            pipx install websockify >/tmp/nihil_websockify_pipx.log 2>&1 || true
        fi
    fi

    if ! command -v websockify >/dev/null 2>&1; then
        echo "[NIHIL] Trying to install websockify via pip (with --break-system-packages)..."
        pip install --no-cache-dir --break-system-packages websockify >/tmp/nihil_websockify_pip.log 2>&1 || \
            echo "[NIHIL] browser-ui: failed to install websockify (pacman/pipx/pip)"
    fi

    # Fetch noVNC web assets if not already present
    if [[ ! -d "$NOVNC_DIR" ]]; then
        echo "[NIHIL] Fetching noVNC web assets..."
        git clone --depth=1 https://github.com/novnc/noVNC.git "$NOVNC_DIR" >/tmp/nihil_novnc_clone.log 2>&1 || \
            echo "[NIHIL] browser-ui: failed to clone noVNC repository"
    fi

    # Create a simple landing page that redirects to vnc_lite.html
    if [[ -d "$NOVNC_DIR" && ! -f "$NOVNC_DIR/index.html" ]]; then
        cat > "$NOVNC_DIR/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Nihil browser UI</title>
    <meta http-equiv="refresh" content="0; url=vnc_lite.html?autoconnect=1&resize=scale">
  </head>
  <body>
    <p>Redirecting to the Nihil browser UI...</p>
  </body>
</html>
EOF
    fi

    # Prepare an Openbox session with wallpaper + terminal (and optional panel)
    if [[ ! -d "$OPENBOX_CONFIG_DIR" ]]; then
        mkdir -p "$OPENBOX_CONFIG_DIR"
    fi

    if [[ ! -f "$OPENBOX_CONFIG_DIR/autostart" ]]; then
        cat > "$OPENBOX_CONFIG_DIR/autostart" <<'EOF'
#!/bin/sh

# Set wallpaper if provided, otherwise solid dark background
if command -v feh >/dev/null 2>&1; then
    if [ -f /opt/nihil/runtime/wallpaper.png ]; then
        feh --bg-scale /opt/nihil/runtime/wallpaper.png
    else
        feh --bg-color "#111111"
    fi
fi

# Launch a terminal so the desktop is immediately usable
if command -v xfce4-terminal >/dev/null 2>&1; then
    xfce4-terminal &
elif command -v xterm >/dev/null 2>&1; then
    xterm &
fi
EOF
        chmod +x "$OPENBOX_CONFIG_DIR/autostart"
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

    # Start Openbox (lightweight desktop with our autostart)
    if command -v openbox >/dev/null 2>&1; then
        openbox >/tmp/nihil_openbox.log 2>&1 &
    fi

    # Start x11vnc on port 5901 (no password, container is expected to be local-only)
    if ! pgrep -x x11vnc >/dev/null 2>&1; then
        x11vnc -display :1 -rfbport 5901 -nopw -forever -shared >/tmp/nihil_x11vnc.log 2>&1 &
    fi

    # Start noVNC/websockify HTTP proxy on $PORT
    if command -v websockify >/dev/null 2>&1; then
        local web_dir="$NOVNC_DIR"
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

