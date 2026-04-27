#!/bin/bash
# Final image cleanup — run once after all modules and healthcheck

nihil::import lib/common

function post_install() {
    colorecho "Running post-install cleanup"

    # Pre-remove leftover download-* temp dirs so pacman -Scc doesn't choke on them
    rm -rf /var/cache/pacman/pkg/download-*
    yes | pacman -Scc

    # Language/tool caches
    rm -rf \
        /root/.cache \
        /root/.cargo/registry \
        /root/go/pkg \
        /root/.npm \
        /root/.bundle/cache \
        /home/builder

    # Temp dirs
    rm -rf /tmp/* /var/tmp/*

    colorecho "Post-install cleanup done"
}
