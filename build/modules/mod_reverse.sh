#!/bin/bash
# Red-team tools for Reverse Engineering
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/pacman
nihil::import lib/registry/go

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_ghidra() {
    install_pacman_tool "ghidra"
}

function install_wabt() {
    # WebAssembly Binary Toolkit: wat2wasm, wasm2wat, wasm-objdump, etc.
    # (the package name differs from its binaries, so the helper's command
    # guard never short-circuits; pacman --needed keeps it idempotent.)
    install_pacman_tool "wabt"
}

function install_vt() {
    # VirusTotal CLI, handy for triaging samples during reverse work.
    install_go_tool "github.com/VirusTotal/vt-cli/vt@latest" "vt"
}

function install_jd-gui() {
    # GUI Java decompiler shipped as a single jar; wrap it in a launcher on PATH
    # (mirrors the burpsuite/ysoserial jar pattern). Needs an X server to display.
    local jar_dir="/opt/tools/jd-gui"
    local jar_file="${jar_dir}/jd-gui.jar"
    if [ -f "$jar_file" ]; then
        colorecho "  ✓ jd-gui already installed"
        return 0
    fi
    colorecho "  → Installing jd-gui (Java decompiler)"
    mkdir -p "$jar_dir"
    if curl -sSLf -o "$jar_file" \
        "https://github.com/java-decompiler/jd-gui/releases/download/v1.6.6/jd-gui-1.6.6.jar"; then
        local java_bin
        java_bin=$(command -v java)
        printf '#!/bin/bash\nexec %s -jar %s "$@"\n' "$java_bin" "$jar_file" \
            > /opt/tools/bin/jd-gui
        chmod +x /opt/tools/bin/jd-gui
    else
        colorecho "  ✗ Warning: Failed to download jd-gui"
    fi
}

function install_ida() {
    # IDA Free (proprietary, GUI only, x86_64). Unattended installer drops the
    # disassembler at /opt/tools/idafree/ida64; expose it on PATH. Needs X to run.
    if [ "$(uname -m)" != "x86_64" ]; then
        colorecho "  ✗ Skipping IDA Free: only supported on x86_64"
        return 0
    fi
    if [ -x /opt/tools/idafree/ida64 ]; then
        colorecho "  ✓ IDA Free already installed"
        return 0
    fi
    colorecho "  → Installing IDA Free (GUI)"
    if curl -sSLf -o /tmp/idafree.run "https://out7.hex-rays.com/files/idafree84_linux.run"; then
        chmod +x /tmp/idafree.run
        /tmp/idafree.run --mode unattended --prefix /opt/tools/idafree \
            && ln -sf /opt/tools/idafree/ida64 /opt/tools/bin/ida64
        rm -f /tmp/idafree.run
    else
        colorecho "  ✗ Warning: Failed to download IDA Free"
    fi
}

function install_binaryninja() {
    # Binary Ninja Free (proprietary, GUI only, x86_64, ~450 MB download).
    # Heavy: gates the largest single tool in the image. Needs X to run.
    if [ "$(uname -m)" != "x86_64" ]; then
        colorecho "  ✗ Skipping Binary Ninja: only supported on x86_64"
        return 0
    fi
    if [ -x /opt/tools/binaryninja/binaryninja ]; then
        colorecho "  ✓ Binary Ninja already installed"
        return 0
    fi
    colorecho "  → Installing Binary Ninja Free (GUI, ~450 MB)"
    if curl -sSLf -o /tmp/binja.zip "https://cdn.binary.ninja/installers/binaryninja_free_linux.zip"; then
        unzip -q -o /tmp/binja.zip -d /opt/tools \
            && ln -sf /opt/tools/binaryninja/binaryninja /opt/tools/bin/binaryninja
        rm -f /tmp/binja.zip
    else
        colorecho "  ✗ Warning: Failed to download Binary Ninja"
    fi
}

function install_angr() {
    install_pipx_tool "angr" "angr"
}

function install_pycdc() {
    local install_dir="/opt/tools/pycdc"

    if command -v pycdc > /dev/null 2>&1; then
        colorecho "  ✓ pycdc already installed"
        return 0
    fi

    colorecho "  → Installing pycdc (Python bytecode decompiler)"
    pacman -S --noconfirm --needed cmake || true
    git clone --depth 1 https://github.com/zrax/pycdc.git "$install_dir" || {
        colorecho "  ✗ Warning: Failed to clone pycdc"
        return 1
    }
    cd "$install_dir" && cmake . && make || {
        colorecho "  ✗ Warning: Failed to build pycdc"
        return 1
    }
    ln -sf "$install_dir/pycdc" /opt/tools/bin/pycdc
    ln -sf "$install_dir/pycdas" /opt/tools/bin/pycdas
    cd - > /dev/null

    colorecho "  ✓ pycdc installed"
}

function install_uncompyle6() {
    install_pipx_tool "uncompyle6" "uncompyle6"
}

function install_nasm() {
    install_pacman_tool "nasm"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_reverse() {
    colorecho "Installing Reverse Engineering red-team tools"

    colorecho "  [pacman] Reverse tools:"
    install_ghidra
    install_nasm
    install_wabt

    colorecho "  [pipx] Reverse tools:"
    install_angr
    install_uncompyle6

    colorecho "  [git] Reverse tools:"
    install_pycdc

    colorecho "  [go] Reverse tools:"
    install_vt

    colorecho "  [download] Reverse / decompilers (GUI, need X):"
    install_jd-gui
    install_ida
    install_binaryninja

    colorecho "Reverse Engineering tools installation finished"
}
