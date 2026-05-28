#!/bin/bash
# Red-team tools for Web / HTTP
# Each tool has its own install_$TOOL function for easier maintenance.

nihil::import lib/common
nihil::import lib/registry/pipx
nihil::import lib/registry/cargo
nihil::import lib/registry/pacman
nihil::import lib/registry/aur
nihil::import lib/registry/curl
nihil::import lib/registry/git
nihil::import lib/registry/go
nihil::import lib/registry/gem

# ---------------------------------------------------------------------------
# Individual install functions
# ---------------------------------------------------------------------------

function install_sqlmap() {
    install_pacman_tool "sqlmap"
}

function install_swaks() {
    install_pacman_tool "swaks"
}

function install_mail() {
    install_pacman_tool "mailutils"
    install_pacman_tool "msmtp"
    install_pacman_tool "msmtp-mta"
    ln -sf /usr/bin/gnu-mail /usr/local/bin/mail
}

function install_gobuster() {
    install_pacman_tool "gobuster"
}

function install_nikto() {
    install_pacman_tool "nikto"
}

function install_wfuzz() {
    install_pipx_tool_git "wfuzz" "https://github.com/xmendez/wfuzz.git"
}

function install_arjun() {
    install_pipx_tool_git "arjun" "https://github.com/s0md3v/Arjun.git"
}

function install_wafw00f() {
    install_pipx_tool "wafw00f" "wafw00f"
}

function install_gopherus() {
    install_pipx_tool_git "gopherus3" "https://github.com/Esonhugh/Gopherus3.git"
    add-symlink "/root/.local/bin/gopherus3" "gopherus"
}

function install_droopescan() {
    install_pipx_tool_git "droopescan" "https://github.com/SamJoan/droopescan.git"
}

function install_cmsmap() {
    install_pipx_tool_git "cmsmap" "https://github.com/dionach/CMSmap.git"
}

function install_ssrfmap() {
    install_git_tool "ssrfmap" "https://github.com/swisskyrepo/SSRFmap.git" "ssrfmap.py"
}

function install_jwt_tool() {
    install_git_tool "jwt-tool" "https://github.com/ticarpi/jwt_tool.git" "jwt-tool.py"
}

function install_xsstrike() {
    install_git_tool "xsstrike" "https://github.com/s0md3v/XSStrike.git" "xsstrike.py"
}

function install_feroxbuster() {
    install_cargo_tool "feroxbuster"
}

function install_testssl() {
    install_download_tool "testssl.sh" "https://raw.githubusercontent.com/drwetter/testssl.sh/v3.2.2/testssl.sh"
}

# ---------------------------------------------------------------------------
# Scanners / Discovery (ProjectDiscovery suite + others)
# ---------------------------------------------------------------------------

function install_nuclei() {
    install_go_tool "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
}

function install_httpx_pd() {
    install_go_tool "github.com/projectdiscovery/httpx/cmd/httpx@latest"
}

function install_subfinder() {
    install_go_tool "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
}

function install_katana() {
    install_go_tool "github.com/projectdiscovery/katana/cmd/katana@latest"
}

function install_ffuf() {
    install_go_tool "github.com/ffuf/ffuf/v2@latest" "ffuf"
}

function install_dirsearch() {
    install_pipx_tool "dirsearch" "dirsearch"
}

function install_whatweb() {
    install_git_tool "whatweb" "https://github.com/urbanadventurer/WhatWeb.git" "whatweb"
}

function install_hakrawler() {
    install_go_tool "github.com/hakluke/hakrawler@latest"
}

function install_gau() {
    install_go_tool "github.com/lc/gau/v2/cmd/gau@latest"
}

function install_waybackurls() {
    install_go_tool "github.com/tomnomnom/waybackurls@latest"
}

# ---------------------------------------------------------------------------
# Exploitation
# ---------------------------------------------------------------------------

