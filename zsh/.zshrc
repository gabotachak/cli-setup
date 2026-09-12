# =============================================================================
# ZSH CONFIGURATION
# =============================================================================

# -----------------------------------------------------------------------------
# 1. PATH AND ENVIRONMENT VARIABLES
# -----------------------------------------------------------------------------

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

export GPG_TTY=$(tty)
export DOCKER_BUILDKIT=1
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# -----------------------------------------------------------------------------
# 2. COMPLETION SYSTEM
# -----------------------------------------------------------------------------

autoload -Uz compinit && compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}No matches found%f'
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path "$HOME/.zsh/cache"

# Completion behavior
setopt AUTO_LIST AUTO_MENU MENU_COMPLETE FLOW_CONTROL
unsetopt CASE_GLOB

# -----------------------------------------------------------------------------
# 3. HISTORY
# -----------------------------------------------------------------------------

# SHARE_HISTORY supersedes INC_APPEND_HISTORY and APPEND_HISTORY
# HIST_IGNORE_ALL_DUPS supersedes HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS HIST_VERIFY

HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"

# -----------------------------------------------------------------------------
# 4. ALIASES AND FUNCTIONS
# -----------------------------------------------------------------------------

alias gp='git push'
alias gpl='git pull'
alias gnew='git checkout -b'
alias gc='git checkout'

gac() {
  [[ -z "$1" ]] && { echo "Usage: gac 'commit message'"; return 1 }
  git add . && git commit -m "$1"
}
