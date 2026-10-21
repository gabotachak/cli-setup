#!/usr/bin/env bash
# setup.sh — Bootstrap a fresh Mac
# Usage: bash setup.sh              → interactive menu
#        bash setup.sh all          → run all steps
#        bash setup.sh <1-10>        → run single step
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

  info "Symlinking Git config..."
  ln -sf "$REPO_ROOT/git/.gitconfig" "$HOME/.gitconfig"
  success "Git config symlinked"

  info "Symlinking SSH config..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ln -sf "$REPO_ROOT/ssh/config" "$HOME/.ssh/config"
  success "SSH config symlinked"

  info "Symlinking Ghostty config..."
  mkdir -p "$HOME/.config/ghostty"
  ln -sf "$REPO_ROOT/ghostty/config" "$HOME/.config/ghostty/config"
  success "Ghostty config symlinked"

  if command -v codium &>/dev/null; then
    info "Symlinking VSCodium settings..."
    VSCODIUM_USER="$HOME/Library/Application Support/VSCodium/User"
    mkdir -p "$VSCODIUM_USER"
    ln -sf "$REPO_ROOT/vscodium/settings.json"    "$VSCODIUM_USER/settings.json"
    ln -sf "$REPO_ROOT/vscodium/keybindings.json" "$VSCODIUM_USER/keybindings.json"
    # todo-tree can't find VSCodium's bundled rg (ripgrep-universal layout), and its
    # path setting is shared with arch, so both OSes expose rg at /usr/local/bin/rg.
    sudo mkdir -p /usr/local/bin && sudo ln -sf "$(brew --prefix)/bin/rg" /usr/local/bin/rg
    info "Installing VSCodium extensions from Open VSX..."
    xargs -n1 codium --install-extension < "$REPO_ROOT/vscodium/extensions.txt" &>/dev/null || true
    success "VSCodium configured"
  fi
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

  info "Linking ~/.claude/CLAUDE.md + settings.json to the repo..."
  for f in CLAUDE.md settings.json; do
    if [[ -e "$c/$f" && ! -L "$c/$f" ]] && ! cmp -s "$c/$f" "$cfg/$f"; then
      bak="$c/$f.bak"; [[ -e "$bak" ]] && bak="$bak.$(date +%s)"
      mv "$c/$f" "$bak"
      warn "$c/$f differed from the repo copy — saved as $bak"
    fi
    ln -sfn "$cfg/$f" "$c/$f"
  done
  success "CLAUDE.md + settings.json linked"

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
    sed -i '' "s#\${CLAUDE_PLUGIN_ROOT}/\.claude/skills/ui-ux-pro-max/#$HOME/.claude/skills/ui-ux-pro-max/#g; s#[^\" ]*/\.claude-[A-Za-z]*/skills/ui-ux-pro-max/#$HOME/.claude/skills/ui-ux-pro-max/#g" "$c/skills/ui-ux-pro-max/SKILL.md"
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

run_all() {
  step_xcode
  step_homebrew
  step_bundle
  step_fish
  step_fisher
  step_symlink
  step_default
  step_claude_code
  step_claude_plugins
  step_claude_config
}

run_step() {
  case "$1" in
    1) step_xcode         ;;
    2) step_homebrew      ;;
    3) step_bundle        ;;
    4) step_fish          ;;
    5) step_fisher        ;;
    6) step_symlink       ;;
    7) step_default       ;;
    8) step_claude_code   ;;
    9) step_claude_plugins ;;
    10) step_claude_config ;;
    *) warn "Invalid step: $1 (valid: 1-10)"; return 1 ;;
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
  echo "  8) Claude Code CLI"
  echo "  9) Claude Code plugins (ponytail, omniroute, graphify, agent-skills, find-skills)"
  echo "  10) Claude Code config (profiles, skills, MCP)"
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
