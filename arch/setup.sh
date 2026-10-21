#!/usr/bin/env bash
# setup.sh — Bootstrap a fresh Arch/CachyOS box
# Usage: bash setup.sh        → interactive menu
#        bash setup.sh all    → run all steps
#        bash setup.sh <1-10> → run single step
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
  info "Symlinking Ghostty config..."
  mkdir -p "$HOME/.config/ghostty"
  ln -sf "$REPO_ROOT/ghostty/config" "$HOME/.config/ghostty/config"
  success "Ghostty config symlinked"
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

step_claude_code() {
  info "Checking Claude Code..."
  if ! command -v claude &>/dev/null; then
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  success "Claude Code ready"
}

step_claude_plugins() {
  info "Checking Claude Code plugins..."
  if ! claude plugin list 2>/dev/null | grep -q "ponytail"; then
    info "Installing ponytail plugin..."
    claude plugin marketplace add DietrichGebert/ponytail
    claude plugin install ponytail@ponytail -y
    success "ponytail installed"
  else
    success "ponytail already installed"
  fi

  if ! command -v omniroute &>/dev/null; then
    info "Installing omniroute..."
    npm install -g omniroute
    success "omniroute installed"
  else
    success "omniroute already installed"
  fi

  if ! command -v graphify &>/dev/null; then
    info "Installing graphify..."
    uv tool install graphifyy
    graphify install
    success "graphify installed"
  else
    success "graphify already installed"
  fi

  if ! claude plugin list 2>/dev/null | grep -q "agent-skills"; then
    info "Installing agent-skills plugin..."
    claude plugin marketplace add joeblackwaslike/agent-marketplace
    claude plugin install agent-skills -y
    success "agent-skills installed"
  else
    success "agent-skills already installed"
  fi

  if [[ ! -d "$HOME/.agents/skills/find-skills" ]]; then
    info "Installing find-skills..."
    (cd "$HOME" && npx skills add https://github.com/vercel-labs/skills --skill find-skills)
    success "find-skills installed"
  else
    success "find-skills already installed"
  fi
}

# Run `claude` against a config dir ("" = default ~/.claude, so no env var at all).
claude_in() {
  local dir=$1; shift
  if [[ -n "$dir" ]]; then CLAUDE_CONFIG_DIR="$dir" claude "$@"; else env -u CLAUDE_CONFIG_DIR claude "$@"; fi
}

step_claude_config() {
  local cfg="$REPO_ROOT/claude" c="$HOME/.claude" f bak repo skill p pd e s t
  mkdir -p "$c/skills"

  info "Linking ~/.claude/CLAUDE.md to the repo..."
  f=CLAUDE.md
  if [[ -e "$c/$f" && ! -L "$c/$f" ]] && ! cmp -s "$c/$f" "$cfg/$f"; then
    bak="$c/$f.bak"; [[ -e "$bak" ]] && bak="$bak.$(date +%s)"
    mv "$c/$f" "$bak"
    warn "$c/$f differed from the repo copy — saved as $bak"
  fi
  ln -sfn "$cfg/$f" "$c/$f"
  success "CLAUDE.md linked"

  # Not a symlink: an interactive session (/model) replaces a symlinked settings.json with a real file.
  # Repo keys win; keys Claude Code adds locally are kept.
  info "Merging repo settings.json into ~/.claude/settings.json..."
  [[ -L "$c/settings.json" ]] && rm "$c/settings.json"
  [[ -f "$c/settings.json" ]] || echo '{}' > "$c/settings.json"
  jq -s '.[0] * .[1]' "$c/settings.json" "$cfg/settings.json" > "$c/settings.json.tmp" \
    && mv "$c/settings.json.tmp" "$c/settings.json" && success "settings.json merged" \
    || { rm -f "$c/settings.json.tmp"; warn "settings.json merge failed (invalid JSON?)"; }

  info "Installing third-party skills..."
  while read -r repo skill; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    if [[ -e "$c/skills/$skill" ]]; then
      success "$skill already installed"
    # -g -a claude-code --copy puts real files straight in ~/.claude/skills, no prompts, no ~/.agents symlinks
    elif (cd "$HOME" && npx -y skills add "$repo" -g -a claude-code -s "$skill" -y --copy </dev/null >/dev/null 2>&1); then
      success "$skill installed"
    else
      warn "Failed: $skill ($repo)"
    fi
  done < "$cfg/skills.txt"

  # Upstream SKILL.md points at ${CLAUDE_PLUGIN_ROOT}/.claude/skills/..., which only exists inside a plugin.
  if [[ -f "$c/skills/ui-ux-pro-max/SKILL.md" ]]; then
    sed -i "s#\${CLAUDE_PLUGIN_ROOT}/\.claude/skills/ui-ux-pro-max/#$HOME/.claude/skills/ui-ux-pro-max/#g; s#[^\" ]*/\.claude-[A-Za-z]*/skills/ui-ux-pro-max/#$HOME/.claude/skills/ui-ux-pro-max/#g" "$c/skills/ui-ux-pro-max/SKILL.md"
    rm -rf "$c/skills/ui-ux-pro-max/scripts/tests"
    success "ui-ux-pro-max patched"
  fi

  info "Sharing config with extra profiles..."
  mkdir -p "$c/plugins" "$c/projects" "$c/file-history" "$c/paste-cache" "$c/ponytail-modes"
  touch "$c/history.jsonl"
  while read -r p; do
    [[ -z "$p" || "$p" == \#* ]] && continue
    pd="$HOME/.claude-$p"
    mkdir -p "$pd/skills"
    for e in CLAUDE.md settings.json plugins projects history.jsonl file-history paste-cache ponytail-modes .ponytail-active ponytail-statusline.sh; do
      if [[ -e "$pd/$e" && ! -L "$pd/$e" ]]; then warn "$pd/$e is a real file/dir — skipped"; else ln -sfn "$c/$e" "$pd/$e"; fi
    done
    for s in "$c"/skills/*; do
      [[ -e "$s" ]] || continue
      t=$(basename "$s"); [[ "$t" == synced ]] && continue
      if [[ -e "$pd/skills/$t" && ! -L "$pd/skills/$t" ]]; then warn "$pd/skills/$t is a real dir — skipped"; else ln -sfn "$s" "$pd/skills/$t"; fi
    done
    success "profile $p linked"
  done < "$cfg/profiles.txt"

  info "Checking plane MCP..."
  for p in "" $(grep -v '^#' "$cfg/profiles.txt"); do
    pd=""; [[ -n "$p" ]] && pd="$HOME/.claude-$p"
    if claude_in "$pd" mcp get plane &>/dev/null; then
      success "plane MCP present (${p:-default})"
    else
      claude_in "$pd" mcp add --transport http -s user plane https://mcp.plane.so/http/mcp \
        && success "plane MCP added (${p:-default})" || warn "plane MCP failed (${p:-default})"
    fi
  done
  info "Run /login in each profile (claude, claude-work, claude-korvy), then /mcp to authenticate plane"
}

step_vscodium() {
  if ! command -v codium &>/dev/null; then
    warn "codium not found — install vscodium (hyprland-config packages.txt) first"
    return 1
  fi
  info "Symlinking VSCodium settings..."
  mkdir -p "$HOME/.config/VSCodium/User"
  ln -sf "$REPO_ROOT/vscodium/settings.json"    "$HOME/.config/VSCodium/User/settings.json"
  ln -sf "$REPO_ROOT/vscodium/keybindings.json" "$HOME/.config/VSCodium/User/keybindings.json"
  # todo-tree can't find VSCodium's bundled rg (ripgrep-universal layout), and its
  # path setting is shared with mac, so both OSes expose rg at /usr/local/bin/rg.
  sudo ln -sf /usr/bin/rg /usr/local/bin/rg
  info "Installing VSCodium extensions from Open VSX..."
  install_list "$REPO_ROOT/vscodium/extensions.txt" codium --install-extension
  success "VSCodium configured"
}

run_all() {
  step_base
  step_pacman_bundle
  step_aur_bundle
  step_symlink
  step_default
  step_docker_group
  step_claude_code
  step_claude_plugins
  step_claude_config
  step_vscodium
}

run_step() {
  case "$1" in
    1) step_base          ;;
    2) step_pacman_bundle  ;;
    3) step_aur_bundle     ;;
    4) step_symlink        ;;
    5) step_default        ;;
    6) step_docker_group   ;;
    7) step_claude_code    ;;
    8) step_claude_plugins ;;
    9) step_claude_config  ;;
    10) step_vscodium      ;;
    *) warn "Invalid step: $1 (valid: 1-10)"; return 1 ;;
  esac
}

show_menu() {
  echo "  1) base-devel + git"
  echo "  2) pacman bundle (official packages)"
  echo "  3) AUR bundle (via shelly)"
  echo "  4) Symlink Fish + Ghostty config"
  echo "  5) Set Fish as default shell"
  echo "  6) Add user to docker group"
  echo "  7) Claude Code CLI"
  echo "  8) Claude Code plugins (ponytail, omniroute, graphify, agent-skills, find-skills)"
  echo "  9) Claude Code config (profiles, skills, MCP)"
  echo "  10) VSCodium settings + extensions"
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
  [1-9]|10)
    run_step "$1"
    ;;
  "")
    while true; do
      show_menu
      read -rp "  Select: " choice
      echo ""
      case "$choice" in
        [1-9]|10) run_step "$choice" ;;
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
    echo "  Usage: bash setup.sh [all|1-10]"
    exit 1
    ;;
esac