function install_commix() {
    install_pipx_tool_git "commix" "https://github.com/commixproject/commix.git"
}

function install_tplmap() {
    install_git_tool "tplmap" "https://github.com/epinna/tplmap" "tplmap.py"
}

function install_nosqlmap() {
    install_git_tool_venv "nosqlmap" "https://github.com/codingo/NoSQLMap" "nosqlmap.py" "" "yes"
}

function install_graphqlmap() {
    install_pipx_tool_git "graphqlmap" "https://github.com/swisskyrepo/GraphQLmap.git"
}

function install_corsy() {
    install_git_tool "corsy" "https://github.com/s0md3v/Corsy" "corsy.py"
}

function install_crlfuzz() {
    install_go_tool "github.com/dwisiswant0/crlfuzz/cmd/crlfuzz@latest"
}

# ---------------------------------------------------------------------------
# Proxy / Interception
# ---------------------------------------------------------------------------

function install_mitmproxy() {
    install_pipx_tool "mitmproxy" "mitmproxy" "mitmdump"
}

# ---------------------------------------------------------------------------
# API Testing / HTTP clients
# ---------------------------------------------------------------------------

function install_kiterunner() {
    install_tar_tool "kiterunner" \
        "https://github.com/assetnote/kiterunner/releases/download/v{version}/kiterunner_{version}_linux_amd64.tar.gz" \
        "/usr/local/share/kiterunner/{version}" \
        "kr" \
        "kr kiterunner" \
        "" \
        "1.0.2"
}

function install_httpie() {
    install_pacman_tool "httpie"
}

