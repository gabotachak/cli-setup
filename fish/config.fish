# ============================================================
# Fish Shell Configuration
# ============================================================

# Homebrew
eval (/opt/homebrew/bin/brew shellenv)

# PATH
fish_add_path $HOME/bin $HOME/.local/bin /usr/local/bin /usr/local/sbin
fish_add_path $HOME/.opencode/bin

# Mise
mise activate fish | source

# Tooling paths
fish_add_path $HOME/.antigravity/antigravity/bin

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
    alias claude-work 'CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
    alias claude-korvy 'CLAUDE_CONFIG_DIR=$HOME/.claude-korvy claude'
    alias wakepc 'wakeonlan 9c:6b:00:18:59:f4'
end

set -gx JAVA_HOME "/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
set -gx PATH $JAVA_HOME/bin $PATH
