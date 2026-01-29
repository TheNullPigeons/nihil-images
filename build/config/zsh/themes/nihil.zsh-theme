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

PROMPT='%F{red}[%D{%H:%M:%S}]%f 🕊️ %B%F{green}%n@%m%f%b %F{blue}%~%f$(git_prompt_info) > '
RPROMPT=''
