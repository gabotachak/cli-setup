# Enable Powerlevel10k instant prompt (must stay at top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================================================================
# ZSH CONFIGURATION
# =============================================================================

# -----------------------------------------------------------------------------
# 1. PATH AND ENVIRONMENT VARIABLES
# -----------------------------------------------------------------------------

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export GPG_TTY=$(tty)
export DOCKER_BUILDKIT=1
export PATH="$HOME/.codeium/windsurf/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# -----------------------------------------------------------------------------
# 2. COMPLETION SYSTEM (zstyle must come before compinit, which OMZ calls)
# -----------------------------------------------------------------------------

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
# 3. AUTOSUGGESTIONS (must be set before OMZ loads the plugin)
# -----------------------------------------------------------------------------

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999999'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# -----------------------------------------------------------------------------
# 4. OH MY ZSH
# -----------------------------------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
)

source "$ZSH/oh-my-zsh.sh"

# -----------------------------------------------------------------------------
# 5. HISTORY
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
# 6. ALIASES AND FUNCTIONS
# -----------------------------------------------------------------------------

alias gp='git push'
alias gpl='git pull'
alias gnew='git checkout -b'
alias gc='git checkout'

gac() {
  [[ -z "$1" ]] && { echo "Usage: gac 'commit message'"; return 1 }
  git add . && git commit -m "$1"
}

# -----------------------------------------------------------------------------
# 7. PROMPT
# -----------------------------------------------------------------------------

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
