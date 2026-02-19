#!/bin/bash
# Registry pour installation d'outils via curl/wget
# - install_download_tool : script ou binaire unique
# - install_tar_tool : archive tar.gz/tar.xz avec support multi-architecture

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Usage: install_download_tool "cmd_name" "url"
# Exemple: install_download_tool "testssl" "https://raw.githubusercontent.com/drwetter/testssl.sh/3.2/testssl.sh"
# Pour un binaire: URL doit pointer vers le fichier exécutable (raw)
install_download_tool() {
    local cmd_name="$1"
    local url="$2"
    local dest="${INSTALL_DIR}/${cmd_name}"

    if command -v "$cmd_name" >/dev/null 2>&1; then
        colorecho "  ✓ $cmd_name already installed (download)"
        return 0
    fi

    colorecho "  → Installing $cmd_name via curl/wget ($url)"
    mkdir -p "$INSTALL_DIR"
    if curl -sSLf "$url" -o "$dest" 2>/dev/null || wget -q -O "$dest" "$url" 2>/dev/null; then
        chmod +x "$dest"
        colorecho "  ✓ $cmd_name installed"
        return 0
    fi
    colorecho "  ✗ Warning: Failed to download $cmd_name"
    rm -f "$dest"
    return 1
}

# Usage: install_tar_tool "tool_name" "url_template" "install_dir" "binary_path" ["symlinks"] ["arch_map"]
#
#   tool_name     : nom de l'outil (pour vérification et messages)
#   url_template  : template d'URL avec {arch} et {version} (ex: "https://.../{arch}/tool-{version}.tar.gz")
#   install_dir   : répertoire d'extraction (ex: "/usr/local/share/tool/{version}")
#   binary_path    : chemin relatif au binaire dans l'archive (ex: "pwsh" ou "bin/tool")
#   symlinks      : (optionnel) liste de symlinks à créer, séparés par des espaces (ex: "pwsh powershell")
#                    Si vide, utilise le nom du binaire
#   arch_map      : (optionnel) mapping architecture personnalisé au format "arch1:url_arch1 arch2:url_arch2"
#                    Si vide, utilise le mapping par défaut (x86_64, aarch64, armv7l)
#   version       : (optionnel) version à installer, passé comme 6ème argument ou dans url_template
#
# Exemples:
#   install_tar_tool "powershell" \
#     "https://github.com/PowerShell/PowerShell/releases/download/v{version}/powershell-{version}-linux-{arch}.tar.gz" \
#     "/usr/local/share/powershell/{version}" "pwsh" "pwsh powershell" "" "7.3.4"
#
#   install_tar_tool "mytool" \
#     "https://example.com/{arch}/tool.tar.gz" \
#     "/usr/local/share/mytool" "bin/mytool" "mytool mt"
install_tar_tool() {
    local tool_name="$1"
    local url_template="$2"
    local install_dir_template="$3"
    local binary_path="$4"
    local symlinks="${5:-}"
    local arch_map="${6:-}"
    local version="${7:-}"

    # Vérifier si déjà installé (vérifier le premier symlink ou le binaire)
    local check_cmd="${symlinks%% *}"
    [ -z "$check_cmd" ] && check_cmd="$(basename "$binary_path")"
    if command -v "$check_cmd" >/dev/null 2>&1; then
        colorecho "  ✓ $tool_name already installed (tar)"
        return 0
    fi

    # Détecter l'architecture
    local arch=$(uname -m)
    local url_arch=""
    
    # Mapping d'architecture par défaut
    if [ -z "$arch_map" ]; then
        case "$arch" in
            x86_64)
                url_arch="x64"
                ;;
            aarch64)
                url_arch="arm64"
                ;;
            armv7l)
                url_arch="arm32"
                ;;
            *)
                colorecho "  ✗ Error: Unsupported architecture: ${arch}"
                return 1
                ;;
        esac
    else
        # Utiliser le mapping personnalisé
        url_arch=$(echo "$arch_map" | grep -o "${arch}:[^ ]*" | cut -d: -f2)
        if [ -z "$url_arch" ]; then
            colorecho "  ✗ Error: Architecture ${arch} not found in arch_map"
            return 1
        fi
    fi

    # Remplacer les variables dans les templates
    local install_dir=$(echo "$install_dir_template" | sed "s/{version}/${version}/g" | sed "s/{arch}/${arch}/g")
    local url=$(echo "$url_template" | sed "s/{arch}/${url_arch}/g" | sed "s/{version}/${version}/g")

    colorecho "  → Installing $tool_name via tar ($url)"

    # Télécharger l'archive
    local tmp_file="/tmp/${tool_name}-${version}-${arch}.tar.gz"
    if ! curl -sSLf -L "$url" -o "$tmp_file" 2>/dev/null && ! wget -q -O "$tmp_file" "$url" 2>/dev/null; then
        colorecho "  ✗ Warning: Failed to download $tool_name"
        rm -f "$tmp_file"
        return 1
    fi

    # Créer le répertoire d'installation
    mkdir -p "$install_dir"

    # Détecter le type d'archive et extraire
    local extract_cmd=""
    if echo "$tmp_file" | grep -q "\.tar\.gz$"; then
        extract_cmd="tar xzf"
    elif echo "$tmp_file" | grep -q "\.tar\.xz$"; then
        extract_cmd="tar xJf"
    elif echo "$tmp_file" | grep -q "\.tar\.bz2$"; then
        extract_cmd="tar xjf"
    else
        colorecho "  ✗ Warning: Unsupported archive format"
        rm -f "$tmp_file"
        return 1
    fi

    if ! $extract_cmd "$tmp_file" -C "$install_dir" 2>/dev/null; then
        colorecho "  ✗ Warning: Failed to extract $tool_name archive"
        rm -f "$tmp_file"
        return 1
    fi

    # Trouver le binaire (peut être à la racine ou dans un sous-dossier après extraction)
    local binary_full_path=""
    if [ -f "${install_dir}/${binary_path}" ]; then
        binary_full_path="${install_dir}/${binary_path}"
    else
        # Chercher récursivement
        binary_full_path=$(find "$install_dir" -name "$(basename "$binary_path")" -type f -executable | head -n1)
        if [ -z "$binary_full_path" ]; then
            colorecho "  ✗ Warning: Binary $binary_path not found in archive"
            rm -f "$tmp_file"
            return 1
        fi
    fi

    # Rendre exécutable
    chmod +x "$binary_full_path" || true

    # Créer les symlinks
    mkdir -p "$INSTALL_DIR"
    if [ -n "$symlinks" ]; then
        for link in $symlinks; do
            ln -sf "$binary_full_path" "${INSTALL_DIR}/${link}" || true
        done
    else
        # Par défaut, créer un symlink avec le nom du binaire
        local default_link=$(basename "$binary_path")
        ln -sf "$binary_full_path" "${INSTALL_DIR}/${default_link}" || true
    fi

    # Nettoyer
    rm -f "$tmp_file"

    # Ajouter aliases et history si disponibles
    add-aliases "$tool_name"
    add-history "$tool_name"

    colorecho "  ✓ $tool_name installed"
    return 0
}
