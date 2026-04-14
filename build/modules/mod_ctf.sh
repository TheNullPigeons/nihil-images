#!/bin/bash
# CTF-specific tools module
# Self-contained: all tools needed for CTF competitions in one module.
# Categories: Pwn, Reverse, Crypto, Forensics/Stego, Web, Network, Cracking, Misc

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/cargo
nihil::import lib/registry/pacman
nihil::import lib/registry/aur
nihil::import lib/registry/gem
nihil::import lib/registry/go
nihil::import lib/registry/git
nihil::import lib/registry/curl

# ===========================================================================
# Pwn / Binary Exploitation
# ===========================================================================

function install_pwntools() {
    install_pipx_tool "pwn" "pwntools"
}

function install_cmake() {
    install_pacman_tool "cmake"
}

function install_ropgadget() {
    install_pipx_tool "ROPgadget" "ROPgadget"
}

function install_radare2() {
    install_pacman_tool "radare2"
}

function install_strace() {
    install_pacman_tool "strace"
}

function install_ltrace() {
    install_pacman_tool "ltrace"
}

function install_pwndbg() {
    install_pacman_tool "pwndbg"
}

function install_one_gadget() {
    install_gem_tool "one_gadget"
}

function install_seccomp_tools() {
    install_gem_tool "seccomp-tools"
}

function install_checksec() {
    install_pacman_tool "checksec"
}

# ===========================================================================
# Reverse Engineering
# ===========================================================================

function install_ghidra() {
    install_pacman_tool "ghidra"
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
    ln -sf "$install_dir/pycdc" /usr/local/bin/pycdc
    ln -sf "$install_dir/pycdas" /usr/local/bin/pycdas
    cd - > /dev/null

    colorecho "  ✓ pycdc installed"
}

function install_uncompyle6() {
    install_pipx_tool "uncompyle6" "uncompyle6"
}

# ===========================================================================
# Crypto
# ===========================================================================

function install_rsactftool() {
    local repo_dir="/opt/tools/RsaCtfTool"
    local venv_dir="${repo_dir}/venv"

    if command -v RsaCtfTool > /dev/null 2>&1; then
        colorecho "  ✓ RsaCtfTool already installed"
        return 0
    fi

    colorecho "  → Installing RsaCtfTool (git + venv)"
    mkdir -p /opt/tools
    rm -rf "${repo_dir}"
    git clone --depth 1 "https://github.com/RsaCtfTool/RsaCtfTool.git" "${repo_dir}" || {
        colorecho "  ✗ Warning: Failed to clone RsaCtfTool"
        return 1
    }

    # Keep this venv isolated to avoid dependency clashes with pwndbg/pwntools stack.
    python3 -m venv "${venv_dir}" || {
        colorecho "  ✗ Warning: Failed to create RsaCtfTool venv"
        return 1
    }

    if ! (cd "${repo_dir}" && "${venv_dir}/bin/pip" install --quiet .); then
        colorecho "  ✗ Warning: Failed to install RsaCtfTool package"
        return 1
    fi

    cat > /usr/local/bin/RsaCtfTool <<EOF
#!/bin/sh
exec "${venv_dir}/bin/python3" -m RsaCtfTool.main "\$@"
EOF
    chmod +x /usr/local/bin/RsaCtfTool

    if ! command -v RsaCtfTool > /dev/null 2>&1; then
        colorecho "  ✗ Warning: RsaCtfTool command not available after installation"
        return 1
    fi

    colorecho "  ✓ RsaCtfTool installed"
}

function install_xortool() {
    install_pipx_tool "xortool" "xortool"
}

function install_z3_solver() {
    colorecho "  → Installing z3-solver"
    if python3 -c "import z3" 2>/dev/null; then
        colorecho "  ✓ z3-solver already installed"
        return 0
    fi
    python3 -m pip install --break-system-packages z3-solver --quiet 2>/dev/null || \
        python3 -m pip install z3-solver --quiet 2>/dev/null || {
        colorecho "  ✗ Warning: Failed to install z3-solver"
        return 1
    }
    cat > /usr/local/bin/z3-solver <<'EOF'
#!/bin/sh
exec python3 -c "import z3,sys; print(z3.get_version_string())"
EOF
    chmod +x /usr/local/bin/z3-solver
    colorecho "  ✓ z3-solver installed"
}

function install_pycryptodome() {
    colorecho "  → Installing pycryptodome"
    if ! python3 -c "import Crypto" 2>/dev/null; then
        python3 -m pip install --break-system-packages pycryptodome --quiet 2>/dev/null || \
            python3 -m pip install pycryptodome --quiet 2>/dev/null || {
            colorecho "  ✗ Warning: Failed to install pycryptodome"
            return 1
        }
    fi
    cat > /usr/local/bin/pycryptodome <<'EOF'
#!/bin/sh
exec python3 -c "import Crypto,sys; print(Crypto.__name__)"
EOF
    chmod +x /usr/local/bin/pycryptodome
    colorecho "  ✓ pycryptodome installed"
}

function install_hashid() {
    install_pipx_tool "hashid" "hashid"
}

# ===========================================================================
# Forensics / Steganography
# ===========================================================================

function install_volatility3() {
    install_pipx_tool "vol" "volatility3"
}

function install_foremost() {
    install_pacman_tool "foremost"
}

function install_binwalk() {
    install_pacman_tool "binwalk"
}

