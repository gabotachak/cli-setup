#!/usr/bin/env bash
# hygiene.sh — Periodic disk hygiene for a dev Mac
# Usage: bash hygiene.sh [--apply] [--quarterly]
#
#   (no flags)    Dry run. Reports what would be freed. Deletes nothing.
#   --apply       Actually delete the monthly-tier items.
#   --quarterly   Include the slow accumulators (DeviceSupport, dyld, sim data).
#
# Never touches: iOS runtimes, WhatsApp media, Photos, ~/Repos. Those need
# judgment, so they are reported only.
set -euo pipefail

APPLY=false
QUARTERLY=false
for arg in "$@"; do
  case "$arg" in
    --apply)     APPLY=true ;;
    --quarterly) QUARTERLY=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

info()    { echo "  [→] $*"; }
success() { echo "  [✓] $*"; }
warn()    { echo "  [!] $*"; }
skip()    { echo "  [·] $*"; }

TOTAL_KB=0

# Disk usage of a path in KB, 0 if missing.
size_kb() { du -sk "$1" 2>/dev/null | cut -f1 || echo 0; }

human() {
  local kb=$1
  if   [ "$kb" -ge 1048576 ]; then printf "%.1f GB" "$(echo "$kb/1048576" | bc -l)"
  elif [ "$kb" -ge 1024 ];    then printf "%.0f MB" "$(echo "$kb/1024" | bc -l)"
  else printf "%s KB" "$kb"
  fi
}

free_kb() { df -k /System/Volumes/Data | awk 'NR==2{print $4}'; }

# Report a deletion candidate and run the command if --apply.
# Usage: candidate <label> <path-to-measure> <command...>
candidate() {
  local label="$1" path="$2"; shift 2
  local kb; kb=$(size_kb "$path")
  if [ "$kb" -lt 1024 ]; then
    skip "$label — nothing to reclaim"
    return 0
  fi
  TOTAL_KB=$((TOTAL_KB + kb))
  if $APPLY; then
    "$@" >/dev/null 2>&1 || warn "$label — command failed, skipped"
    success "$label — freed $(human "$kb")"
  else
    info "$label — would free $(human "$kb")"
  fi
}

START_FREE=$(free_kb)

