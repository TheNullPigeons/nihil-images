#!/bin/bash
# Outils red-team divers (exploit-db, etc.)

nihil::import lib/common
nihil::import lib/registry/git
nihil::import lib/registry/aur
nihil::import lib/registry/go
nihil::import lib/registry/pacman

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_searchsploit() {
    local install_dir="/opt/tools/exploitdb"
    local repo_url="https://gitlab.com/exploit-database/exploitdb.git"

    install_git_tool_symlink "$install_dir" "$repo_url" "searchsploit" || return 1
    if [ -f "$install_dir/.searchsploit_rc" ]; then
        cp -n "$install_dir/.searchsploit_rc" ~/.searchsploit_rc
        sed -i 's/\(.*[pP]aper.*\)/#\1/' ~/.searchsploit_rc
        sed -i 's|opt/exploitdb|opt/tools/exploitdb|g' ~/.searchsploit_rc
    fi
}


# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_cyberchef() {
    local install_dir="/opt/tools/CyberChef"

    if [ -d "$install_dir" ]; then
        colorecho "  ✓ CyberChef already installed"
        return 0
    fi

    colorecho "  → Installing CyberChef (offline)"
    mkdir -p "$install_dir"
    local latest_url
    latest_url=$(curl -s https://api.github.com/repos/gchq/CyberChef/releases/latest | \
        grep "browser_download_url.*CyberChef.*\.zip" | head -1 | cut -d'"' -f4)
    if [ -n "$latest_url" ]; then
        pacman -S --noconfirm --needed unzip 2>/dev/null || true
        curl -sSL "$latest_url" -o /tmp/cyberchef.zip && \
        unzip -o /tmp/cyberchef.zip -d "$install_dir" && \
        rm -f /tmp/cyberchef.zip
        colorecho "  ✓ CyberChef installed at $install_dir"
    else
        colorecho "  ✗ Warning: Failed to fetch CyberChef release URL"
        return 1
    fi
}

function install_firefox() {
    install_pacman_tool "firefox"
    python3 /opt/nihil/build/assets/firefox/generate_policy.py
    add-history "firefox"
}
function install_chromium() {
    install_pacman_tool "chromium"
    printf '#!/bin/bash\nexec /usr/sbin/chromium --no-sandbox "$@"\n' > /opt/tools/bin/chromium
    chmod +x /opt/tools/bin/chromium
    # Force-install extensions via policy (downloaded on first launch)
    mkdir -p /etc/chromium/policies/managed
    cat > /etc/chromium/policies/managed/extensions.json << 'EOF'
{
  "ExtensionInstallForcelist": [
    "gcknhkkoolaabfmlnjonogaaifnjlfnp;https://clients2.google.com/service/update2/crx"
  ]
}
EOF
}
function install_chrony() {
    install_pacman_tool "chrony"
}

function install_grc() {
    install_pacman_tool "grc"
    local grc_assets="/opt/nihil/build/assets/grc"
    cp "${grc_assets}/grc.conf" /etc/grc.conf
    cp "${grc_assets}"/conf.* /usr/share/grc/
}

function install_sqlitebrowser() {
    install_pacman_tool "sqlitebrowser"
}

function install_keepassxc() {
    install_pacman_tool "keepassxc"
}

function install_rsync() {
    install_pacman_tool "rsync"
}

function install_wes() {
    install_git_tool "wes" "https://github.com/bitsadmin/wesng.git" "wes.py"
}

function install_gitleaks() {
    # go install github.com/gitleaks/gitleaks/v8@latest fails: go.mod in v8.30.1+
    # still declares the old path github.com/zricethezav/gitleaks/v8 (org rename),
    # causing a module path mismatch. Use the prebuilt binary instead.
    if command -v gitleaks > /dev/null 2>&1; then
        colorecho "  ✓ gitleaks already installed"
        return 0
    fi

    colorecho "  → Installing gitleaks (prebuilt binary)"
    local arch
    arch=$(uname -m)
    [ "$arch" = "aarch64" ] && arch="arm64" || arch="x64"

    local url
    url=$(curl -Ls "https://api.github.com/repos/gitleaks/gitleaks/releases/latest" \
        | grep "browser_download_url.*gitleaks.*linux_${arch}.*tar\.gz" \
        | grep -o 'https://[^"]*' | head -1)

    if [ -z "$url" ]; then
        colorecho "  ✗ Warning: Failed to resolve gitleaks download URL"
        return 0
    fi

    curl -fsSL "$url" -o /tmp/gitleaks.tar.gz || {
        colorecho "  ✗ Warning: Failed to download gitleaks"
        return 0
    }
    tar -xf /tmp/gitleaks.tar.gz -C /tmp gitleaks
    rm -f /tmp/gitleaks.tar.gz
    mv /tmp/gitleaks /opt/tools/bin/gitleaks
    chmod +x /opt/tools/bin/gitleaks

    add-history "gitleaks"
    colorecho "  ✓ gitleaks installed"
}

function install_rdate() {
    pacman -S --noconfirm --needed libbsd autoconf automake make gcc
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone --depth 1 https://github.com/resurrecting-open-source-projects/openrdate.git "$tmpdir/rdate"
    cd "$tmpdir/rdate"
    ./autogen.sh && ./configure && make && make install
    cd /
    rm -rf "$tmpdir"
}


# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_misc() {
    colorecho "Installing misc red-team tools"

    install_searchsploit
    install_cyberchef
    install_firefox
    install_chromium
    install_chrony
    install_rdate
    install_grc
    install_sqlitebrowser

    install_keepassxc
    install_rsync
    install_wes
    install_gitleaks

    colorecho "Misc red-team tools installation finished"
}
