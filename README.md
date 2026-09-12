# cli-setup

> Personal macOS shell configuration and one-step bootstrap.

![macOS](https://img.shields.io/badge/macOS-Tahoe-000000?logo=apple&logoColor=white)
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
│   ├── config.fish           # Fish config (Tide prompt)
│   └── functions/
│       └── gac.fish          # git add . && git commit -m
├── git/
│   └── .gitconfig   # user, GPG signing, LFS filter
├── ssh/
│   └── config       # Host aliases (no keys — generate those separately)
├── ghostty/
│   └── config       # Font + theme
├── vscode/
│   ├── settings.json
│   └── extensions.txt
└── mac/
    ├── Brewfile     # All formulae + casks
    └── setup.sh     # One-step bootstrap script
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

## SSH + GPG Setup

Interactive assistant — you only need to paste the generated keys into GitHub.

```bash
bash ~/github.com/gabotachak/cli-setup/mac/setup-keys.sh
```

The script will:
1. Generate an **Ed25519 SSH key** (if none exists)
2. Configure `~/.ssh/config` for macOS Keychain
3. Open GitHub SSH settings → you paste the key
4. Test the SSH connection
5. Generate a **GPG key** (Ed25519, via macOS passphrase dialog)
6. Configure git to auto-sign all commits + tags
7. Open GitHub GPG settings → you paste the key

> Requires `gnupg` and `pinentry-mac` (included in Brewfile).

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
