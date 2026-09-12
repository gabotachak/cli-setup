# ============================================================
# Fish Shell Configuration (Arch / CachyOS)
# ============================================================

# CachyOS default fish config (theming, fastfetch greeting, etc.)
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# PATH
fish_add_path $HOME/.local/bin $HOME/bin

# Mise
if command -sq mise
    mise activate fish | source
end

# Environment
set -gx GPG_TTY (tty)
set -gx DOCKER_BUILDKIT 1
set -gx GITROOT $HOME/development

# SSH agent: one agent on a fixed socket, shared across shells (no per-shell spawn).
# Keys load on first use via `AddKeysToAgent yes` in ~/.ssh/config.
if not set -q SSH_AUTH_SOCK
    set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
    test -S $SSH_AUTH_SOCK; or ssh-agent -a $SSH_AUTH_SOCK >/dev/null 2>&1
end

# Interactive-only config
if status is-interactive
    alias gp 'git push'
    alias gpl 'git pull'
    alias gnew 'git checkout -b'
    alias gc 'git checkout'
    alias docker-compose 'docker compose'
    alias amend 'git add . && git commit --amend --no-edit && git push --force-with-lease && echo "✅ Amended and pushed!"'
end