function install_caido() {
    local caido_bin
    local caido_cli_bin
    local arch
    local release_json

    colorecho "  → Installing Caido (desktop + CLI)"

    # Runtime deps for the desktop app (Electron/GTK)
    local electron_deps=(
        atk
        at-spi2-atk
        at-spi2-core
        gtk3
        nss
        libxss
        libdrm
        libxcomposite
        libxdamage
        libxrandr
        mesa
        xdg-utils
        alsa-lib
    )
    for dep in "${electron_deps[@]}"; do
        install_pacman_tool "$dep" || true
    done

    # 1) Try AUR first on Arch
    install_aur_tool "caido-desktop" "caido" || colorecho "  ✗ Warning: Failed to install caido-desktop from AUR"
    install_aur_tool "caido-cli" "caido-cli" || colorecho "  ✗ Warning: Failed to install caido-cli from AUR"

    # 2) Normalize paths for healthcheck expectations
    caido_bin="$(command -v caido 2>/dev/null || true)"
    if [ -n "$caido_bin" ]; then
        ln -sf "$caido_bin" /opt/tools/bin/caido
    fi
    caido_cli_bin="$(command -v caido-cli 2>/dev/null || true)"
    if [ -n "$caido_cli_bin" ]; then
        ln -sf "$caido_cli_bin" /opt/tools/bin/caido-cli
    fi

    if [ -x /opt/tools/bin/caido ] && command -v caido-cli >/dev/null 2>&1; then
        colorecho "  ✓ Caido binaries detected"
        add-aliases "caido"
        add-history "caido"
        return 0
    fi

    # 3) Fallback: install from upstream release assets
    colorecho "  → Falling back to upstream release downloads"
    arch="$(uname -m)"

    release_json="$(curl -fsSL https://api.caido.io/releases/latest 2>/dev/null)" || release_json=""
    if [ -z "$release_json" ]; then
        colorecho "  ✗ Warning: Failed to fetch Caido release metadata"
        return 0
    fi

    local appimage_url
    local cli_url

    appimage_url="$(ARCH="$arch" python3 -c 'import sys, json, os
data=json.load(sys.stdin)
arch=os.environ.get("ARCH","")
assets=data.get("assets",[])
links=[a.get("link","") for a in assets if a.get("link")]
app=[l for l in links if l.endswith(".AppImage")]
if not app:
    print("")
    raise SystemExit
arch_map={
  "x86_64":["amd64","x86_64","linux-x86_64","linux-amd64"],
  "aarch64":["arm64","aarch64","linux-arm64","linux-aarch64"],
  "armv7l":["armv7l","arm-linux-gnueabihf","linux-armv7l"],
}
want=arch_map.get(arch,[arch])
for w in want:
    if not w: 
        continue
    for l in app:
        if w in l:
            print(l)
            raise SystemExit
print(app[0])' <<<"$release_json")"

    cli_url="$(ARCH="$arch" python3 -c 'import sys, json, os
data=json.load(sys.stdin)
arch=os.environ.get("ARCH","")
assets=data.get("assets",[])
links=[a.get("link","") for a in assets if a.get("link")]
cli=[l for l in links if "caido-cli" in l and l.endswith(".tar.gz")]
if not cli:
    print("")
    raise SystemExit
arch_map={
  "x86_64":["amd64","x86_64","linux-x86_64","linux-amd64"],
  "aarch64":["arm64","aarch64","linux-arm64","linux-aarch64"],
  "armv7l":["armv7l","arm-linux-gnueabihf","linux-armv7l"],
}
want=arch_map.get(arch,[arch])
for w in want:
    if not w:
        continue
    for l in cli:
        if w in l:
            print(l)
            raise SystemExit
print(cli[0])' <<<"$release_json")"

    mkdir -p /opt/tools/caido /opt/tools/bin

    if [ -n "$appimage_url" ]; then
        local appimage_name
        appimage_name="$(basename "$appimage_url")"
        if curl -fsSL "$appimage_url" -o "/opt/tools/caido/${appimage_name}" 2>/dev/null; then
            chmod +x "/opt/tools/caido/${appimage_name}" || true
            ln -sf "/opt/tools/caido/${appimage_name}" /opt/tools/bin/caido
        fi
    fi

    if [ -n "$cli_url" ]; then
        local cli_archive
        cli_archive="/tmp/$(basename "$cli_url")"
        if curl -fsSL "$cli_url" -o "$cli_archive" 2>/dev/null; then
            if tar -xzf "$cli_archive" -C /opt/tools/bin 2>/dev/null; then
                if [ -f /opt/tools/bin/caido-cli ]; then
                    chmod +x /opt/tools/bin/caido-cli || true
                    ln -sf /opt/tools/bin/caido-cli /opt/tools/bin/caido-cli
                else
                    local extracted
                    extracted="$(python3 -c 'import os
root="/opt/tools/bin"
target="caido-cli"
for dp,_,files in os.walk(root):
  for f in files:
    if f==target:
      print(os.path.join(dp,f))
      raise SystemExit
print("")')"
                    if [ -n "$extracted" ] && [ -f "$extracted" ]; then
                        chmod +x "$extracted" || true
                        ln -sf "$extracted" /opt/tools/bin/caido-cli
                    fi
                fi
            fi
            rm -f "$cli_archive" || true
        fi
    fi

    add-aliases "caido"
    add-history "caido"
}

# ---------------------------------------------------------------------------
# Burp Suite Community
# ---------------------------------------------------------------------------

function install_wpscan() {
    install_gem_tool "wpscan"
    add-history "wpscan"
}


