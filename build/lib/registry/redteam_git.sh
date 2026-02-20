#!/bin/bash
# Registry pour installation d'outils via Git (clone + build/install personnalisable)
# Supporte : pip requirements.txt, make, make install, ou toute commande shell.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

GIT_INSTALL_DIR="${GIT_INSTALL_DIR:-/usr/local/share}"
GIT_BIN_DIR="${GIT_BIN_DIR:-/root/.local/bin}"

# Usage: install_git_tool_symlink "install_dir" "git_url" "script_name" ["cmd_name"] ["alias_name"]
#
#   install_dir  : chemin complet du clone (ex: /opt/tools/exploitdb)
#   git_url      : URL du dépôt Git
#   script_name  : nom du script exécutable à la racine du repo (ex: searchsploit)
#   cmd_name     : (optionnel) nom dans le PATH, défaut = script_name
#   alias_name   : (optionnel) nom pour aliases/history, défaut = cmd_name
#
# Pas de wrapper : symlink direct du script (pour outils qui utilisent des chemins relatifs au repo).
# Exemple: install_git_tool_symlink "/opt/tools/exploitdb" "https://gitlab.com/exploit-database/exploitdb.git" "searchsploit"
install_git_tool_symlink() {
    local install_dir="$1"
    local git_url="$2"
    local script_name="$3"
    local cmd_name="${4:-$script_name}"
    local alias_name="${5:-$cmd_name}"
    local script_path="$install_dir/$script_name"

    if command -v "$cmd_name" >/dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (git)"
        add-aliases "$alias_name"
        add-history "$alias_name"
        return 0
    fi

    colorecho "  → Installing $cmd_name via Git ($git_url)"
    mkdir -p "$(dirname "$install_dir")"
    if [ ! -d "$install_dir" ]; then
        git clone --depth 1 "$git_url" "$install_dir" || {
            colorecho "  ✗ Failed to clone $(basename "$install_dir")"
            return 1
        }
    fi

    if [ ! -f "$script_path" ]; then
        colorecho "  ✗ Script $script_name not found in $install_dir"
        return 1
    fi

    mkdir -p "$GIT_BIN_DIR"
    ln -sf "$script_path" "$GIT_BIN_DIR/$cmd_name"

    add-aliases "$alias_name"
    add-history "$alias_name"
    colorecho "  ✓ $cmd_name installed"
    return 0
}

# Usage: install_git_tool "cmd_name" "git_url" ["entrypoint"] ["install_cmd"] ["exclude_deps"]
#
#   cmd_name     : nom de la commande (dans PATH)
#   git_url      : URL du dépôt Git
#   entrypoint   : (optionnel) script/binaire relatif au repo (ex: ssrfmap.py, build/tool).
#                  Si vide et install_cmd fourni, on suppose que l'install met le binaire dans PATH.
#   install_cmd  : (optionnel) commande à exécuter dans le repo après clone (ex: "make", "make install").
#                  Si vide : pip install -r requirements.txt si le fichier existe.
#   exclude_deps : (optionnel) pattern regex pour exclure des dépendances de requirements.txt
#
# Exemples:
#   install_git_tool "ssrfmap" "https://github.com/swisskyrepo/SSRFmap.git" "ssrfmap.py"
#   install_git_tool "outil_c" "https://github.com/..." "" "make && make install"
#   install_git_tool "autre" "https://github.com/..." "bin/autre" "make"
#   install_git_tool "patator" "https://github.com/..." "patator.py" "" "cx-oracle|cx_Oracle"
install_git_tool() {
    local cmd_name="$1"
    local git_url="$2"
    local entrypoint="${3:-}"
    local install_cmd="${4:-}"
    local exclude_deps="${5:-}"
    local repo_dir="${GIT_INSTALL_DIR}/${cmd_name}"
    local wrapper="${GIT_BIN_DIR}/${cmd_name}"

    if command -v "$cmd_name" >/dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (git)"
        return 0
    fi

    colorecho "  → Installing $cmd_name via Git ($git_url)"
    if [ ! -d "$repo_dir" ]; then
        git clone --depth=1 "$git_url" "$repo_dir" || {
            colorecho "  ✗ Warning: Failed to clone $cmd_name"
            return 1
        }
    fi

    # Étape build/install
    if [ -n "$install_cmd" ]; then
        (cd "$repo_dir" && eval "$install_cmd") || {
            colorecho "  ✗ Warning: Install command failed for $cmd_name"
            return 1
        }
    else
        # Comportement par défaut : pip -r requirements.txt si présent
        if [ -f "$repo_dir/requirements.txt" ]; then
            if [ -n "$exclude_deps" ]; then
                # Exclure certaines dépendances (ex: cx-oracle pour patator)
                grep -vE "$exclude_deps" "$repo_dir/requirements.txt" | \
                    python3 -m pip install --break-system-packages -r /dev/stdin --quiet 2>/dev/null || \
                    python3 -m pip install -r /dev/stdin --quiet 2>/dev/null || true
            else
                python3 -m pip install --break-system-packages -r "$repo_dir/requirements.txt" --quiet 2>/dev/null || \
                    python3 -m pip install -r "$repo_dir/requirements.txt" --quiet 2>/dev/null || true
            fi
        fi
    fi

    # Wrapper si entrypoint fourni
    if [ -n "$entrypoint" ]; then
        mkdir -p "$GIT_BIN_DIR"
        local full_path="$repo_dir/$entrypoint"
        if [[ "$entrypoint" == *.py ]]; then
            printf '%s\n' '#!/bin/sh' "exec python3 $full_path \"\$@\"" > "$wrapper"
        else
            printf '%s\n' '#!/bin/sh' "exec $full_path \"\$@\"" > "$wrapper"
        fi
        chmod +x "$wrapper"
    fi

    # Ajouter aliases et history si disponibles
    add-aliases "$cmd_name"
    add-history "$cmd_name"

    colorecho "  ✓ $cmd_name installed"
    return 0
}

