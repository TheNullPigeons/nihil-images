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
    local install_dir="/opt/tools/exiftool"

    if command -v exiftool > /dev/null 2>&1; then
        colorecho "  ✓ exiftool already installed"
        return 0
    fi

    colorecho "  → Installing exiftool"

    # perl-image-exiftool installs to /usr/bin/vendor_perl/exiftool (not /usr/bin/exiftool).
    # That path is not in the default PATH, so command -v would miss it.
    # Check the exact path and create an explicit symlink into /opt/tools/bin.
    pacman -S --noconfirm --needed perl-image-exiftool 2>/dev/null || true
    if [ -f /usr/bin/vendor_perl/exiftool ]; then
        ln -sf /usr/bin/vendor_perl/exiftool /opt/tools/bin/exiftool
        add-history "exiftool"
        colorecho "  ✓ exiftool installed (pacman)"
        return 0
    fi

    # pacman unavailable or package not found -- install from GitHub release
    colorecho "  ⟳ pacman fallback: installing exiftool from GitHub release"
    pacman -S --noconfirm --needed perl 2>/dev/null || true

    local tag
    tag=$(curl -Ls -o /dev/null -w '%{url_effective}' \
        "https://github.com/exiftool/exiftool/releases/latest" | sed 's:.*/::' || true)
    if [ -z "$tag" ]; then
        colorecho "  ✗ Warning: Failed to resolve exiftool version"
        return 0
    fi

    mkdir -p "$install_dir"
    curl -fsSL "https://github.com/exiftool/exiftool/archive/refs/tags/${tag}.tar.gz" \
        -o /tmp/exiftool.tar.gz || {
        colorecho "  ✗ Warning: Failed to download exiftool"
        return 0
    }
    tar xzf /tmp/exiftool.tar.gz -C "$install_dir" --strip-components=1
    rm -f /tmp/exiftool.tar.gz

    if [ -f "$install_dir/exiftool" ]; then
        chmod +x "$install_dir/exiftool"
        # exiftool uses FindBin::RealBin so symlink is safe - lib/ resolves correctly
        ln -sf "$install_dir/exiftool" /opt/tools/bin/exiftool
        add-history "exiftool"
        colorecho "  ✓ exiftool installed (${tag})"
    else
        colorecho "  ✗ Warning: exiftool not found after extraction"
    fi
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

function install_jadx() {
    install_aur_tool "jadx-bin" "jadx"
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
    install_jadx

    colorecho "  [gem] Stego tools:"
    install_zsteg

    colorecho "  [git] Stego tools:"
    install_stegseek

    colorecho "Forensics / Steganography tools installation finished"
}
