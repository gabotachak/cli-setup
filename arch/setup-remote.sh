#!/usr/bin/env bash
# setup-remote.sh — Make this box reachable from the Mac: SSH (keys only) over
# Tailscale, pc.gabotachak.dev pointing at the Tailscale IP, and Wake-on-LAN.
# Desktop streaming (Sunshine) is GUI, so it lives in hyprland-config:
#   bash ~/Repos/hyprland-config/system/setup-sunshine.sh
#
# Usage: bash setup-remote.sh
# Needs an interactive terminal (sudo + Tailscale login link). Idempotent.
# Set CLOUDFLARE_API_TOKEN (Zone:DNS:Edit on gabotachak.dev) to upsert the DNS
# record automatically; otherwise you're prompted (blank = skip).
set -euo pipefail

DOMAIN="gabotachak.dev"
RECORD="pc.$DOMAIN"
GITHUB_USER="gabotachak"
SSHD_DROPIN=/etc/ssh/sshd_config.d/10-remote.conf

info()    { echo "  [→] $*"; }
success() { echo "  [✓] $*"; }
warn()    { echo "  [!] $*"; }

step_packages() {
  info "Installing openssh, tailscale, ethtool, jq..."
  sudo pacman -S --needed --noconfirm openssh tailscale ethtool jq
  success "Packages ready"
}

step_authorized_keys() {
  # The Mac's key is already registered on GitHub (gh auth login), so pull every
  # auth key from there instead of copying it by hand. Merge, never overwrite.
  info "Adding GitHub keys of $GITHUB_USER to ~/.ssh/authorized_keys..."
  local keys
  keys="$(curl -fsSL "https://github.com/$GITHUB_USER.keys")"
  [[ -n "$keys" ]] || { warn "No keys on github.com/$GITHUB_USER.keys"; return 1; }
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  touch "$HOME/.ssh/authorized_keys"
  { cat "$HOME/.ssh/authorized_keys"; echo "$keys"; } | grep -v '^\s*$' | sort -u > "$HOME/.ssh/authorized_keys.tmp"
  mv "$HOME/.ssh/authorized_keys.tmp" "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
  success "$(wc -l < "$HOME/.ssh/authorized_keys") keys authorized"
}

step_sshd() {
  info "Hardening sshd (keys only, no root) → $SSHD_DROPIN"
  sudo tee "$SSHD_DROPIN" >/dev/null <<'EOF'
# Managed by cli-setup/arch/setup-remote.sh
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers gabotachak
EOF
  # Host keys only get generated on sshd's first start (sshdgenkeys.service),
  # which is after `sshd -t` on a fresh box. -A only creates missing ones.
  sudo ssh-keygen -A
  sudo sshd -t
  sudo systemctl enable --now sshd.service
  sudo systemctl reload sshd.service
  success "sshd running"
}

step_tailscale() {
  sudo systemctl enable --now tailscaled.service
  if tailscale status &>/dev/null; then
    success "Tailscale already logged in"
  else
    # --operator lets this user run `tailscale` without sudo afterwards.
    info "Logging into Tailscale — open the link it prints..."
    sudo tailscale up --operator="$USER"
  fi
  success "Tailscale IP: $(tailscale ip -4)"
}

step_firewall() {
  if ! systemctl is-active --quiet ufw; then
    success "ufw not active — nothing to open"
    return
  fi
  # Tailscale peers are authenticated devices of this account: trust the whole
  # interface (SSH + Sunshine ports) and keep the LAN/WAN side closed.
  info "Allowing all inbound traffic on tailscale0 (ufw)..."
  sudo ufw allow in on tailscale0 comment 'tailscale peers'
  success "ufw: tailscale0 allowed"
}

step_wol() {
  local con dev
  con="$(nmcli -t -f NAME,TYPE con show --active | awk -F: '$2=="802-3-ethernet"{print $1; exit}')"
  dev="$(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2=="ethernet"{print $1; exit}')"
  if [[ -z "$con" || -z "$dev" ]]; then
    warn "No active wired connection — Wake-on-LAN needs ethernet"
    return
  fi
  if ! sudo ethtool "$dev" | grep -q 'Supports Wake-on:.*g'; then
    warn "$dev does not support magic-packet Wake-on-LAN"
    return
  fi
  info "Enabling Wake-on-LAN (magic packet) on $dev / '$con'..."
  sudo nmcli con modify "$con" 802-3-ethernet.wake-on-lan magic
  sudo ethtool -s "$dev" wol g
  success "WoL on. MAC: $(cat "/sys/class/net/$dev/address") — also enable it in the BIOS (often 'Power On By PCI-E')"
}

step_dns() {
  local token="${CLOUDFLARE_API_TOKEN:-}" ip zone rec api="https://api.cloudflare.com/client/v4"
  if [[ -z "$token" ]]; then
    read -rsp "  Cloudflare API token (Zone:DNS:Edit, blank = skip): " token; echo
  fi
  if [[ -z "$token" ]]; then
    warn "Skipped DNS — create A $RECORD → $(tailscale ip -4) (DNS only, not proxied) by hand"
    return
  fi
  ip="$(tailscale ip -4)"
  cf() { curl -fsS -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$@"; }
  zone="$(cf "$api/zones?name=$DOMAIN" | jq -r '.result[0].id')"
  rec="$(cf "$api/zones/$zone/dns_records?type=A&name=$RECORD" | jq -r '.result[0].id // empty')"
  # proxied=false: a 100.x Tailscale address only resolves to something useful
  # inside the tailnet; Cloudflare's proxy can't reach it.
  local body
  body="$(jq -n --arg n "$RECORD" --arg ip "$ip" '{type:"A",name:$n,content:$ip,ttl:1,proxied:false,comment:"Tailscale IP of PC-Gabo"}')"
  if [[ -n "$rec" ]]; then
    cf -X PUT "$api/zones/$zone/dns_records/$rec" --data "$body" >/dev/null
  else
    cf -X POST "$api/zones/$zone/dns_records" --data "$body" >/dev/null
  fi
  success "$RECORD → $ip"
}

echo ""
echo "  Remote access setup (SSH + Tailscale + $RECORD + WoL)"
echo ""
sudo -v
step_packages
step_authorized_keys
step_sshd
step_tailscale
step_firewall
step_wol
step_dns
echo ""
echo "  Done. From the Mac (with Tailscale logged into the same account):"
echo "    ssh desktop        # ssh/config → $RECORD"
echo "    wakepc             # magic packet, same LAN only"
echo ""
