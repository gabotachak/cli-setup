#!/usr/bin/env bash
# setup.sh — Bootstrap a fresh Arch/CachyOS box
# Usage: bash setup.sh        → interactive menu
#        bash setup.sh all    → run all steps
#        bash setup.sh <1-7>  → run single step
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
FISH_PATH="$(command -v fish || echo /usr/bin/fish)"

info()    { echo "  [→] $*"; }
success() { echo "  [✓] $*"; }
warn()    { echo "  [!] $*"; }

banner() {
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║         $USER — arch setup               ║"
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
  echo "  1. Log out/in (or reboot) if you were just added to the docker group"
  echo "  2. Open a new terminal"
  echo "  3. Run: mise use --global python@<version>"
  echo "  4. Create ~/.config/fish/conf.d/secrets.fish (AWS creds, API keys)"
  echo ""
}

# Install every non-comment/non-blank line of a package list, one at a time,
# so one wrong/renamed AUR package doesn't abort the rest.
install_list() {
  local installer=$1 list=$2
  local failed=()
  while IFS= read -r pkg; do
    pkg="$(echo "$pkg" | sed 's/#.*//' | xargs)"
    [[ -z "$pkg" ]] && continue
    if $installer --needed --noconfirm -S "$pkg"; then
      success "$pkg"
    else
      warn "Failed: $pkg"
      failed+=("$pkg")
    fi
  done < "$list"
  if [[ ${#failed[@]} -gt 0 ]]; then
    warn "Skipped/failed packages: ${failed[*]}"
  fi
}

# ── Step functions ────────────────────────────────────────────

step_base() {
  info "Installing base-devel + git (needed to build AUR packages)..."
  sudo pacman -S --needed --noconfirm base-devel git
  success "base-devel ready"
}

step_paru() {
  info "Checking paru (AUR helper)..."
  if command -v paru &>/dev/null; then
    success "paru already installed"
    return
  fi
  info "Building paru from AUR..."
  local tmp
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"
  (cd "$tmp/paru" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  success "paru installed"
}

step_pacman_bundle() {
  info "Installing packages from pacman.txt..."
  sudo pacman -Sy --needed --noconfirm - < <(grep -vE '^\s*#|^\s*$' "$SCRIPT_DIR/pacman.txt")
  success "Official packages installed"
}

step_aur_bundle() {
  if ! command -v paru &>/dev/null; then
    warn "paru not installed — run step 2 first"
    return 1
  fi
  info "Installing packages from aur.txt (this can take a while, builds from source)..."
  install_list paru "$SCRIPT_DIR/aur.txt"
  success "AUR packages installed"
}

step_symlink() {
  info "Symlinking Fish config..."
  mkdir -p "$HOME/.config/fish/"{conf.d,functions}
  ln -sf "$SCRIPT_DIR/fish/config.fish" "$HOME/.config/fish/config.fish"
  for f in "$REPO_ROOT/fish/functions/"*.fish; do
    ln -sf "$f" "$HOME/.config/fish/functions/$(basename "$f")"
  done
  success "Fish config symlinked"
}

step_default() {
  if [[ "$SHELL" != "$FISH_PATH" ]]; then
    info "Setting Fish as default shell..."
    chsh -s "$FISH_PATH"
    success "Fish set as default shell (takes effect next login)"
  else
    success "Fish already default shell"
  fi
}

step_docker_group() {
  if id -nG "$USER" | grep -qw docker; then
    success "$USER already in docker group"
  else
    info "Adding $USER to docker group (run docker without sudo)..."
    sudo usermod -aG docker "$USER"
    sudo systemctl enable --now docker.service
    success "Added to docker group — log out/in to take effect"
  fi
}

run_all() {
  step_base
  step_paru
  step_pacman_bundle
  step_aur_bundle
  step_symlink
  step_default
  step_docker_group
}

run_step() {
  case "$1" in
    1) step_base         ;;
    2) step_paru          ;;
    3) step_pacman_bundle ;;
    4) step_aur_bundle    ;;
    5) step_symlink       ;;
    6) step_default       ;;
    7) step_docker_group  ;;
    *) warn "Invalid step: $1 (valid: 1-7)"; return 1 ;;
  esac
}

show_menu() {
  echo "  1) base-devel + git"
  echo "  2) paru (AUR helper)"
  echo "  3) pacman bundle (official packages)"
  echo "  4) AUR bundle"
  echo "  5) Symlink Fish config"
  echo "  6) Set Fish as default shell"
  echo "  7) Add user to docker group"
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
