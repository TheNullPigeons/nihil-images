#!/bin/bash
# Final image cleanup — run once after all modules and healthcheck

nihil::import lib/common

function install_list_tools() {
    cat > /opt/tools/bin/list-tools << 'EOF'
#!/bin/bash
cd /opt/nihil/build
source lib/loader.sh
nihil::import lib/healthcheck
list_tools "$@"
EOF
    chmod +x /opt/tools/bin/list-tools
}

function post_install() {
    colorecho "Running post-install cleanup"
    install_list_tools

    # System Python consumers still import pkg_resources; keep the same
    # compatibility bound used by isolated environments after package upgrades.
    python3 -m pip install --break-system-packages "setuptools<81" || return 1

    rm -rf /var/cache/pacman/pkg/ /var/lib/pacman/sync/

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
