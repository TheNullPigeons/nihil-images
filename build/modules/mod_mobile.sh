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
    install_aur_tool "android-apktool" "apktool"
}

function install_dex2jar() {
    install_aur_tool "dex2jar" "d2j-dex2jar"
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