function install_eyewitness() {
    local tool_name="EyeWitness"
    local git_url="https://github.com/RedSiege/EyeWitness.git"
    local repo_dir="${GIT_INSTALL_DIR}/${tool_name}"
    local venv_dir="${repo_dir}/venv"

    if command -v EyeWitness > /dev/null 2>&1; then
        colorecho "  ✓ EyeWitness already installed"
        return 0
    fi

    colorecho "  → Installing EyeWitness"
    git clone --depth=1 "$git_url" "$repo_dir" || {
        colorecho "  ✗ Warning: Failed to clone EyeWitness"
        return 1
    }

    python3 -m venv "$venv_dir" || return 1
    source "$venv_dir/bin/activate"
    pip install --quiet selenium Pillow fuzzywuzzy python-Levenshtein requests netaddr || {
        colorecho "  ✗ Warning: Failed to install EyeWitness requirements"
        deactivate
        return 1
    }
    deactivate

    mkdir -p "$GIT_BIN_DIR"
    cat > "${GIT_BIN_DIR}/EyeWitness" << EOF
#!/bin/sh
cd "$repo_dir/Python" || exit 1
source "$venv_dir/bin/activate"
exec python3 "$repo_dir/Python/EyeWitness.py" "\$@"
EOF
    chmod +x "${GIT_BIN_DIR}/EyeWitness"
    add-history "EyeWitness"
    colorecho "  ✓ EyeWitness installed"
}

function install_burpsuite() {
    colorecho "  → Installing Burp Suite Community"
    install_pacman_tool "jdk-openjdk"
    install_pacman_tool "nss"
    install_pacman_tool "ttf-dejavu"
    install_pacman_tool "freetype2"
    local burp_dir="/opt/tools/BurpSuiteCommunity"
    mkdir -p "$burp_dir"
    wget -q "https://portswigger.net/burp/releases/download?product=community&type=Jar" \
        -O "${burp_dir}/BurpSuiteCommunity.jar"
    file "${burp_dir}/BurpSuiteCommunity.jar" | grep -q "Java archive" \
        || { colorecho "  ✗ Downloaded file is not a valid JAR"; exit 1; }
    cp /opt/nihil/build/assets/burpsuite/conf.json "${burp_dir}/conf.json"
    mkdir -p /root/.BurpSuite
    cp /opt/nihil/build/assets/burpsuite/UserConfigCommunity.json /root/.BurpSuite/UserConfigCommunity.json
    mkdir -p /etc/fonts/conf.d
    cp /opt/nihil/build/assets/fontconfig/local.conf /etc/fonts/local.conf
    fc-cache -fv > /dev/null 2>&1 || true
    local java_bin
    java_bin=$(archlinux-java get 2>/dev/null | xargs -I{} echo "/usr/lib/jvm/{}/bin/java")
    [[ -x "$java_bin" ]] || java_bin=$(which java)
    printf '#!/bin/bash\nexec %s -Dawt.useSystemAAFontSettings=lcd -Dswing.aatext=true -jar -Xmx4g /opt/tools/BurpSuiteCommunity/BurpSuiteCommunity.jar "$@"\n' "$java_bin" \
        > /opt/tools/bin/burpsuite
    chmod +x /opt/tools/bin/burpsuite
    colorecho "  ✓ Burp Suite Community installed at ${burp_dir}"
}

function install_bbot() {
    install_pipx_tool "bbot" "bbot"
}

function install_byp4xx() {
    install_go_tool "github.com/lobuhi/byp4xx@latest"
}

function install_git_dumper() {
    install_pipx_tool "git-dumper" "git-dumper"
}

function install_gowitness() {
    install_go_tool "github.com/sensepost/gowitness@latest"
}

function install_httpmethods() {
    install_pipx_tool_git "httpmethods" "https://github.com/ShutdownRepo/httpmethods.git"
}

function install_joomscan() {
    install_pacman_tool "perl"
    install_git_tool_symlink "/opt/tools/joomscan" \
        "https://github.com/OWASP/joomscan.git" \
        "joomscan.pl" \
        "joomscan"
}

function install_linkfinder() {
    install_git_tool "linkfinder" "https://github.com/GerbenJavado/LinkFinder.git" "linkfinder.py"
}

function install_naabu() {
    install_go_tool "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
}

function install_patator() {
    # setuptools>=82 removed pkg_resources which patator imports at runtime
    install_git_tool_venv "patator" "https://github.com/lanjelot/patator.git" "src/patator/patator.py" "setuptools<82 ldap3 paramiko impacket dnspython pyotp requests" "yes"
}

