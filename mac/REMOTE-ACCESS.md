# Remote access to the Arch PC — Mac-side setup

Instructions for Claude Code running on the Mac. Goal: use the Arch PC (PC-Gabo,
RTX 3060, CachyOS + Hyprland) from the Mac. Terminal work goes over SSH, the full
desktop over Moonlight.

## Already done on the PC (2026-10-16, verified)

- `sshd` is running and accepts **keys only**. Password login is refused. Every key
  on `github.com/gabotachak.keys` is authorized, so the Mac's `~/.ssh/id_ed25519`
  (from `gh auth login`) works if it's registered on GitHub.
- Tailscale is logged in. The PC is `pc-gabo` at `100.110.149.21`.
- DNS: `pc.gabotachak.dev` → `100.110.149.21` (Cloudflare A record, DNS only).
  The address is only reachable from inside the tailnet.
- ufw on the PC only accepts traffic on `tailscale0`, so **nothing works unless the
  Mac is logged into Tailscale**, even when both are on the same LAN.
- Sunshine (desktop streaming, NVENC) starts with the Hyprland session. Its web UI
  is `https://localhost:47990` and is only reachable from the PC itself.
- Wake-on-LAN (magic packet) is enabled on the NIC. MAC address: `9c:6b:00:18:59:f4`.
  The BIOS setting has not been checked.

PC-side scripts: `arch/setup-remote.sh` (this repo) and
`hyprland-config/system/setup-sunshine.sh`.

## Steps on the Mac

1. **Pull this repo** and install the new packages:
   ```bash
   cd ~/github.com/gabotachak/cli-setup && git pull
   brew bundle --file=mac/Brewfile    # adds wakeonlan
   brew bundle --file=mac/Caskfile    # adds tailscale-app, moonlight
   ```
   Running only the new ones is also fine:
   `brew install wakeonlan && brew install --cask tailscale-app moonlight`.

2. **Tailscale.** Open the Tailscale app and log in with the **same account** as the
   PC (the user does this in the GUI). Check it with:
   ```bash
   /Applications/Tailscale.app/Contents/MacOS/Tailscale status   # pc-gabo should be listed
   ```
   The old Mac node `co000h79wyn4r0q` has been offline for over a year. It can be
   removed from the Tailscale admin console.

3. **SSH config.** `~/.ssh/config` should be a symlink to `ssh/config` in this repo
   (created by `mac/setup.sh` step 6). It now has `Host desktop pc` →
   `pc.gabotachak.dev`. If it isn't a symlink, ask the user before replacing it, then run
   `ln -sf "$PWD/ssh/config" ~/.ssh/config`. Test it:
   ```bash
   ssh -o BatchMode=yes desktop 'echo ok from $(hostname)'   # expect: ok from PC-Gabo
   ```
   If you get `Permission denied (publickey)`, the Mac's key isn't on GitHub. Check
   `gh ssh-key list` against `cat ~/.ssh/id_ed25519.pub`. Fix it by adding the key
   (`gh ssh-key add ~/.ssh/id_ed25519.pub --type authentication`), then on the
   PC run `bash ~/Repos/cli-setup/arch/setup-remote.sh` again (or append the key to
   `~/.ssh/authorized_keys` over another session).

4. **Shell aliases.** `fish/config.fish` and `zsh/.zshrc` now define `wakepc`
   (`wakeonlan 9c:6b:00:18:59:f4`). It only works on the same LAN as the PC, and only
   if WoL is enabled in the PC's BIOS. Open a new terminal to pick up the alias.

5. **VS Code Remote-SSH.** Install `ms-vscode-remote.remote-ssh` if it's missing
   (it's in `vscode/extensions.txt`). Then use Command Palette → "Remote-SSH:
   Connect to Host" → `desktop`.

6. **Moonlight (full desktop)**: this needs the user, because a PIN is involved.
   - On the PC, the user opens `https://localhost:47990` and creates the Sunshine
     login (first run only).
   - On the Mac: Moonlight → **Add Host manually** → `pc.gabotachak.dev`. Moonlight
     shows a PIN, and the user enters it in the Sunshine web UI under the **PIN** tab.
   - Suggested settings: 60 fps, HEVC, bitrate around 20–40 Mbps on Wi-Fi. On a
     Retina screen, use the PC monitor's native resolution.

## Troubleshooting

- `ssh: connect ... timed out`: Tailscale is off or logged out on one side.
- `pc.gabotachak.dev` doesn't resolve: check `dig +short pc.gabotachak.dev @1.1.1.1`.
  It should return `100.110.149.21`. If the PC's Tailscale IP changed, re-run
  `setup-remote.sh` on the PC with `CLOUDFLARE_API_TOKEN` set.
- Moonlight connects but shows a black screen: Sunshine isn't running in the
  Hyprland session. Fix it with `ssh desktop 'hyprctl dispatch exec sunshine'`.
- Known issue: Sunshine logs `Failed to gain CAP_SYS_ADMIN` and falls back to
  wlr-screencopy capture. NVENC still works, so this is fine.

When everything works, tell the user so they can push and regenerate
`hyprland-config/system/packages.txt` on the PC.
