#!/bin/bash
# Runtime entrypoint: keep container alive or execute a command

set -e

trap "exit 0" SIGTERM SIGINT

run_default() {
    exec tail -f /dev/null
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
