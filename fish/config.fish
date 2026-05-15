# ============================================================
# Fish Shell Configuration
# ============================================================

# Homebrew
eval (/opt/homebrew/bin/brew shellenv)

# PATH
fish_add_path $HOME/bin $HOME/.local/bin /usr/local/bin

# Pyenv
set -x PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin
pyenv init - fish | source

# Tooling paths
fish_add_path $HOME/.codeium/windsurf/bin
fish_add_path $HOME/.antigravity/antigravity/bin
fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Environment
set -x GPG_TTY (tty)
set -x DOCKER_BUILDKIT 1

# Interactive-only config
if status is-interactive
    alias gp 'git push'
    alias gpl 'git pull'
    alias gnew 'git checkout -b'
    alias gc 'git checkout'
end
