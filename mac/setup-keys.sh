#!/usr/bin/env bash
# setup-keys.sh — SSH + GPG key setup for GitHub (macOS)
# Usage: bash setup-keys.sh
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}  [→]${NC} $*"; }
success() { echo -e "${GREEN}  [✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}  [!]${NC} $*"; }
step()    { echo -e "\n${CYAN}${BOLD}══ $* ══${NC}"; }
box()     { echo -e "${BOLD}$*${NC}"; }
pause()   { read -rp "  Press Enter to continue..."; }

echo ""
box "╔══════════════════════════════════════════╗"
box "║       SSH + GPG setup for GitHub        ║"
box "╚══════════════════════════════════════════╝"
echo ""

# ── Config ─────────────────────────────────────────────────────
step "Config"
read -rp "  Name (for GPG):   " GIT_NAME
read -rp "  Email (SSH + GPG): " GIT_EMAIL

# ════════════════════════════════════════════════════════════════
# SSH
# ════════════════════════════════════════════════════════════════
step "SSH Key"

SSH_KEY="$HOME/.ssh/id_ed25519"
mkdir -p ~/.ssh && chmod 700 ~/.ssh

if [[ -f "$SSH_KEY" ]]; then
  warn "Key already exists: $SSH_KEY — skipping generation"
else
  info "Generating Ed25519 SSH key..."
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
  success "Key generated"
fi

# macOS Keychain config
if [[ ! -f ~/.ssh/config ]] || ! grep -q "github.com" ~/.ssh/config; then
  cat >> ~/.ssh/config <<'EOF'

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
  chmod 600 ~/.ssh/config
  success "~/.ssh/config updated"
fi

# Load into agent
eval "$(ssh-agent -s)" > /dev/null
ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY"

echo ""
echo -e "  ${BOLD}┌─── Paste this into GitHub → Settings → SSH keys ───────────┐${NC}"
echo ""
cat "$SSH_KEY.pub"
echo ""
echo -e "  ${BOLD}└─────────────────────────────────────────────────────────────┘${NC}"
echo ""

info "Opening GitHub SSH settings..."
open "https://github.com/settings/ssh/new"

echo ""
warn "Paste the key above → Add SSH key — then come back."
pause

info "Testing GitHub connection..."
if ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  success "GitHub SSH connection works!"
else
  warn "Could not confirm — you can test manually: ssh -T git@github.com"
fi

# ════════════════════════════════════════════════════════════════
# GPG
# ════════════════════════════════════════════════════════════════
step "GPG Key"

# Configure pinentry-mac (macOS GUI passphrase dialog)
mkdir -p ~/.gnupg && chmod 700 ~/.gnupg
cat > ~/.gnupg/gpg-agent.conf <<EOF
pinentry-program /opt/homebrew/bin/pinentry-mac
default-cache-ttl 3600
max-cache-ttl 86400
EOF
chmod 600 ~/.gnupg/gpg-agent.conf

# Restart agent so pinentry-mac takes effect
gpgconf --kill gpg-agent 2>/dev/null || true
sleep 1

# Check for existing key
EXISTING_KEY=$(gpg --list-secret-keys --keyid-format=long "$GIT_EMAIL" 2>/dev/null \
  | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1 || true)

if [[ -n "$EXISTING_KEY" ]]; then
  warn "GPG key already exists: $EXISTING_KEY — skipping generation"
  GPG_KEY_ID="$EXISTING_KEY"
else
  info "Generating GPG key (Ed25519) — a passphrase dialog will appear..."
  gpg --quick-generate-key "$GIT_NAME <$GIT_EMAIL>" ed25519 sign 0

  GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$GIT_EMAIL" 2>/dev/null \
    | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1)
  success "GPG key generated: $GPG_KEY_ID"
fi

# Configure git globally
git config --global user.name       "$GIT_NAME"
git config --global user.email      "$GIT_EMAIL"
git config --global user.signingkey "$GPG_KEY_ID"
git config --global commit.gpgsign  true
git config --global tag.gpgsign     true
success "Git configured: all commits + tags auto-signed"

echo ""
echo -e "  ${BOLD}┌─── Paste this into GitHub → Settings → GPG keys ───────────┐${NC}"
echo ""
gpg --armor --export "$GPG_KEY_ID"
echo ""
echo -e "  ${BOLD}└─────────────────────────────────────────────────────────────┘${NC}"
echo ""

info "Opening GitHub GPG settings..."
open "https://github.com/settings/gpg/new"

echo ""
warn "Paste the full key block (including BEGIN/END lines) → Add GPG key."
pause

# ════════════════════════════════════════════════════════════════
# Done
# ════════════════════════════════════════════════════════════════
echo ""
box "╔══════════════════════════════════════════╗"
box "║            Setup complete! ✓            ║"
box "╚══════════════════════════════════════════╝"
echo ""
echo "  SSH key:    $SSH_KEY.pub"
echo "  GPG key ID: $GPG_KEY_ID"
echo "  Git signing: enabled (commits + tags)"
echo ""
echo "  Verify a signed commit:"
echo "    git log --show-signature -1"
echo ""
