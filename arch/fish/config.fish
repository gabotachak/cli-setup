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
mise activate fish | source

# Environment
set -gx GPG_TTY (tty)
set -gx DOCKER_BUILDKIT 1
set -gx GITROOT $HOME/development

# SSH agent (autostart + load key)
if not set -q SSH_AUTH_SOCK
    eval (ssh-agent -c) > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
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
