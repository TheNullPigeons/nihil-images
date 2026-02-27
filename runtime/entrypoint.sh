#!/bin/bash
# Runtime entrypoint: keep container alive or execute a command

set -e

trap "exit 0" SIGTERM SIGINT

LOCKFILE="/opt/my-resources/.nihil_setup_done"
LOAD_SCRIPT="/opt/nihil/runtime/load_my_resources.sh"

# Déploie les my-resources au premier démarrage du container
deploy_my_resources() {
    if [[ -f "$LOAD_SCRIPT" && ! -f "$LOCKFILE" ]]; then
        bash "$LOAD_SCRIPT"
        # Create lockfile only if the parent directory exists, to avoid failures
        # when my-resources volume is intentionally disabled.
        if [[ -d "$(dirname "$LOCKFILE")" ]]; then
            touch "$LOCKFILE"
        fi
    fi
}

run_default() {
    deploy_my_resources

    # Optional browser-based UI (VNC + noVNC) for this session only.
    if [ "${NIHIL_BROWSER_UI:-0}" = "1" ]; then
        if [ -x /opt/nihil/runtime/browser_ui.sh ]; then
            /opt/nihil/runtime/browser_ui.sh >/tmp/nihil_browser_ui_boot.log 2>&1 &
        else
            echo "[NIHIL] browser-ui requested but /opt/nihil/runtime/browser_ui.sh is missing"
        fi
    fi

    # VPN: if NIHIL_VPN=1, config is at /opt/nihil/vpn/client.ovpn; start OpenVPN then shell; VPN stops when container exits
    if [ "${NIHIL_VPN:-0}" = "1" ]; then
        if [ -f /opt/nihil/vpn/client.ovpn ] && command -v openvpn > /dev/null 2>&1; then
            echo "[nihil] Starting VPN (/opt/nihil/vpn/client.ovpn)..."
            openvpn --config /opt/nihil/vpn/client.ovpn --daemon
            sleep 2
        else
            [ ! -f /opt/nihil/vpn/client.ovpn ] && echo "[nihil] VPN requested but /opt/nihil/vpn/client.ovpn not found"
            command -v openvpn > /dev/null 2>&1 || echo "[nihil] VPN requested but openvpn not installed"
        fi
    fi

    # Si zsh est disponible, on le lance directement
    if command -v zsh > /dev/null 2>&1; then
        exec zsh
    else
        # Sinon, on garde le conteneur vivant avec tail
        exec tail -f /dev/null
    fi
}

run_cmd() {
    deploy_my_resources
    shift
    exec "$@"
}

if [ $# -eq 0 ]; then
    run_default
else
    if [ "$1" = "cmd" ]; then
        run_cmd "$@"
    else
        deploy_my_resources
        exec "$@"
    fi
fi