HEADER="$USER — disk hygiene"
echo ""
echo "╔══════════════════════════════════════════╗"
printf "║%*s%s%*s║\n" $(( (42 - ${#HEADER}) / 2 )) "" "$HEADER" \
  $(( 42 - ${#HEADER} - (42 - ${#HEADER}) / 2 )) ""
echo "╚══════════════════════════════════════════╝"
$APPLY || warn "DRY RUN — nothing will be deleted. Re-run with --apply."
echo ""
info "Free now: $(human "$START_FREE")"
echo ""

# ── 1. Homebrew ───────────────────────────────────────────────
echo "── Homebrew ──"
candidate "Homebrew download cache" "$HOME/Library/Caches/Homebrew/downloads" \
  rm -rf "$HOME/Library/Caches/Homebrew/downloads"
if $APPLY; then
  brew cleanup --prune=all -s >/dev/null 2>&1 || warn "brew cleanup failed"
  success "brew cleanup --prune=all -s"
else
  info "brew cleanup --prune=all -s — would run"
fi
echo ""

# ── 2. Simulators ─────────────────────────────────────────────
echo "── iOS Simulators ──"
if command -v xcrun >/dev/null 2>&1; then
  DEAD=$(xcrun simctl list devices 2>/dev/null | grep -c unavailable || true)
  if [ "$DEAD" -gt 0 ]; then
    if $APPLY; then
      xcrun simctl delete unavailable >/dev/null 2>&1 || true
      success "Deleted $DEAD unavailable sim devices"
    else
      info "$DEAD unavailable sim devices — would delete"
    fi
  else
    skip "No unavailable sim devices"
  fi

  # Runtimes are expensive and need judgment. Report only.
  echo ""
  info "Installed runtimes (delete N-2 and older by hand):"
  xcrun simctl runtime list 2>/dev/null | sed 's/^/      /' || true
  echo "      → xcrun simctl runtime delete <BUILD_ID>"
fi
echo ""

# ── 3. Xcode build artifacts ──────────────────────────────────
echo "── Xcode ──"
candidate "DerivedData" "$HOME/Library/Developer/Xcode/DerivedData" \
  rm -rf "$HOME/Library/Developer/Xcode/DerivedData"
candidate "Archives" "$HOME/Library/Developer/Xcode/Archives" \
  rm -rf "$HOME/Library/Developer/Xcode/Archives"
echo ""

# ── 4. Docker ─────────────────────────────────────────────────
echo "── Docker ──"
if docker info >/dev/null 2>&1; then
  docker system df 2>/dev/null | sed 's/^/      /'
  if $APPLY; then
    docker system prune -af >/dev/null 2>&1 || warn "docker prune failed"
    success "docker system prune -af (volumes kept)"
  else
    info "docker system prune -af — would run (volumes kept)"
  fi
else
  skip "Docker not running"
fi
echo ""

# ── 5. Build tool caches ──────────────────────────────────────
echo "── Build caches ──"
candidate "Gradle build cache" "$HOME/.gradle/caches/build-cache-1" \
  rm -rf "$HOME/.gradle/caches/build-cache-1"
candidate "npm cache" "$HOME/.npm/_cacache" rm -rf "$HOME/.npm/_cacache"
candidate "Trash" "$HOME/.Trash" rm -rf "$HOME/.Trash"
echo ""

# ── 6. Quarterly: the slow accumulators ───────────────────────
if $QUARTERLY; then
  echo "── Quarterly ──"

  # DeviceSupport grows one folder per iOS build, forever. Keep newest only.
  DS="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  if [ -d "$DS" ]; then
    OLD=$(ls -1t "$DS" 2>/dev/null | tail -n +2)
    if [ -n "$OLD" ]; then
      while IFS= read -r d; do
        candidate "DeviceSupport: $d" "$DS/$d" rm -rf "$DS/$d"
      done <<< "$OLD"
    else
      skip "DeviceSupport — only newest present"
    fi
  fi

  # dyld sim caches regenerate on next simulator boot.
  DYLD="/Library/Developer/CoreSimulator/Caches/dyld"
  DYLD_KB=$(size_kb "$DYLD")
  if [ "$DYLD_KB" -gt 1024 ]; then
    TOTAL_KB=$((TOTAL_KB + DYLD_KB))
    if $APPLY; then
      sudo rm -rf "$DYLD" && success "dyld sim caches — freed $(human "$DYLD_KB")"
    else
      info "dyld sim caches — would free $(human "$DYLD_KB") (needs sudo)"
    fi
  fi

  echo ""
  info "Review by hand (real data, not caches):"
  for p in \
    "$HOME/Library/Group Containers/group.net.whatsapp.WhatsApp.shared" \
    "$HOME/Pictures/Photos Library.photoslibrary" \
    "$HOME/Library/Application Support/Claude/vm_bundles" \
    "$HOME/Library/Android/sdk/system-images"
  do
    [ -e "$p" ] && echo "      $(du -sh "$p" 2>/dev/null | cut -f1)  ${p/#$HOME/~}"
  done
  echo ""
fi

# ── Summary ───────────────────────────────────────────────────
END_FREE=$(free_kb)
echo "══════════════════════════════════════════"
if $APPLY; then
  success "Reclaimed $(human $((END_FREE - START_FREE)))"
  info "Free now: $(human "$END_FREE")"
else
  if [ "$TOTAL_KB" -lt 1024 ]; then
    success "Measured candidates are already clean"
  else
    info "Would reclaim ~$(human "$TOTAL_KB") from measured paths"
  fi
  info "Plus whatever brew cleanup and docker prune release (see above)"
  warn "Re-run with --apply to execute."
fi
echo ""
