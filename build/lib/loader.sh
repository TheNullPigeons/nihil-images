#!/bin/bash
#
# loader.sh — Chargeur principal du système de build Nihil
#
# Usage :
#   source lib/loader.sh
#
# Une fois chargé, on peut importer des modules à la demande :
#   nihil::import lib/registry/pipx
#   nihil::import modules/mod_ad
#
# Les imports redondants sont silencieusement ignorés (idempotent).
# ─────────────────────────────────────────────────────────────────────────────

# Protection contre le double-chargement
[[ -n "${_NIHIL_LOADER_LOADED:-}" ]] && return 0
readonly _NIHIL_LOADER_LOADED=1

# Résolution du chemin racine du système de build (= répertoire build/)
# Fonctionne quel que soit le répertoire depuis lequel on source ce fichier.
if [[ -z "${NIHIL_BUILD:-}" ]]; then
    NIHIL_BUILD="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    readonly NIHIL_BUILD
fi

# ── Registre des modules chargés ─────────────────────────────────────────────
#
# Clé   : chemin relatif du module depuis NIHIL_BUILD (sans .sh)
# Valeur: 1 si chargé
declare -gA _NIHIL_MODULES=()

# ── Fonction d'import ────────────────────────────────────────────────────────
#
# nihil::import <module> [module...]
#
# Charge un ou plusieurs modules par leur chemin relatif depuis NIHIL_BUILD.
# Les imports redondants sont silencieusement ignorés (idempotent).
#
# Exemples :
#   nihil::import lib/common
#   nihil::import lib/registry/pipx modules/mod_ad
#
nihil::import() {
    local module
    for module in "$@"; do
        # Déjà chargé ? On passe.
        [[ -n "${_NIHIL_MODULES[${module}]:-}" ]] && continue

        local path="${NIHIL_BUILD}/${module}.sh"
        if [[ ! -f "${path}" ]]; then
            printf '[nihil] ERREUR : module introuvable : %s\n' "${module}" >&2
            return 1
        fi

        # Marquer avant le source pour éviter les cycles
        _NIHIL_MODULES["${module}"]=1
        # shellcheck source=/dev/null
        source "${path}"
    done
}

# ── Chargement du socle (toujours effectué) ───────────────────────────────────
nihil::import lib/common
