#!/bin/bash
# Red-team tools for Forensics and Steganography
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/pacman
nihil::import lib/registry/aur
nihil::import lib/registry/gem

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_volatility3() {
    install_pipx_tool "vol" "volatility3"
}

function install_foremost() {
    install_pacman_tool "foremost"
}

function install_exiftool() {
    install_pacman_tool "perl-image-exiftool"
}

function install_steghide() {
    install_aur_tool "steghide" "steghide"
}

function install_zsteg() {
    install_gem_tool "zsteg"
}

function install_stegseek() {
    local install_dir="/opt/tools/stegseek"

    if command -v stegseek > /dev/null 2>&1; then
        colorecho "  ✓ stegseek already installed"
        return 0
    fi

    colorecho "  → Installing stegseek (steghide brute-forcer)"
    pacman -S --noconfirm --needed cmake libjpeg-turbo libmcrypt mhash || true
    git clone --depth 1 https://github.com/RickdeJager/stegseek.git "$install_dir" || {
        colorecho "  ✗ Warning: Failed to clone stegseek"
        return 1
    }
    cd "$install_dir" && mkdir -p build && cd build && cmake .. && make || {
        colorecho "  ✗ Warning: Failed to build stegseek"
        cd - > /dev/null
        return 1
    }
    ln -sf "$install_dir/build/src/stegseek" /usr/local/bin/stegseek
    cd - > /dev/null

    colorecho "  ✓ stegseek installed"
}

function install_openstego() {
    install_aur_tool "openstego" "openstego"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_forensics() {
    colorecho "Installing Forensics / Steganography red-team tools"

    colorecho "  [pipx] Forensics tools:"
    install_volatility3

    colorecho "  [pacman] Forensics tools:"
    install_exiftool

    colorecho "  [AUR] Forensics / Stego tools:"
    install_foremost
    install_steghide
    install_openstego

    colorecho "  [gem] Stego tools:"
    install_zsteg

    colorecho "  [git] Stego tools:"
    install_stegseek

    colorecho "Forensics / Steganography tools installation finished"
}
