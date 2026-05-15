# ============================================================
# Fish Shell Configuration
# ============================================================

# Homebrew
eval (/opt/homebrew/bin/brew shellenv)

# PATH
fish_add_path $HOME/bin $HOME/.local/bin /usr/local/bin
fish_add_path $HOME/Library/Python/3.9/bin /usr/local/sbin
fish_add_path $HOME/.opencode/bin

# Mise
mise activate fish | source

# jenv
set -x PATH $HOME/.jenv/bin $PATH
jenv init - fish | source

# Tooling paths
fish_add_path $HOME/.codeium/windsurf/bin
fish_add_path $HOME/.antigravity/antigravity/bin
fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Environment
set -gx GPG_TTY (tty)
set -gx DOCKER_BUILDKIT 1
set -gx GITROOT $HOME/development

# Interactive-only config
if status is-interactive
    alias gp 'git push'
    alias gpl 'git pull'
    alias gnew 'git checkout -b'
    alias gc 'git checkout'
    alias docker-compose 'docker compose'
    alias amend 'git add . && git commit --amend --no-edit && git push --force-with-lease && echo "✅ Amended and pushed!"'
end
