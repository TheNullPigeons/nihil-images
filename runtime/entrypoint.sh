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
        touch "$LOCKFILE"
    fi
}

run_default() {
    deploy_my_resources
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
