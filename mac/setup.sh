#!/usr/bin/env bash
# setup.sh — Bootstrap a fresh Mac
# Usage: bash setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FISH_PATH="/opt/homebrew/bin/fish"

info()    { echo "  [→] $*"; }
success() { echo "  [✓] $*"; }
warn()    { echo "  [!] $*"; }

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║         gabotachak — mac setup           ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Xcode Command Line Tools ───────────────────────────────
info "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  read -rp "  Press Enter once Xcode CLT installation completes..."
fi
success "Xcode CLT ready"

# ── 2. Homebrew ───────────────────────────────────────────────
info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
success "Homebrew $(brew --version | head -1)"

# ── 3. Brew bundle ────────────────────────────────────────────
info "Installing packages from Brewfile..."
brew bundle --file="$SCRIPT_DIR/Brewfile"
success "All packages installed"

# ── 4. Fish shell setup ───────────────────────────────────────
info "Configuring Fish shell..."

if ! grep -qF "$FISH_PATH" /etc/shells 2>/dev/null; then
  echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
  success "Fish added to /etc/shells"
fi

# ── 5. Fisher + tide ─────────────────────────────────────────
info "Installing Fisher plugin manager..."
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null
success "Fisher installed"

info "Installing Tide prompt (Powerlevel10k equivalent)..."
fish -c "fisher install IlanCosman/tide@v6" 2>/dev/null
success "Tide installed"

# ── 6. Copy config files ──────────────────────────────────────
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

info "Symlinking Zsh config..."
ln -sf "$REPO_ROOT/zsh/.zshrc"   "$HOME/.zshrc"
ln -sf "$REPO_ROOT/zsh/.zprofile" "$HOME/.zprofile"
success "Zsh config symlinked"

info "Symlinking Fish config..."
mkdir -p "$HOME/.config/fish/functions"
ln -sf "$REPO_ROOT/fish/config.fish"              "$HOME/.config/fish/config.fish"
ln -sf "$REPO_ROOT/fish/functions/gac.fish"       "$HOME/.config/fish/functions/gac.fish"
success "Fish config symlinked"

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║              Setup complete!             ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Next steps:"
echo "  1. chsh -s $FISH_PATH   (set Fish as default shell)"
echo "  2. Open a new terminal"
echo "  3. Run: tide configure  (set up your prompt)"
echo "  4. Run: pyenv install <version> && pyenv global <version>"
echo ""