# Usage: install_git_tool_venv "tool_name" "git_url" "entrypoints..." ["pip_packages"] ["use_system_site_packages"]
#
#   tool_name              : nom de l'outil (pour le répertoire)
#   git_url                : URL du dépôt Git
#   entrypoints            : liste des scripts Python à wrapper (ex: "krbrelayx.py addspn.py")
#   pip_packages           : (optionnel) packages pip à installer, séparés par des espaces. 
#                            Si vide et requirements.txt existe, utilise requirements.txt
#   use_system_site_packages : (optionnel) "yes" pour --system-site-packages, défaut: "no"
#
# Exemple:
#   install_git_tool_venv "krbrelayx" "https://github.com/dirkjanm/krbrelayx.git" "krbrelayx.py addspn.py printerbug.py" "dnspython ldap3 impacket dsinternals" "yes"
install_git_tool_venv() {
    local tool_name="$1"
    local git_url="$2"
    local entrypoints="$3"
    local pip_packages="${4:-}"
    local use_system_site="${5:-no}"
    local repo_dir="${GIT_INSTALL_DIR}/${tool_name}"
    local venv_dir="${repo_dir}/venv"

    if [ -z "$entrypoints" ]; then
        colorecho "  ✗ Error: install_git_tool_venv requires at least one entrypoint"
        return 1
    fi

    # Vérifier si déjà installé (vérifier le premier entrypoint)
    local first_entrypoint=$(echo "$entrypoints" | awk '{print $1}')
    if command -v "$(basename "$first_entrypoint" .py)" >/dev/null 2>&1; then
        colorecho "  ✓ $tool_name already installed (git+venv)"
        return 0
    fi

    colorecho "  → Installing $tool_name via Git with venv ($git_url)"
    
    # Cloner le repo
    if [ ! -d "$repo_dir" ]; then
        git clone --depth=1 "$git_url" "$repo_dir" || {
            colorecho "  ✗ Warning: Failed to clone $tool_name"
            return 1
        }
    fi

    # Créer le venv
    if [ ! -d "$venv_dir" ]; then
        if [ "$use_system_site" = "yes" ]; then
            python3 -m venv --system-site-packages "$venv_dir" || {
                colorecho "  ✗ Warning: Failed to create venv for $tool_name"
                return 1
            }
        else
            python3 -m venv "$venv_dir" || {
                colorecho "  ✗ Warning: Failed to create venv for $tool_name"
                return 1
            }
        fi
    fi

    # Activer le venv et installer les dépendances
    source "$venv_dir/bin/activate" || {
        colorecho "  ✗ Warning: Failed to activate venv for $tool_name"
        return 1
    }

    if [ -n "$pip_packages" ]; then
        # Installer les packages spécifiés
        pip install --quiet $pip_packages || {
            colorecho "  ✗ Warning: Failed to install pip packages for $tool_name"
            deactivate
            return 1
        }
    elif [ -f "$repo_dir/requirements.txt" ]; then
        # Utiliser requirements.txt si présent
        pip install --quiet -r "$repo_dir/requirements.txt" || {
            colorecho "  ✗ Warning: Failed to install requirements.txt for $tool_name"
            deactivate
            return 1
        }
    fi

    deactivate

    # Créer les wrappers pour chaque entrypoint
    mkdir -p "$GIT_BIN_DIR"
    for entrypoint in $entrypoints; do
        local cmd_name=$(basename "$entrypoint" .py)
        local wrapper="${GIT_BIN_DIR}/${cmd_name}"
        local full_path="$repo_dir/$entrypoint"
        
        if [ ! -f "$full_path" ]; then
            colorecho "  ✗ Warning: Entrypoint $entrypoint not found in $repo_dir"
            continue
        fi

        # Créer le wrapper qui active le venv et exécute le script
        cat > "$wrapper" <<EOF
#!/bin/sh
cd "$repo_dir" || exit 1
source "$venv_dir/bin/activate"
exec python3 "$full_path" "\$@"
EOF
        chmod +x "$wrapper"
        colorecho "  ✓ Created wrapper: $cmd_name"
    done

    # Ajouter aliases et history si disponibles
    add-aliases "$tool_name"
    add-history "$tool_name"

    colorecho "  ✓ $tool_name installed"
    return 0
}

