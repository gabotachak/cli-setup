# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal shell configuration + CLI-toolchain bootstrap ("dotfiles" repo) for macOS and Arch Linux (CachyOS). No build system, no tests, no package.json — just shell config files and bash setup scripts that get symlinked/run on a fresh machine.

**CLI only.** GUI apps, fonts and gaming packages do NOT belong here — on Arch they live in the `hyprland-config` repo's `system/packages.txt` (a full `pacman -Qqe` machine dump). `arch/pacman.txt` and `arch/aur.txt` carry only command-line tools and build deps. On macOS there's no machine-dump repo, so GUI apps stay in this repo but split out: `mac/Brewfile` = CLI formulae, `mac/Caskfile` = GUI casks (skipped when `CLI_ONLY=1`).

## Structure

```
cli-setup/
├── zsh/
│   ├── .zshrc       # Zsh config (plain, no framework) — macOS fallback shell
│   └── .zprofile    # Homebrew PATH
├── fish/
│   ├── config.fish           # Fish config (Tide prompt) — macOS primary shell
│   └── functions/             # One function per file (fish convention) — shared by mac AND arch
├── mac/
│   ├── Brewfile     # CLI brew formulae
│   ├── Caskfile     # GUI casks (skipped when CLI_ONLY=1)
│   ├── setup.sh     # One-step bootstrap (menu-driven, steps 1-9)
│   └── setup-keys.sh # SSH commit-signing setup (assumes `gh auth login` already ran)
└── arch/
    ├── pacman.txt    # Official Arch/CachyOS repo packages
    ├── aur.txt       # AUR packages (installed via `shelly install aur`)
    ├── fish/config.fish  # Fish config — Arch equivalent of ../fish/config.fish
    ├── setup.sh      # One-step bootstrap (menu-driven, steps 1-8)
    └── setup-keys.sh # SSH commit-signing setup (Arch, assumes `gh auth login` already ran)
```

`fish/functions/` is OS-agnostic and shared — both `mac/setup.sh` and `arch/setup.sh` symlink the same directory. Only `config.fish` differs per OS (Homebrew paths on mac vs. CachyOS theming/pacman paths on Arch), which is why Arch gets its own `arch/fish/config.fish` instead of reusing `fish/config.fish`.

## Running / testing changes

There's no test suite. "Testing" a change means running the relevant script or sourcing the config on the target OS:

```bash
bash mac/setup.sh          # macOS interactive menu
bash mac/setup.sh all      # run all mac bootstrap steps
bash mac/setup.sh <1-9>    # run a single mac step (see show_menu in mac/setup.sh)
bash mac/setup-keys.sh     # macOS SSH commit signing (run `gh auth login` first), signs commits/tags globally

bash arch/setup.sh        # Arch interactive menu
bash arch/setup.sh all    # run all arch bootstrap steps
bash arch/setup.sh <1-8>  # run a single arch step (see show_menu in arch/setup.sh)
bash arch/setup-keys.sh   # Arch SSH commit signing (run `gh auth login` first), signs commits/tags globally
```

`mac/*.sh` use `set -euo pipefail` — a broken step aborts the whole run. `arch/setup.sh` intentionally drops `-e`; `pacman.txt` installs as one batch (`pacman -Syu`), but `aur.txt` goes through `install_list` one package at a time (`shelly install aur`) so one wrong/renamed AUR package doesn't abort the rest — failures are reported at the end. Both need an interactive terminal (`sudo` / AUR build prompts), so they're meant to be run directly by a user, not piped or run non-interactively.

## Architecture notes

- **Fish is primary, zsh is fallback.** Aliases/functions are duplicated across both (e.g. `gp`, `gpl`, `gc`, `gnew`, `gac`) — when adding a git shortcut, add it to both `fish/config.fish`/`fish/functions/` and `zsh/.zshrc` unless it's fish-only.
- **Fish functions are one-per-file** under `fish/functions/`, named after the function. Files prefixed with `_` (e.g. `_gc.fish`, `_bl.fish`) are internal helpers composed by other functions — e.g. `_bl` (branch + push new) and `_br` (checkout + merge existing) both call `_gc` and `_get_primary_branch`. `_get_primary_branch` resolves the default branch (main/master) via `git symbolic-ref` on each call — no cache, since it's a local file read and a cache not keyed per repo returns the wrong branch after `cd`.
- **`setup.sh` step order matters**: Xcode CLT → Homebrew → Brewfile bundle → add Fish to `/etc/shells` → Fisher + Tide install → symlink Fish config → set Fish as default shell → install Claude Code CLI → install Claude Code plugins (caveman, ponytail, omniroute, graphify, agent-skills, find-skills). `step_symlink` symlinks (not copies) `fish/config.fish` and every file in `fish/functions/` into `~/.config/fish/`, so edits to files in this repo take effect immediately on a machine that already ran setup.
- **`setup-keys.sh`** is separate from `setup.sh` (not run by `all`) and assumes `gh auth login` (git protocol: ssh) already ran — that generates `~/.ssh/id_ed25519` and registers it with GitHub as an Authentication key. `setup-keys.sh` only wires that same key up for commit signing (no GPG): `git config --global gpg.format ssh` + `user.signingkey <key>.pub` + `commit.gpgsign true` / `tag.gpgsign true` + `~/.config/git/allowed_signers`, then registers the key with GitHub as a Signing key via `gh ssh-key add --type signing` (refreshing the `admin:ssh_signing_key` scope first if needed) — no manual paste. This matches the SSH-signing setup in the `hyprland-config` repo; keep them consistent.
- **Package lists are grouped by purpose** — keep new entries under the matching group rather than appending to the end.
  - `arch/pacman.txt` / `arch/aur.txt`: **CLI only** (Dev tools / Containers / AI-ML / Shell-CLI / build deps). A GUI app request goes to the `hyprland-config` repo, not here.
  - `mac/Brewfile`: `brew` formulae only, grouped like the arch lists.
  - `mac/Caskfile`: GUI `cask` apps, grouped Browsers/Editors/Dev tools/Productivity/Communication/Media/Utilities/Fonts. macOS-only (no macOS machine-dump repo). `step_bundle` installs it after `Brewfile` unless `CLI_ONLY=1`.

## Conventions to follow when editing

- Bootstrap scripts (`mac/*.sh`) use `set -euo pipefail` and the `info`/`success`/`warn`/`step` echo helpers for output — reuse them rather than raw `echo` for new steps.
- Fish functions use `❌`/`✅`/`📍`/🚀 emoji-prefixed echo for status/error messages — match this style for consistency (README's alias table and this pattern are the closest thing to a style guide in this repo).
- README.md's "Structure", "Shell Features", "Git Aliases", and "Installed Tools" tables are the source of truth for what's installed/aliased — update them when adding packages, aliases, or fish functions so the repo stays self-documenting.
