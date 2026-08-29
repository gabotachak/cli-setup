#!/usr/bin/env bash
# setup-keys.sh — SSH key + SSH commit signing for GitHub (macOS)
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
box "║      SSH key + signing for GitHub       ║"
box "╚══════════════════════════════════════════╝"
echo ""

# ── Config ─────────────────────────────────────────────────────
step "Config"
read -rp "  Name (for git):  " GIT_NAME
read -rp "  Email (for git): " GIT_EMAIL

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
# Commit signing — SSH (same key as above, no GPG)
# ════════════════════════════════════════════════════════════════
step "Commit signing (SSH)"

git config --global user.name       "$GIT_NAME"
git config --global user.email      "$GIT_EMAIL"
git config --global gpg.format      ssh
git config --global user.signingkey "$SSH_KEY.pub"
git config --global commit.gpgsign  true
git config --global tag.gpgsign     true

# allowed_signers: lets `git log --show-signature` verify locally
SIGNERS="$HOME/.config/git/allowed_signers"
mkdir -p "$(dirname "$SIGNERS")"
SIGNER_LINE="$GIT_EMAIL $(cat "$SSH_KEY.pub")"
grep -qxF "$SIGNER_LINE" "$SIGNERS" 2>/dev/null || echo "$SIGNER_LINE" >> "$SIGNERS"
git config --global gpg.ssh.allowedSignersFile "$SIGNERS"
success "Git configured: SSH-signed commits + tags (key: $SSH_KEY.pub)"

echo ""
warn "GitHub needs this SAME key added a SECOND time, as a Signing key."
info "Opening GitHub SSH settings..."
open "https://github.com/settings/ssh/new"

echo ""
warn "Paste the key above again → Key type: Signing key → Add SSH key."
pause

# ════════════════════════════════════════════════════════════════
# Done
# ════════════════════════════════════════════════════════════════
echo ""
box "╔══════════════════════════════════════════╗"
box "║            Setup complete! ✓            ║"
box "╚══════════════════════════════════════════╝"
echo ""
echo "  SSH key:     $SSH_KEY.pub  (add to GitHub twice: Authentication + Signing)"
echo "  Git signing: SSH, enabled (commits + tags)"
echo ""
echo "  Verify a signed commit:"
echo "    git log --show-signature -1"
echo ""
