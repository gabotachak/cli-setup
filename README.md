# cli-setup

> Personal shell configuration and one-step bootstrap — macOS and Arch Linux (CachyOS).

![macOS](https://img.shields.io/badge/macOS-Tahoe-000000?logo=apple&logoColor=white)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-CachyOS-1793D1?logo=archlinux&logoColor=white)
![Fish Shell](https://img.shields.io/badge/Fish_Shell-4.7-4aae47?logo=gnubash&logoColor=white)
![Zsh](https://img.shields.io/badge/Zsh-5.9-89e051?logo=gnubash&logoColor=white)
![Homebrew](https://img.shields.io/badge/Homebrew-darkred?logo=homebrew&logoColor=white)
![Powerlevel10k](https://img.shields.io/badge/Powerlevel10k-theme-blueviolet)
![Tide](https://img.shields.io/badge/Tide-prompt-blue)

---

## Structure

```
cli-setup/
├── zsh/
│   ├── .zshrc       # Zsh config (Oh My Zsh + Powerlevel10k)
│   └── .zprofile    # Homebrew + JetBrains Toolbox PATH
├── fish/
│   ├── config.fish           # Fish config (macOS, Tide prompt)
│   └── functions/            # Shared git helper functions (mac + arch)
│       └── gac.fish          # git add . && git commit -m
├── mac/
│   ├── Brewfile         # All formulae + casks
│   ├── setup.sh         # One-step bootstrap script
│   └── setup-keys.sh    # SSH key + commit signing (SSH)
└── arch/
    ├── pacman.txt        # Official repo packages (Arch/CachyOS)
    ├── aur.txt           # AUR packages (via shelly)
    ├── fish/config.fish  # Fish config (Arch, CachyOS theming)
    ├── setup.sh          # One-step bootstrap script
    └── setup-keys.sh     # SSH key + commit signing (SSH)
```

---

## Fresh Mac Setup

```bash
git clone git@github.com:gabotachak/cli-setup.git ~/github.com/gabotachak/cli-setup
bash ~/github.com/gabotachak/cli-setup/mac/setup.sh
```

The script will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install all packages via `Brewfile`
4. Add Fish to `/etc/shells`
5. Install Fisher + Tide prompt
6. Symlink all config files

After running, set Fish as default:
```bash
chsh -s /opt/homebrew/bin/fish
```
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
4. Symlink Fish config (reuses the same `fish/functions/` as macOS)
5. Set Fish as default shell
6. Add your user to the `docker` group
7. Install Claude Code plugins (caveman, find-skills)

> Needs an interactive terminal — `sudo`/AUR builds prompt for a password and confirmations, so run it directly rather than through a non-interactive shell.

---

## SSH Key + Commit Signing

Interactive assistant — you only need to paste the generated key into GitHub (twice).

```bash
bash ~/github.com/gabotachak/cli-setup/mac/setup-keys.sh     # macOS
bash ~/Repos/cli-setup/arch/setup-keys.sh                    # Arch Linux
```

The script will:
1. Generate an **Ed25519 SSH key** (if none exists)
2. Configure `~/.ssh/config` (macOS Keychain integration on the mac variant)
3. Open GitHub SSH settings → you paste the key as an **Authentication key**
4. Test the SSH connection
5. Configure git to **SSH-sign** all commits + tags with the same key (no GPG),
   and write `~/.config/git/allowed_signers` for local verification
6. Open GitHub SSH settings again → you paste the same key as a **Signing key**

> Signing uses the SSH key directly — no `gnupg`/`pinentry` needed.

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
| Prompt | [Powerlevel10k](https://github.com/romkatv/powerlevel10k) |
| Plugin manager | [Oh My Zsh](https://ohmyz.sh) |
| Autosuggestions | `zsh-autosuggestions` |
| Syntax highlighting | `zsh-syntax-highlighting` |

---

## Git Aliases

| Alias | Command |
|---|---|
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gc` | `git checkout` |
| `gnew` | `git checkout -b` |
| `gac 'msg'` | `git add . && git commit -m 'msg'` |

---

## Installed Tools

### Dev

![Go](https://img.shields.io/badge/Go-00ADD8?logo=go&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?logo=nodedotjs&logoColor=white)
![Python](https://img.shields.io/badge/pyenv-Python-3776AB?logo=python&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)
![Colima](https://img.shields.io/badge/Colima-container_runtime-blue)
![gh](https://img.shields.io/badge/GitHub_CLI-181717?logo=github&logoColor=white)
![GPG](https://img.shields.io/badge/GPG-0093DD?logo=gnuprivacyguard&logoColor=white)

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

### Apps

![VS Code](https://img.shields.io/badge/VS_Code-007ACC?logo=visualstudiocode&logoColor=white)
![Windsurf](https://img.shields.io/badge/Windsurf-AI_IDE-5C6BC0)
![Obsidian](https://img.shields.io/badge/Obsidian-7C3AED?logo=obsidian&logoColor=white)
![Brave](https://img.shields.io/badge/Brave-FB542B?logo=brave&logoColor=white)
![Discord](https://img.shields.io/badge/Discord-5865F2?logo=discord&logoColor=white)
![Spotify](https://img.shields.io/badge/Spotify-1DB954?logo=spotify&logoColor=white)
![UTM](https://img.shields.io/badge/UTM-VM_for_Mac-blue)
![Unity](https://img.shields.io/badge/Unity-000000?logo=unity&logoColor=white)
