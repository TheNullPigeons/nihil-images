# Nihil Oh My Zsh Theme
# Auteur: TheNullPigeons
# Description: Thème custom avec timestamps et indicateurs git

# Config git
ZSH_THEME_GIT_PROMPT_PREFIX=" %F{yellow}git:("
ZSH_THEME_GIT_PROMPT_SUFFIX=")%f"
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# Prompt direct
# %D{...} : Heure
# %n@%m : User@Host
# %~ : Path
# $(git_prompt_info) : Info git (évalué dynamiquement)

_nihil_cred_info() {
  local u="$USER" d="$DOMAIN"
  if [[ -n "$u" && -n "$d" ]]; then
    echo "[%F{#88ddff}${u}@${d}%f] "
  elif [[ -n "$u" ]]; then
    echo "[%F{#88ddff}${u}%f] "
  elif [[ -n "$d" ]]; then
    echo "[%F{#88ddff}@${d}%f] "
  fi
}

PROMPT='$(_nihil_cred_info)%F{red}[%D{%d/%m/%Y %H:%M:%S %Z}]%f 🕊️ %B%F{green}%n@%m%f%b %F{blue}%~%f$(git_prompt_info) > '
RPROMPT=''
