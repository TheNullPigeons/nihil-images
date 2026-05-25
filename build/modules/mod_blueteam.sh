#!/bin/bash
# Blue team / SOC - outils propres au blueteam (hors mod_forensics et mod_network).
# Categories: Log Analysis/Threat Hunting, Malware Triage, Disk Forensics, Network Detection

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/pacman

# Résout le tag de la dernière release via redirect HTTP (pas d'API, pas de rate limit)
_latest_tag() {
    curl -Ls -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's:.*/::' || true
}

# ===========================================================================
# Log Analysis / Threat Hunting
# ===========================================================================

function install_chainsaw() {
    local install_dir="/opt/tools/chainsaw"

    if command -v chainsaw > /dev/null 2>&1; then
        colorecho "  ✓ chainsaw already installed"
        return 0
    fi

    colorecho "  → Installing chainsaw (Windows event log hunter)"

    # Asset name is stable across versions (no version in filename)
    local url="https://github.com/WithSecureLabs/chainsaw/releases/latest/download/chainsaw_x86_64-unknown-linux-gnu.tar.gz"

    mkdir -p "$install_dir"
    curl -fsSL "$url" -o /tmp/chainsaw.tar.gz || {
        colorecho "  ✗ Warning: Failed to download chainsaw"
        return 0
    }

    # Archive: chainsaw/ -> chainsaw (binary) + rule_libs/ + sigma/ etc.
    tar xzf /tmp/chainsaw.tar.gz -C "$install_dir" --strip-components=1
    rm -f /tmp/chainsaw.tar.gz

    if [ -x "$install_dir/chainsaw" ]; then
        ln -sf "$install_dir/chainsaw" /opt/tools/bin/chainsaw
        add-history "chainsaw"
        colorecho "  ✓ chainsaw installed"
    else
        colorecho "  ✗ Warning: chainsaw binary not found after extraction"
    fi
    return 0
}

function install_hayabusa() {
    local install_dir="/opt/tools/hayabusa"

    if command -v hayabusa > /dev/null 2>&1; then
        colorecho "  ✓ hayabusa already installed"
        return 0
    fi

    colorecho "  → Installing hayabusa (Windows DFIR timeline generator)"
    pacman -S --noconfirm --needed unzip 2>/dev/null || true

    local tag version url
    tag=$(_latest_tag "Yamato-Security/hayabusa")
    version="${tag#v}"

    if [ -z "$tag" ]; then
        colorecho "  ✗ Warning: Failed to resolve hayabusa latest tag"
        return 0
    fi

    # Asset format (since v3.x): hayabusa-<version>-lin-x64-gnu.zip
    url="https://github.com/Yamato-Security/hayabusa/releases/download/${tag}/hayabusa-${version}-lin-x64-gnu.zip"

    mkdir -p "$install_dir"
    curl -fsSL "$url" -o /tmp/hayabusa.zip || {
        colorecho "  ✗ Warning: Failed to download hayabusa"
        return 0
    }

    unzip -o /tmp/hayabusa.zip -d "$install_dir" 2>/dev/null
    rm -f /tmp/hayabusa.zip

    # Binary: hayabusa-<version>-lin-x64-gnu (no extension)
    local hayabusa_bin
    hayabusa_bin=$(find "$install_dir" -maxdepth 1 -name "hayabusa-*" -not -name "*.zip" -type f 2>/dev/null | head -1)
    if [ -n "$hayabusa_bin" ]; then
        chmod +x "$hayabusa_bin"
        ln -sf "$hayabusa_bin" /opt/tools/bin/hayabusa
        add-history "hayabusa"
        colorecho "  ✓ hayabusa installed"
    else
        colorecho "  ✗ Warning: hayabusa binary not found after extraction"
    fi
    return 0
}

function install_sigma_cli() {
    # PyPI: sigma-cli, binary: sigma
    install_pipx_tool "sigma" "sigma-cli"
}

# ===========================================================================
# Malware Triage
# ===========================================================================

function install_yara() {
    install_pacman_tool "yara"
}

function install_capa() {
    local install_dir="/opt/tools/capa"

    if command -v capa > /dev/null 2>&1; then
        colorecho "  ✓ capa already installed"
        return 0
    fi

    colorecho "  → Installing capa (FLARE malware capability detection)"
    pacman -S --noconfirm --needed unzip 2>/dev/null || true

    local tag url
    tag=$(_latest_tag "mandiant/capa")

    if [ -z "$tag" ]; then
        colorecho "  ✗ Warning: Failed to resolve capa latest tag"
        return 0
    fi

    # Asset format: capa-v9.4.0-linux.zip (tag includes 'v' prefix)
    url="https://github.com/mandiant/capa/releases/download/${tag}/capa-${tag}-linux.zip"

    mkdir -p "$install_dir"
    curl -fsSL "$url" -o /tmp/capa.zip || {
        colorecho "  ✗ Warning: Failed to download capa"
        return 0
    }

    unzip -o /tmp/capa.zip -d "$install_dir" 2>/dev/null
    rm -f /tmp/capa.zip

    if [ -f "$install_dir/capa" ]; then
        chmod +x "$install_dir/capa"
        ln -sf "$install_dir/capa" /opt/tools/bin/capa
        add-history "capa"
        colorecho "  ✓ capa installed"
    else
        colorecho "  ✗ Warning: capa binary not found after extraction"
    fi
    return 0
}

function install_loki() {
    local install_dir="/usr/local/share/loki"

    if command -v loki > /dev/null 2>&1; then
        colorecho "  ✓ loki already installed"
        return 0
    fi

    colorecho "  → Installing loki (IOC scanner)"
    if [ ! -d "$install_dir" ]; then
        git clone --depth 1 https://github.com/Neo23x0/Loki.git "$install_dir" || {
            colorecho "  ✗ Warning: Failed to clone loki"
            return 0
        }
    fi

    if [ -f "$install_dir/requirements.txt" ]; then
        python3 -m pip install --break-system-packages -r "$install_dir/requirements.txt" --quiet 2>/dev/null || \
            python3 -m pip install -r "$install_dir/requirements.txt" --quiet 2>/dev/null || true
    fi

    mkdir -p /root/.local/bin
    cat > /root/.local/bin/loki <<'EOF'
#!/bin/sh
exec python3 /usr/local/share/loki/loki.py "$@"
EOF
    chmod +x /root/.local/bin/loki
    add-history "loki"
    colorecho "  ✓ loki installed"
    return 0
}

# ===========================================================================
# Disk Forensics (complement de mod_forensics)
# ===========================================================================

function install_sleuthkit() {
    if command -v fls > /dev/null 2>&1; then
        colorecho "  ✓ sleuthkit already installed"
        return 0
    fi
    colorecho "  → Installing sleuthkit via pacman"
    pacman -Sy --noconfirm && pacman -S --noconfirm --needed sleuthkit || {
        colorecho "  ✗ Warning: Failed to install sleuthkit"
        return 0
    }
    add-history "sleuthkit"
    colorecho "  ✓ sleuthkit installed"
}

# ===========================================================================
# Module entry point
# ===========================================================================

function install_mod_blueteam() {
    colorecho "Installing blue team / SOC tools"

    colorecho "  [log] Log analysis and threat hunting:"
    install_chainsaw
    install_hayabusa
    install_sigma_cli

    colorecho "  [malware] Malware triage:"
    install_yara
    install_capa
    install_loki

    colorecho "  [disk] Disk forensics:"
    install_sleuthkit

    colorecho "Blue team / SOC tools installation finished"
}
