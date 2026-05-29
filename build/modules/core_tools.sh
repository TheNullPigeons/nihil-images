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
    tmux \
    fzf \
    zoxide \
    curl \
    wget \
    asciinema \
    whois \
    xclip \
    gdb \
    rlwrap \
    bind && \
    pacman -Scc --noconfirm

    colorecho "Core tools installed"

    add-aliases "fzf"
    add-history "fzf"
    add-aliases "zoxide"
    add-history "zoxide"

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

