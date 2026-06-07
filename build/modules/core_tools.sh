#!/bin/bash
# Core CLI / workstation tools (non-spécifiques red-team)
#
# Ici on met tout ce qui est confort d'utilisation dans le conteneur :
# éditeurs, multiplexeurs, utilitaires réseau génériques, etc.

nihil::import lib/common
nihil::import lib/registry/pipx

function install_core_tools() {
    colorecho "Installing core CLI tools (editors, tmux, fzf, etc.)"

    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed \
    vim \
    nano \
    neovim \
    less \
    tmux \
    fzf \
    zoxide \
    yazi \
    fd \
    ripgrep \
    chafa \
    feh \
    zathura \
    zathura-pdf-mupdf \
    thunar \
    xdg-utils \
    curl \
    wget \
    asciinema \
    whois \
    xclip \
    gdb \
    rlwrap \
    bind \
    xcb-util-cursor && \
    pacman -Scc --noconfirm

    # D-Bus machine-id: GTK/Qt apps like thunar fail to start in a container
    # without it ("Cannot spawn a message bus without a machine-id").
    if [ ! -s /etc/machine-id ]; then
        (command -v dbus-uuidgen >/dev/null 2>&1 && dbus-uuidgen --ensure=/etc/machine-id) \
            || systemd-machine-id-setup >/dev/null 2>&1 || true
    fi
    mkdir -p /var/lib/dbus && ln -sf /etc/machine-id /var/lib/dbus/machine-id

    colorecho "Core tools installed"

    add-aliases "fzf"
    add-history "fzf"
    add-aliases "zoxide"
    add-history "zoxide"
    add-aliases "yazi"
    add-history "yazi"
    install -Dm644 "${NIHIL_BUILD}/config/yazi/yazi.toml" /root/.config/yazi/yazi.toml
    # Lightweight default viewers, so `open`/yazi launch a real window (on the
    # host display when the container runs with --enable-x11): feh for images,
    # zathura for PDFs. Both behave better in a container than chromium.
    if command -v xdg-mime >/dev/null 2>&1; then
        xdg-mime default feh.desktop \
            image/png image/jpeg image/gif image/webp image/bmp image/x-icon image/tiff image/svg+xml \
            >/dev/null 2>&1 || true
        xdg-mime default org.pwmt.zathura.desktop application/pdf >/dev/null 2>&1 || true
    fi

    colorecho "Installing nihil-history"
    install_pipx_tool_git "nihil-history" "https://github.com/TheNullPigeons/nihil-history"
    add-symlink "/root/.local/bin/nhi" "nhi"
    colorecho "nihil-history installed"

    install_nihil_ntp
}

# nihil-ntp: point every terminal at a chosen NTP server (typically the DC) so
# Kerberos does not reject tickets for clock skew. Needs the ntp + libfaketime
# packages, both already pulled by package_base.
function install_nihil_ntp() {
    colorecho "Installing nihil-ntp"
    local assets="${NIHIL_BUILD}/lib/installers/nihil-ntp"
    local hook_dir="/opt/nihil/config/nihil-ntp"

    install -Dm755 "${assets}/nihil-ntp" /opt/tools/bin/nihil-ntp
    install -Dm644 "${assets}/hook.sh" "${hook_dir}/hook.sh"

    # zsh tab-completion: drop in the default site-functions fpath so the
    # compinit run by oh-my-zsh autoloads it at shell startup.
    install -Dm644 "${assets}/_nihil-ntp" /usr/share/zsh/site-functions/_nihil-ntp

    # Source the hook from every interactive shell. zsh reads the baked-in
    # /root/.zshrc (which already carries the source line); wire bash too.
    local src_line="[ -f ${hook_dir}/hook.sh ] && source ${hook_dir}/hook.sh"
    if [ -f /root/.bashrc ] && ! grep -qF "${hook_dir}/hook.sh" /root/.bashrc; then
        printf '\n# nihil-ntp shell hook\n%s\n' "${src_line}" >>/root/.bashrc
    fi

    add-history "nihil-ntp"
    colorecho "nihil-ntp installed"
}

