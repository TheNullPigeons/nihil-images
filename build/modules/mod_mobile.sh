#!/bin/bash
# Red-team tools for Mobile (Android / iOS)
# Each tool has its own install_$TOOL function for easier maintenance.
# jadx is provided by mod_forensics (install_jadx) and reused via the catalogue.

nihil::import lib/common
nihil::import lib/registry/pacman
nihil::import lib/registry/aur
nihil::import lib/registry/pipx
nihil::import lib/registry/cargo

# ---------------------------------------------------------------------------
# Android
# ---------------------------------------------------------------------------

function install_android_tools() {
    # adb / fastboot
    install_pacman_tool "android-tools"
    add-history "android-tools"
}

function install_scrcpy() {
    install_pacman_tool "scrcpy"
}

function install_apktool() {
    # The AUR package pins java-environment=26 + gradle (unresolvable here), so
    # install the official release jar with a thin wrapper (needs only a JRE).
    if command -v apktool >/dev/null 2>&1; then
        colorecho "  ✓ apktool already installed"
        add-history "apktool"
        return 0
    fi
    command -v java >/dev/null 2>&1 || install_pacman_tools "jre-openjdk-headless" || return 0
    local tag version
    tag=$(retry-command 3 "resolve apktool latest tag" curl -Ls -o /dev/null -w '%{url_effective}' \
        "https://github.com/iBotPeaches/Apktool/releases/latest" | sed 's:.*/::' || true)
    [ -n "$tag" ] || { colorecho "  ✗ Warning: Failed to resolve apktool latest tag"; return 0; }
    version="${tag#v}"
    mkdir -p /opt/tools/apktool
    download-retry "https://github.com/iBotPeaches/Apktool/releases/download/${tag}/apktool_${version}.jar" \
        "/opt/tools/apktool/apktool.jar" || {
        colorecho "  ✗ Warning: Failed to download apktool"
        return 0
    }
    printf '%s\n' '#!/bin/sh' 'exec java -jar /opt/tools/apktool/apktool.jar "$@"' > /opt/tools/bin/apktool
    chmod +x /opt/tools/bin/apktool
    ln -sf /opt/tools/bin/apktool /usr/local/bin/apktool
    add-history "apktool"
    colorecho "  ✓ apktool installed (${tag})"
}

function install_dex2jar() {
    # AUR package exposes a single `dex2jar` wrapper binary.
    install_aur_tool "dex2jar" "dex2jar"
}

function install_apkleaks() {
    install_pipx_tool "apkleaks" "apkleaks"
}

function install_androguard() {
    install_pipx_tool "androguard" "androguard"
}

function install_apkeep() {
    install_cargo_tool "apkeep"
}

# ---------------------------------------------------------------------------
# Dynamic instrumentation (Android + iOS)
# ---------------------------------------------------------------------------

function install_frida_tools() {
    # frida ships abi3 wheels, so pipx installs cleanly even on Python 3.14.
    install_pipx_tool "frida" "frida-tools" "frida"
}

function install_objection() {
    install_pipx_tool "objection" "objection"
}

# ---------------------------------------------------------------------------
# iOS
# ---------------------------------------------------------------------------

function install_libimobiledevice() {
    install_pacman_tool "libimobiledevice"
}

function install_ideviceinstaller() {
    install_aur_tool "ideviceinstaller"
}

function install_libplist() {
    install_pacman_tool "libplist"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_mobile() {
    install_selected_tools "mod_mobile"
}