function install_exiftool() {
    install_pacman_tool "exiftool" || install_pacman_tool "perl-image-exiftool"
    if ! command -v exiftool > /dev/null 2>&1; then
        for p in \
            "/usr/bin/exiftool" \
            "/usr/bin/vendor_perl/exiftool" \
            "/usr/share/perl5/vendor_perl/Image/ExifTool/exiftool"
        do
            if [ -x "$p" ]; then
                add-symlink "$p" "exiftool"
                break
            fi
        done
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

# ===========================================================================
# Web CTF
# ===========================================================================

function install_sqlmap() {
    install_pacman_tool "sqlmap"
}

function install_ffuf() {
    install_go_tool "github.com/ffuf/ffuf/v2@latest" "ffuf"
}

function install_gobuster() {
    install_pacman_tool "gobuster"
}

function install_feroxbuster() {
    install_cargo_tool "feroxbuster"
}

function install_nikto() {
    install_pacman_tool "nikto"
}

function install_jwt_tool() {
    install_git_tool "jwt-tool" "https://github.com/ticarpi/jwt_tool.git" "jwt-tool.py"
}

function install_commix() {
    install_pipx_tool_git "commix" "https://github.com/commixproject/commix.git"
}

function install_ssrfmap() {
    install_git_tool "ssrfmap" "https://github.com/swisskyrepo/SSRFmap.git" "ssrfmap.py"
}

function install_tplmap() {
    install_git_tool "tplmap" "https://github.com/epinna/tplmap" "tplmap.py"
}

function install_httpie() {
    install_pacman_tool "httpie"
}

function install_nuclei() {
    install_go_tool "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
}

function install_dirsearch() {
    install_pipx_tool "dirsearch" "dirsearch"
}

# ===========================================================================
# Network
# ===========================================================================

function install_nmap() {
    install_pacman_tool "nmap"
}

function install_netcat() {
    install_pacman_tool "openbsd-netcat"
}

function install_socat() {
    install_pacman_tool "socat"
}

function install_wireshark_cli() {
    install_pacman_tool "wireshark-cli"
}

# ===========================================================================
# Cracking
# ===========================================================================

function install_john() {
    install_pacman_tool "john"
}

function install_hashcat() {
    install_pacman_tool "hashcat"
}

function install_seclists() {
    install_aur_tool "seclists" "seclists"
}

# ===========================================================================
# Misc / Resources
# ===========================================================================

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

function install_payloadsallthethings() {
    local install_dir="/opt/resources/PayloadsAllTheThings"
    colorecho "  → Cloning PayloadsAllTheThings"
    if [ ! -d "$install_dir" ]; then
        git clone --depth 1 "https://github.com/swisskyrepo/PayloadsAllTheThings.git" "$install_dir" || {
            colorecho "  ✗ Warning: Failed to clone PayloadsAllTheThings"
            return 1
        }
    fi
    colorecho "  ✓ PayloadsAllTheThings installed at $install_dir"
}

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
        curl -sSL "$latest_url" -o /tmp/cyberchef.zip && \
        pacman -S --noconfirm --needed unzip 2>/dev/null || true && \
        unzip -o /tmp/cyberchef.zip -d "$install_dir" && \
        rm -f /tmp/cyberchef.zip
        colorecho "  ✓ CyberChef installed at $install_dir"
    else
        colorecho "  ✗ Warning: Failed to fetch CyberChef release URL"
        return 1
    fi
}

# ===========================================================================
# Module entry point
# ===========================================================================

function install_mod_ctf() {
    colorecho "Installing CTF tools"

    # --- Pwn / Binary Exploitation ---
    colorecho "  [pwn] Binary exploitation tools:"
    install_cmake
    # Install pwndbg first from pacman to avoid later file conflicts with pipx
    # packages that can ship overlapping binaries (pwn / ROPgadget).
    install_pwndbg
    install_pwntools
    install_ropgadget
    install_radare2
    install_strace
    install_ltrace
    install_one_gadget
    install_seccomp_tools
    install_checksec
    # --- Reverse Engineering ---
    colorecho "  [reverse] Reverse engineering tools:"
    install_ghidra
    install_angr
    install_pycdc
    install_uncompyle6

    # --- Crypto ---
    colorecho "  [crypto] Cryptography tools:"
    install_rsactftool
    install_xortool
    install_z3_solver
    install_pycryptodome
    install_hashid

    # --- Forensics / Steganography ---
    colorecho "  [forensics] Forensics and steganography tools:"
    install_volatility3
    install_foremost
    install_binwalk
    install_exiftool
    install_steghide
    install_zsteg
    install_stegseek
    install_openstego

    # --- Web CTF ---
    colorecho "  [web] Web exploitation tools:"
    install_sqlmap
    install_ffuf
    install_gobuster
    install_feroxbuster
    install_nikto
    install_jwt_tool
    install_commix
    install_ssrfmap
    install_tplmap
    install_httpie
    install_nuclei
    install_dirsearch

    # --- Network ---
    colorecho "  [network] Network tools:"
    install_nmap
    install_netcat
    install_socat
    install_wireshark_cli

    # --- Cracking ---
    colorecho "  [cracking] Password cracking tools:"
    install_john
    install_hashcat
    install_seclists

    # --- Misc / Resources ---
    colorecho "  [misc] Misc tools and resources:"
    install_searchsploit
    install_payloadsallthethings
    install_cyberchef

    colorecho "CTF tools installation finished"
}
