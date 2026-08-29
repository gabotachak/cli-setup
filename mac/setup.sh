#!/usr/bin/env bash
# setup.sh — Bootstrap a fresh Mac
# Usage: bash setup.sh              → interactive menu
#        bash setup.sh all          → run all steps
#        bash setup.sh <1-7>        → run single step
#        CLI_ONLY=1 bash setup.sh … → skip Caskfile (GUI apps), CLI only
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
FISH_PATH="/opt/homebrew/bin/fish"

info()    { echo "  [→] $*"; }
success() { echo "  [✓] $*"; }
warn()    { echo "  [!] $*"; }

banner() {
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║         $USER — mac setup                ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
}

done_footer() {
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║              Setup complete!             ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
  echo "  Next steps:"
  echo "  1. Open a new terminal"
  echo "  2. Run: tide configure  (set up your prompt)"
  echo "  3. Run: mise use --global python@<version>"
  echo "  4. Create ~/.config/fish/conf.d/secrets.fish (AWS creds, API keys)"
  echo ""
}

# ── Step functions ────────────────────────────────────────────

step_xcode() {
  info "Checking Xcode Command Line Tools..."
  if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    read -rp "  Press Enter once Xcode CLT installation completes..."
  fi
  success "Xcode CLT ready"
}

step_homebrew() {
  info "Checking Homebrew..."
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  success "Homebrew $(brew --version | head -1)"
}

step_bundle() {
  info "Installing CLI packages from Brewfile..."
  brew bundle --file="$SCRIPT_DIR/Brewfile"
  if [[ "${CLI_ONLY:-}" == "1" ]]; then
    warn "CLI_ONLY=1 — skipping Caskfile (GUI apps)"
  else
    info "Installing GUI apps from Caskfile..."
    brew bundle --file="$SCRIPT_DIR/Caskfile"
  fi
  success "Packages installed"
}

step_fish() {
  info "Configuring Fish shell..."
  if ! grep -qF "$FISH_PATH" /etc/shells 2>/dev/null; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
    success "Fish added to /etc/shells"
  else
    success "Fish already in /etc/shells"
  fi
}

step_fisher() {
  info "Installing Fisher plugin manager..."
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null
  success "Fisher installed"

  info "Installing Tide prompt (Powerlevel10k equivalent)..."
  fish -c "fisher install IlanCosman/tide@v6" 2>/dev/null
  success "Tide installed"
}

step_symlink() {
  info "Symlinking Fish config..."
  mkdir -p "$HOME/.config/fish/"{conf.d,functions}
  ln -sf "$REPO_ROOT/fish/config.fish" "$HOME/.config/fish/config.fish"
  for f in "$REPO_ROOT/fish/functions/"*.fish; do
    ln -sf "$f" "$HOME/.config/fish/functions/$(basename "$f")"
  done
  success "Fish config symlinked"

  info "Symlinking zsh config (fallback shell)..."
  ln -sf "$REPO_ROOT/zsh/.zshrc"    "$HOME/.zshrc"
  ln -sf "$REPO_ROOT/zsh/.zprofile" "$HOME/.zprofile"
  success "zsh config symlinked"
}

step_default() {
  if ! grep -qF "$FISH_PATH" /etc/shells 2>/dev/null; then
    warn "Fish not in /etc/shells — run step 4 first"
    return 1
  fi
  if [ "$SHELL" != "$FISH_PATH" ]; then
    info "Setting Fish as default shell..."
    chsh -s "$FISH_PATH"
    success "Fish set as default shell"
  else
    success "Fish already default shell"
  fi
}

run_all() {
  step_xcode
  step_homebrew
  step_bundle
  step_fish
  step_fisher
  step_symlink
  step_default
}

run_step() {
  case "$1" in
    1) step_xcode   ;;
    2) step_homebrew ;;
    3) step_bundle   ;;
    4) step_fish     ;;
    5) step_fisher   ;;
    6) step_symlink  ;;
    7) step_default  ;;
    *) warn "Invalid step: $1 (valid: 1-7)"; return 1 ;;
  esac
}

show_menu() {
  echo "  1) Xcode Command Line Tools"
  echo "  2) Homebrew"
  echo "  3) Brew bundle (Brewfile + Caskfile)"
  echo "  4) Fish shell (/etc/shells)"
  echo "  5) Fisher + Tide"
  echo "  6) Symlink Fish config"
  echo "  7) Set Fish as default shell"
  echo "  a) Run all steps"
  echo "  q) Quit"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────

banner

case "${1:-}" in
  all)
    run_all
    done_footer
    ;;
  [1-7])
    run_step "$1"
    ;;
  "")
    while true; do
      show_menu
      read -rp "  Select: " choice
      echo ""
      case "$choice" in
        [1-7]) run_step "$choice" ;;
        a)     run_all ;;
        q)     break ;;
        *)     warn "Invalid choice: $choice" ;;
      esac
      echo ""
    done
    done_footer
    ;;
  *)
    warn "Unknown argument: $1"
    echo "  Usage: bash setup.sh [all|1-7]"
    exit 1
    ;;
esac