function install_phpggc() {
    install_git_tool_symlink "/opt/tools/phpggc" \
        "https://github.com/ambionics/phpggc.git" \
        "phpggc" \
        "phpggc"
}

function install_smuggler() {
    install_git_tool "smuggler" "https://github.com/defparam/smuggler.git" "smuggler.py"
}

function install_sslscan() {
    install_pacman_tool "sslscan"
}

function install_xxeinjector() {
    install_git_tool_symlink "/opt/tools/XXEinjector" \
        "https://github.com/enjoiz/XXEinjector.git" \
        "XXEinjector.rb" \
        "xxeinjector"
}

function install_ysoserial() {
    local jar_dir="/opt/tools/ysoserial"
    local jar_file="${jar_dir}/ysoserial.jar"

    if command -v ysoserial >/dev/null 2>&1; then
        colorecho "  ✓ ysoserial already installed"
        return 0
    fi

    colorecho "  → Installing ysoserial"
    mkdir -p "$jar_dir"
    local tag
    tag=$(curl -Ls -o /dev/null -w '%{url_effective}' \
        "https://github.com/frohoff/ysoserial/releases/latest" | sed 's:.*/::' || true)
    if [ -z "$tag" ]; then
        colorecho "  ✗ Warning: Failed to resolve ysoserial version"
        return 0
    fi
    if ! curl -fsSL "https://github.com/frohoff/ysoserial/releases/download/${tag}/ysoserial-all.jar" \
            -o "$jar_file" 2>/dev/null; then
        colorecho "  ✗ Warning: Failed to download ysoserial"
        return 0
    fi
    local java_bin
    java_bin=$(command -v java 2>/dev/null || echo "java")
    printf '#!/bin/bash\nexec %s -jar %s "$@"\n' "$java_bin" "$jar_file" > /opt/tools/bin/ysoserial
    chmod +x /opt/tools/bin/ysoserial
    colorecho "  ✓ ysoserial installed (${tag})"
}

# ---------------------------------------------------------------------------
# Module entry point
# ---------------------------------------------------------------------------

function install_mod_web() {
    colorecho "Installing Web red-team tools"

    colorecho "  [pacman] Web scanners / fuzzers:"
    install_sqlmap
    install_gobuster
    install_nikto
    install_httpie
    install_swaks
    install_mail
    install_sslscan

    colorecho "  [pipx] Web fuzzers / scanners:"
    install_wfuzz
    install_arjun
    install_wafw00f
    install_gopherus
    install_droopescan
    install_cmsmap
    install_dirsearch
    install_commix
    install_mitmproxy
    install_bbot
    install_git_dumper
    install_httpmethods
    install_linkfinder
    install_patator

    colorecho "  [pipx-git] Web scanners:"
    install_graphqlmap

    colorecho "  [go] Web scanners / discovery:"
    install_nuclei
    install_httpx_pd
    install_subfinder
    install_katana
    install_ffuf
    install_hakrawler
    install_gau
    install_waybackurls
    install_crlfuzz
    install_byp4xx
    install_gowitness
    install_naabu

    colorecho "  [gem] CMS scanners:"
    install_wpscan

    colorecho "  [git] Scripts (clone + requirements):"
    install_ssrfmap
    install_jwt_tool
    install_xsstrike
    install_tplmap
    install_nosqlmap
    install_corsy
    install_whatweb
    install_eyewitness
    install_joomscan
    install_phpggc
    install_smuggler
    install_xxeinjector

    colorecho "  [cargo] Web fuzzer:"
    install_feroxbuster

    colorecho "  [curl/download] Web tools:"
    install_testssl
    install_kiterunner
    install_caido
    install_burpsuite

    install_ysoserial

    colorecho "Web tools installation finished"
}
