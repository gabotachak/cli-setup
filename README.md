# cli-setup

> Personal shell config + CLI toolchain bootstrap — macOS and Arch Linux (CachyOS). Arch is CLI-only; macOS still bundles its GUI apps via `Caskfile`.

![macOS](https://img.shields.io/badge/macOS-Tahoe-000000?logo=apple&logoColor=white)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-CachyOS-1793D1?logo=archlinux&logoColor=white)
![Fish Shell](https://img.shields.io/badge/Fish_Shell-4.7-4aae47?logo=gnubash&logoColor=white)
![Zsh](https://img.shields.io/badge/Zsh-5.9-89e051?logo=gnubash&logoColor=white)
![Homebrew](https://img.shields.io/badge/Homebrew-darkred?logo=homebrew&logoColor=white)
![Tide](https://img.shields.io/badge/Tide-prompt-blue)

---

## Structure

```
cli-setup/
├── zsh/
│   ├── .zshrc       # Zsh config (plain, no framework)
│   └── .zprofile    # Homebrew PATH
├── fish/
│   ├── config.fish           # Fish config (macOS, Tide prompt)
│   └── functions/            # Shared git helper functions (mac + arch)
│       └── gac.fish          # git add . && git commit -m
├── git/
│   └── .gitconfig   # user, signing, LFS filter (mac's current state)
├── ssh/
│   └── config       # Host aliases (no keys — generate those separately)
├── ghostty/
│   └── config       # Font + theme
├── vscodium/
│   ├── settings.json       # Symlinked into VSCodium (mac + arch)
│   ├── keybindings.json    # Symlinked into VSCodium (mac + arch)
│   └── extensions.txt      # Open VSX extensions (mac + arch)
├── claude/
│   ├── CLAUDE.md        # Global Claude Code instructions (symlinked to ~/.claude/CLAUDE.md)
│   ├── settings.json    # Global Claude Code settings (symlinked to ~/.claude/settings.json)
│   ├── profiles.txt     # Extra profiles sharing ~/.claude (work, korvy)
│   ├── skills.txt       # Third-party skills: `<github repo> <skill>`
│   └── SETUP.md         # Instructions for Claude to set this up on a machine
├── mac/
│   ├── Brewfile         # CLI formulae
│   ├── Caskfile         # GUI apps (casks) — skipped when CLI_ONLY=1
│   ├── setup.sh         # One-step bootstrap script
│   ├── setup-keys.sh    # SSH key + commit signing (SSH)
│   ├── hygiene.sh       # Disk cleanup (dry-run by default)
│   └── REMOTE-ACCESS.md # Mac-side steps to reach the Arch PC
└── arch/
    ├── pacman.txt        # Official repo CLI packages (Arch/CachyOS)
    ├── aur.txt           # AUR CLI packages (via shelly)
    ├── fish/config.fish  # Fish config (Arch, CachyOS theming)
    ├── setup.sh          # One-step bootstrap script
    ├── setup-keys.sh     # SSH key + commit signing (SSH)
    └── setup-remote.sh   # SSH + Tailscale + pc.gabotachak.dev + Wake-on-LAN
```

---

## Fresh Mac Setup

```bash
git clone git@github.com:gabotachak/cli-setup.git ~/github.com/gabotachak/cli-setup
bash ~/github.com/gabotachak/cli-setup/mac/setup.sh        # interactive menu
bash ~/github.com/gabotachak/cli-setup/mac/setup.sh all    # run all steps
CLI_ONLY=1 bash ~/github.com/gabotachak/cli-setup/mac/setup.sh all   # skip GUI apps
```

Steps (run all, or pick one from the menu):
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install packages via `Brewfile` (CLI) + `Caskfile` (GUI apps, unless `CLI_ONLY=1`)
4. Add Fish to `/etc/shells`
5. Install Fisher + Tide prompt
6. Symlink Fish/zsh/git/ssh/ghostty configs + VSCodium settings & extensions
7. Set Fish as default shell
8. Install Claude Code CLI
9. Install Claude Code plugins (ponytail, omniroute, graphify, agent-skills, find-skills)
10. Claude Code config: symlink `claude/CLAUDE.md` + `settings.json`, install `claude/skills.txt`, link the `claude/profiles.txt` profiles to `~/.claude`, add the `plane` MCP

Then open a new terminal and configure the prompt:
```bash
tide configure
```

---

## Fresh Arch Linux Setup (CachyOS)

```bash
git clone git@github.com:gabotachak/cli-setup.git ~/Repos/cli-setup
bash ~/Repos/cli-setup/arch/setup.sh
```

The script will:
1. Install `base-devel` + `git` (needed to build AUR packages)
2. Install all packages from `pacman.txt` (`pacman -Syu`)
3. Install all packages from `aur.txt` (`shelly install aur`, ships with CachyOS)
4. Symlink Fish config (reuses the same `fish/functions/` as macOS) + Ghostty config
5. Set Fish as default shell
6. Add your user to the `docker` group
7. Install Claude Code CLI
8. Install Claude Code plugins (ponytail, omniroute, graphify, agent-skills, find-skills)
9. Claude Code config: symlink `claude/CLAUDE.md` + `settings.json`, install `claude/skills.txt`, link the `claude/profiles.txt` profiles to `~/.claude`, add the `plane` MCP
10. Symlink VSCodium settings + install extensions from Open VSX (`vscodium` itself comes from `hyprland-config`)

> Needs an interactive terminal — `sudo`/AUR builds prompt for a password and confirmations, so run it directly rather than through a non-interactive shell.

---

## Claude Code profiles

`~/.claude` is the default profile; `~/.claude-work` and `~/.claude-korvy` (`claude/profiles.txt`) are
symlink views of it, so they differ only by account/billing. The config step shares CLAUDE.md,
settings.json, plugins, skills (except `synced`), history, projects, file-history, paste-cache and
the ponytail files; it never touches `.credentials.json`, `.claude.json`, `skills/synced`, sessions or caches.
Aliases: `claude`, `claude-work`, `claude-korvy`.

- After the step, run `/login` in each profile, then `/mcp` to authenticate `plane`.
- macOS: check that each `CLAUDE_CONFIG_DIR` uses its own Keychain entry (otherwise logins overwrite each other).
- Memories and `projects/` are NOT versioned (tied to absolute paths, private data).
- To have Claude do all this for you, point it at [`claude/SETUP.md`](claude/SETUP.md).

---

## SSH Key + Commit Signing

First authenticate with GitHub via `gh` — this generates `~/.ssh/id_ed25519` and
registers it with GitHub as an **Authentication key**:

```bash
gh auth login   # choose SSH as the git protocol
```

Then run `setup-keys.sh` to reuse that same key for commit signing (no GPG):

```bash
bash ~/github.com/gabotachak/cli-setup/mac/setup-keys.sh     # macOS
bash ~/Repos/cli-setup/arch/setup-keys.sh                    # Arch Linux
```

The script will:
1. Verify the SSH key from `gh auth login` exists (fails with instructions if not)
2. Configure git to **SSH-sign** all commits + tags with that key (no GPG),
   and write `~/.config/git/allowed_signers` for local verification
3. Register the same key with GitHub as a **Signing key** via `gh ssh-key add`
   (refreshing the `admin:ssh_signing_key` scope first if needed) — no manual paste

> Signing uses the SSH key directly — no `gnupg`/`pinentry` needed.

---

## Remote Access (Mac → Arch PC)

Use the PC's power from the Mac: SSH/VSCodium Remote-SSH for terminal work, Sunshine +
Moonlight for the full desktop. Everything goes over Tailscale (no ports opened
on the router); `pc.gabotachak.dev` is an A record (Cloudflare, DNS only) pointing
at the PC's Tailscale IP, so it only resolves to something reachable inside the tailnet.

```bash
bash ~/Repos/cli-setup/arch/setup-remote.sh                 # on the PC
bash ~/Repos/hyprland-config/system/setup-sunshine.sh       # on the PC (desktop streaming)
```

`setup-remote.sh`:
1. Installs `openssh`, `tailscale`, `ethtool`, `jq`
2. Authorizes every key on `github.com/gabotachak.keys` (merged into `~/.ssh/authorized_keys`)
3. Hardens sshd (keys only, no root) and enables it
4. Enables `tailscaled` and logs in (`--operator=$USER`)
5. `ufw allow in on tailscale0` (SSH + Sunshine reachable only from the tailnet)
6. Turns on Wake-on-LAN (magic packet) for the wired connection — also enable it in the BIOS
7. Upserts `pc.gabotachak.dev` → Tailscale IP via the Cloudflare API (`CLOUDFLARE_API_TOKEN`, Zone:DNS:Edit; blank = skip)

Mac-side walkthrough (for Claude on the Mac): [`mac/REMOTE-ACCESS.md`](mac/REMOTE-ACCESS.md).

On the Mac: `tailscale-app` + `moonlight` (Caskfile), `wakeonlan` (Brewfile),
`ssh desktop` / `ssh pc` (ssh/config), `wakepc` to power the PC on (same LAN only).

---

## Shell Features

### Fish (primary)

| Feature | How |
|---|---|
| Autosuggestions | Built-in |
| Syntax highlighting | Built-in |
| Git completions | Built-in |
| Prompt | [Tide v6](https://github.com/IlanCosman/tide) (Powerlevel10k-style) |
| Plugin manager | [Fisher](https://github.com/jorgebucaran/fisher) |

### Zsh (fallback)

| Feature | How |
|---|---|
| Prompt | System default |
| Plugin manager | None (plain config) |

---

## Git Aliases

| Alias | Command |
|---|---|
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gc` | `git checkout` |
| `gnew` | `git checkout -b` |
| `gac 'msg'` | `git add . && git commit -m 'msg'` |

Other: `claude-work` / `claude-korvy` run Claude Code with `CLAUDE_CONFIG_DIR=$HOME/.claude-work` / `.claude-korvy` (other accounts). `wakepc` (macOS) sends a Wake-on-LAN magic packet to the Arch PC.

---

## Installed Tools

### Dev

![Go](https://img.shields.io/badge/Go-00ADD8?logo=go&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?logo=nodedotjs&logoColor=white)
![mise](https://img.shields.io/badge/mise-runtime_manager-3776AB?logo=python&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)
![Colima](https://img.shields.io/badge/Colima-container_runtime-blue)
![gh](https://img.shields.io/badge/GitHub_CLI-181717?logo=github&logoColor=white)
![GPG](https://img.shields.io/badge/GPG-0093DD?logo=gnuprivacyguard&logoColor=white)
![pre-commit](https://img.shields.io/badge/pre--commit-FAB040?logo=precommit&logoColor=black)

### AI / ML

![Ollama](https://img.shields.io/badge/Ollama-local_LLMs-black)
![llmfit](https://img.shields.io/badge/llmfit-ML-orange)

### CLI Utilities

![eza](https://img.shields.io/badge/eza-modern_ls-4e4e4e)
![tree](https://img.shields.io/badge/tree-directory_view-4e4e4e)
![ncdu](https://img.shields.io/badge/ncdu-disk_usage-4e4e4e)
![fastfetch](https://img.shields.io/badge/fastfetch-system_info-4e4e4e)
![ffmpeg](https://img.shields.io/badge/FFmpeg-007808?logo=ffmpeg&logoColor=white)
![pandoc](https://img.shields.io/badge/pandoc-document_converter-4e4e4e)
![typst](https://img.shields.io/badge/Typst-markup_language-blue)
![opencode](https://img.shields.io/badge/opencode-terminal_agent-black)
![spotify-player](https://img.shields.io/badge/spotify--player-TUI-1DB954)
![speedtest-go](https://img.shields.io/badge/speedtest--go-network_speed-4e4e4e)

> Arch's GUI apps/desktop config (Hyprland, browsers, gaming, …) are **not** in
> this repo — they live in the machine dump in [`hyprland-config`](https://github.com/gabotachak/hyprland-config).
> macOS GUI apps stay here, in `mac/Caskfile`.
