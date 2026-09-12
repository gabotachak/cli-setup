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

start_sudo_keepalive() {
  sudo -v
  ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT
}

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
# $1 = list file, $2.. = install command the package name is appended to.
install_list() {
  local list=$1; shift
  local -a cmd=("$@")
  local failed=()
  while IFS= read -r pkg; do
    pkg="$(echo "$pkg" | sed 's/#.*//' | xargs)"
    [[ -z "$pkg" ]] && continue
    if "${cmd[@]}" "$pkg"; then
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

step_pacman_bundle() {
  info "Installing packages from pacman.txt..."
  # -Syu, never -Sy alone: a partial upgrade (new pkg against a stale db) can
  # break the system when shared libs get out of sync.
  sudo pacman -Syu --needed --noconfirm - < <(grep -vE '^\s*#|^\s*$' "$SCRIPT_DIR/pacman.txt")
  success "Official packages installed"
}

step_aur_bundle() {
  if ! command -v shelly &>/dev/null; then
    warn "shelly not found — it ships with CachyOS; install it before this step"
    return 1
  fi
  info "Installing packages from aur.txt via shelly (builds from source, slow)..."
  install_list "$SCRIPT_DIR/aur.txt" shelly install aur --no-confirm
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
    sudo usermod -s "$FISH_PATH" "$USER"
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

step_claude_plugins() {
  info "Checking Claude Code plugins..."
  if ! claude plugin list 2>/dev/null | grep -q "caveman"; then
    info "Installing caveman plugin..."
    curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
    success "caveman installed"
  else
    success "caveman already installed"
  fi

  if [[ ! -d "$HOME/.agents/skills/find-skills" ]]; then
    info "Installing find-skills..."
    (cd "$HOME" && npx skills add https://github.com/vercel-labs/skills --skill find-skills)
    success "find-skills installed"
  else
    success "find-skills already installed"
  fi
}

run_all() {
  step_base
  step_pacman_bundle
  step_aur_bundle
  step_symlink
  step_default
  step_docker_group
  step_claude_plugins
}

run_step() {
  case "$1" in
    1) step_base          ;;
    2) step_pacman_bundle  ;;
    3) step_aur_bundle     ;;
    4) step_symlink        ;;
    5) step_default        ;;
    6) step_docker_group   ;;
    7) step_claude_plugins ;;
    *) warn "Invalid step: $1 (valid: 1-7)"; return 1 ;;
  esac
}

show_menu() {
  echo "  1) base-devel + git"
  echo "  2) pacman bundle (official packages)"
  echo "  3) AUR bundle (via shelly)"
  echo "  4) Symlink Fish config"
  echo "  5) Set Fish as default shell"
  echo "  6) Add user to docker group"
  echo "  7) Claude Code plugins (caveman, find-skills)"
  echo "  a) Run all steps"
  echo "  q) Quit"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────

banner
start_sudo_keepalive

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
