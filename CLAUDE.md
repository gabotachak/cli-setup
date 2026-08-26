# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal shell configuration + one-step bootstrap ("dotfiles" repo) for macOS and Arch Linux (CachyOS). No build system, no tests, no package.json — just shell config files and bash setup scripts that get symlinked/run on a fresh machine.

## Structure

```
cli-setup/
├── zsh/
│   ├── .zshrc       # Zsh config (Oh My Zsh + Powerlevel10k) — macOS fallback shell
│   └── .zprofile    # Homebrew + JetBrains Toolbox PATH
├── fish/
│   ├── config.fish           # Fish config (Tide prompt) — macOS primary shell
│   └── functions/             # One function per file (fish convention) — shared by mac AND arch
├── mac/
│   ├── Brewfile     # All brew formulae + casks
│   ├── setup.sh     # One-step bootstrap (menu-driven, steps 1-7)
│   └── setup-keys.sh # Interactive SSH + GPG key setup for GitHub
└── arch/
    ├── pacman.txt    # Official Arch/CachyOS repo packages
    ├── aur.txt       # AUR packages (installed via paru)
    ├── fish/config.fish  # Fish config — Arch equivalent of ../fish/config.fish
    ├── setup.sh      # One-step bootstrap (menu-driven, steps 1-8)
    └── setup-keys.sh # Interactive SSH + GPG key setup for GitHub (Arch variant)
```

`fish/functions/` is OS-agnostic and shared — both `mac/setup.sh` and `arch/setup.sh` symlink the same directory. Only `config.fish` differs per OS (Homebrew/JetBrains paths on mac vs. CachyOS theming/pacman paths on Arch), which is why Arch gets its own `arch/fish/config.fish` instead of reusing `fish/config.fish`.

## Running / testing changes

There's no test suite. "Testing" a change means running the relevant script or sourcing the config on the target OS:

```bash
bash mac/setup.sh          # macOS interactive menu
bash mac/setup.sh all      # run all mac bootstrap steps
bash mac/setup.sh <1-7>    # run a single mac step (see show_menu in mac/setup.sh)
bash mac/setup-keys.sh     # macOS SSH + GPG key generation, signs commits/tags globally

bash arch/setup.sh        # Arch interactive menu
bash arch/setup.sh all    # run all arch bootstrap steps
bash arch/setup.sh <1-8>  # run a single arch step (see show_menu in arch/setup.sh)
bash arch/setup-keys.sh   # Arch SSH + GPG key generation, signs commits/tags globally
```

`mac/*.sh` use `set -euo pipefail` — a broken step aborts the whole run. `arch/setup.sh` intentionally drops `-e` and installs AUR/pacman packages one-at-a-time (see `install_list`) so one wrong/renamed package doesn't abort the whole bundle — it reports failures at the end instead. Both need an interactive terminal (`sudo` / AUR build prompts), so they're meant to be run directly by a user, not piped or run non-interactively.

## Architecture notes

- **Fish is primary, zsh is fallback.** Aliases/functions are duplicated across both (e.g. `gp`, `gpl`, `gc`, `gnew`, `gac`) — when adding a git shortcut, add it to both `fish/config.fish`/`fish/functions/` and `zsh/.zshrc` unless it's fish-only.
- **Fish functions are one-per-file** under `fish/functions/`, named after the function. Files prefixed with `_` (e.g. `_gc.fish`, `_bl.fish`) are internal helpers composed by other functions — e.g. `_bl` (branch + push new) and `_br` (checkout + merge existing) both call `_gc` and `_get_primary_branch`. `_get_primary_branch` caches the resolved default branch (main/master) for 60s in global fish variables to avoid repeated `git symbolic-ref` calls.
- **`setup.sh` step order matters**: Xcode CLT → Homebrew → Brewfile bundle → add Fish to `/etc/shells` → Fisher + Tide install → symlink Fish config → set Fish as default shell. `step_symlink` symlinks (not copies) `fish/config.fish` and every file in `fish/functions/` into `~/.config/fish/`, so edits to files in this repo take effect immediately on a machine that already ran setup.
- **`setup-keys.sh`** is separate from `setup.sh` (not run by `all`) — it's an interactive, one-key-at-a-time flow (SSH key → GitHub SSH settings in browser → confirm → GPG key → GitHub GPG settings in browser → confirm) that also sets `git config --global commit.gpgsign true` / `tag.gpgsign true`, so every commit made after running it will be GPG-signed.
- **Brewfile / pacman.txt / aur.txt are grouped by purpose** (Dev tools / Containers / AI-ML / Media / Shell-CLI / Misc / Apps, apps further grouped by Browsers/Editors/Dev tools/Productivity/Communication/Media/Utilities/Game dev/Fonts) — keep new entries under the matching group rather than appending to the end. When adding an app, add it to the Brewfile group AND the pacman.txt/aur.txt equivalent group so the two package managers stay in sync; some macOS casks have no Arch port (orion, utm, betterdisplay, applite, iterm2, colima, pinentry-mac) — those are listed as a skipped comment block at the bottom of `aur.txt` rather than silently omitted.

## Conventions to follow when editing

- Bootstrap scripts (`mac/*.sh`) use `set -euo pipefail` and the `info`/`success`/`warn`/`step` echo helpers for output — reuse them rather than raw `echo` for new steps.
- Fish functions use `❌`/`✅`/`📍`/🚀 emoji-prefixed echo for status/error messages — match this style for consistency (README's alias table and this pattern are the closest thing to a style guide in this repo).
- README.md's "Structure", "Shell Features", "Git Aliases", and "Installed Tools" tables are the source of truth for what's installed/aliased — update them when adding packages, aliases, or fish functions so the repo stays self-documenting.
