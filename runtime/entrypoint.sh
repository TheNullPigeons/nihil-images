#!/bin/bash
# Runtime entrypoint: keep container alive or execute a command

set -e

trap "exit 0" SIGTERM SIGINT

run_default() {
    # Si zsh est disponible, on le lance directement
    if command -v zsh >/dev/null 2>&1; then
        exec zsh
    else
        # Sinon, on garde le conteneur vivant avec tail
        exec tail -f /dev/null
    fi
}

run_cmd() {
    shift
    exec "$@"
}

if [ $# -eq 0 ]; then
    run_default
else
    if [ "$1" = "cmd" ]; then
        run_cmd "$@"
    else
        exec "$@"
    fi
fi