# Usage: install_git_tool_bundler "tool_name" "git_url" "entrypoints..." ["system_deps"] ["extra_gems"] ["bundle_args"] ["alias_name"]
#
#   tool_name     : nom de l'outil (pour le répertoire)
#   git_url       : URL du dépôt Git
#   entrypoints   : liste des scripts Ruby à wrapper (ex: "msfconsole msfvenom msfdb")
#   system_deps   : (optionnel) dépendances système à installer via pacman, séparées par des espaces
#   extra_gems    : (optionnel) gems supplémentaires à installer, séparées par des espaces
#   bundle_args   : (optionnel) arguments supplémentaires pour bundle install (ex: "--without test development")
#   alias_name    : (optionnel) nom à utiliser pour aliases/history (par défaut: tool_name)
#
# Exemple:
#   install_git_tool_bundler "metasploit-framework" "https://github.com/rapid7/metasploit-framework.git" "msfconsole msfvenom msfdb" "ruby ruby-bundler postgresql libpcap" "rex rex-text timeout:0.4.1" "--without test development" "metasploit"
install_git_tool_bundler() {
    local tool_name="$1"
    local git_url="$2"
    local entrypoints="$3"
    local system_deps="${4:-ruby ruby-bundler}"
    local extra_gems="${5:-}"
    local bundle_args="${6:-}"
    local alias_name="${7:-$tool_name}"
    local repo_dir="${GIT_INSTALL_DIR}/${tool_name}"

    if [ -z "$entrypoints" ]; then
        colorecho "  ✗ Error: install_git_tool_bundler requires at least one entrypoint"
        return 1
    fi

    # Vérifier si déjà installé (vérifier le premier entrypoint)
    local first_entrypoint=$(echo "$entrypoints" | awk '{print $1}')
    if command -v "$first_entrypoint" >/dev/null 2>&1; then
        colorecho "  ✓ $tool_name already installed (git+bundler)"
        return 0
    fi

    colorecho "  → Installing $tool_name via Git with Bundler ($git_url)"

    # Installer les dépendances système
    if [ -n "$system_deps" ]; then
        colorecho "  → Installing system dependencies"
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm --needed $system_deps || {
            colorecho "  ✗ Warning: Failed to install some system dependencies"
            return 1
        }
    fi

    # Cloner le repo
    if [ ! -d "$repo_dir" ]; then
        git clone --depth=1 "$git_url" "$repo_dir" || {
            colorecho "  ✗ Warning: Failed to clone $tool_name"
            return 1
        }
    fi

    cd "$repo_dir" || return 1

    # Configurer git pour les outils qui en ont besoin (ex: msfupdate)
    git config user.name "nihil" || true
    git config user.email "nihil@localhost" || true

    # Installer bundler si pas déjà installé
    if ! gem list -i bundler >/dev/null 2>&1; then
        colorecho "  → Installing bundler"
        gem install bundler --no-document || {
            colorecho "  ✗ Warning: Failed to install bundler"
            return 1
        }
    fi

    # Installer les dépendances Ruby avec bundler
    colorecho "  → Installing Ruby dependencies"
    if [ -n "$bundle_args" ]; then
        bundle install $bundle_args || {
            colorecho "  ✗ Warning: Bundle install failed, trying without args"
            bundle install || {
                colorecho "  ✗ Warning: Failed to install Ruby dependencies"
                return 1
            }
        }
    else
        bundle install || {
            colorecho "  ✗ Warning: Failed to install Ruby dependencies"
            return 1
        }
    fi

    # Installer les gems supplémentaires si fournies
    if [ -n "$extra_gems" ]; then
        colorecho "  → Installing additional gems"
        for gem_spec in $extra_gems; do
            # Support pour "gem:version" (ex: "timeout:0.4.1")
            if echo "$gem_spec" | grep -q ":"; then
                local gem_name=$(echo "$gem_spec" | cut -d: -f1)
                local gem_version=$(echo "$gem_spec" | cut -d: -f2)
                gem install "$gem_name" --version "$gem_version" --no-document || true
            else
                gem install "$gem_spec" --no-document || true
            fi
        done
    fi

    # Configurer les permissions
    chmod -R o+rx "$repo_dir" || true
    chmod 444 "$repo_dir/.git/index" 2>/dev/null || true

    # Créer les wrappers pour chaque entrypoint
    mkdir -p "$GIT_BIN_DIR"
    for entrypoint in $entrypoints; do
        local cmd_name="$entrypoint"
        local wrapper="${GIT_BIN_DIR}/${cmd_name}"
        
        # Créer le wrapper qui exécute bundle exec ruby depuis le repo
        cat > "$wrapper" <<EOF
#!/bin/sh
cd "$repo_dir" || exit 1
exec bundle exec ruby $entrypoint "\$@"
EOF
        chmod +x "$wrapper"
        colorecho "  ✓ Created wrapper: $cmd_name"
    done

    # Ajouter aliases et history si disponibles (utiliser alias_name si fourni)
    add-aliases "$alias_name"
    add-history "$alias_name"

    colorecho "  ✓ $tool_name installed"
    return 0
}
