#!/usr/bin/env bash
# setup-keys.sh — SSH commit signing for GitHub (Arch Linux)
# Assumes SSH auth is already set up via `gh auth login` (git protocol: ssh) —
# that generates ~/.ssh/id_ed25519 and registers it with GitHub as an
# Authentication key. This script reuses that same key to sign commits/tags
# and registers it with GitHub as a Signing key via `gh` (no GPG, no manual paste).
# Usage: bash setup-keys.sh
set -euo pipefail

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

open_url() {
  if command -v xdg-open &>/dev/null; then
    xdg-open "$1" &>/dev/null &
  else
    warn "xdg-open not found — open this URL manually:"
    echo "  $1"
  fi
}

echo ""
box "╔══════════════════════════════════════════╗"
box "║       SSH commit signing for GitHub     ║"
box "╚══════════════════════════════════════════╝"
echo ""

# ── Config ─────────────────────────────────────────────────────
step "Config"
read -rp "  Name (for git):  " GIT_NAME
read -rp "  Email (for git): " GIT_EMAIL

# ════════════════════════════════════════════════════════════════
# SSH key — expected to already exist via `gh auth login`
# ════════════════════════════════════════════════════════════════
step "SSH key"

SSH_KEY="$HOME/.ssh/id_ed25519"

if [[ ! -f "$SSH_KEY.pub" ]]; then
  warn "No SSH key at $SSH_KEY.pub"
  echo "  Run 'gh auth login' first (git protocol: ssh) — it generates the key"
  echo "  and registers it with GitHub as an Authentication key."
  exit 1
fi
success "Using existing key: $SSH_KEY.pub"

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

# ════════════════════════════════════════════════════════════════
# Register the same key with GitHub as a Signing key (via gh)
# ════════════════════════════════════════════════════════════════
step "Register signing key with GitHub"

if ! command -v gh &>/dev/null; then
  warn "gh not found — add this key manually as a Signing key:"
  open_url "https://github.com/settings/ssh/new"
  cat "$SSH_KEY.pub"
else
  LOCAL_KEY="$(awk '{print $1, $2}' "$SSH_KEY.pub")"
  if ! gh auth status 2>&1 | grep -q "admin:ssh_signing_key"; then
    info "Requesting the admin:ssh_signing_key scope from GitHub..."
    gh auth refresh -h github.com -s admin:ssh_signing_key
  fi
  if gh ssh-key list 2>/dev/null | awk -F'\t' -v k="$LOCAL_KEY" '$2==k && $5=="signing"{f=1} END{exit !f}'; then
    success "Signing key already registered with GitHub"
  else
    info "Adding key to GitHub as a Signing key..."
    gh ssh-key add "$SSH_KEY.pub" --type signing --title "$(hostname) (signing)"
    success "Signing key registered with GitHub"
  fi
fi

# ════════════════════════════════════════════════════════════════
# Done
# ════════════════════════════════════════════════════════════════
echo ""
box "╔══════════════════════════════════════════╗"
box "║            Setup complete! ✓            ║"
box "╚══════════════════════════════════════════╝"
echo ""
echo "  Git signing: SSH, enabled (commits + tags), key: $SSH_KEY.pub"
echo ""
echo "  Verify a signed commit:"
echo "    git log --show-signature -1"
echo ""
