# Claude Code setup — instructions for Claude

You are Claude Code running on one of the user's machines (macOS or Arch). Goal: reproduce the user's
3 Claude Code profiles from this repo. `~/.claude` is the default profile; `~/.claude-work` and
`~/.claude-korvy` (listed in `claude/profiles.txt`) share everything with it via symlinks and differ only
by account/billing (`.credentials.json`, `.claude.json`, Keychain entry).

Repo path: `~/Repos/cli-setup` (Arch and the main Mac; an older Mac may use `~/github.com/gabotachak/cli-setup`). Never push, merge or
change git config without the user's explicit permission. If anything you find does not match what is
described here, STOP and ask the user.

## What the setup step does (`mac/setup.sh 10`, `arch/setup.sh 9`)
- Symlinks `~/.claude/CLAUDE.md` to `claude/` in this repo (a differing real file is saved as `.bak`).
- Merges `claude/settings.json` into a real `~/.claude/settings.json` with `jq` (repo keys win, local-only keys stay). Not a symlink: an interactive session's `/model` replaces a symlinked settings.json with a real file.
- Installs the skills in `claude/skills.txt` into `~/.claude/skills` (`npx skills add -g -a claude-code --copy`) and patches ui-ux-pro-max (script paths, removes `scripts/tests`).
- For each profile: symlinks CLAUDE.md, settings.json, plugins, projects, history.jsonl, file-history, paste-cache, ponytail-* and every skill (except `synced`) to `~/.claude`. Real files/dirs in a profile are skipped with a warning, never deleted.
- Adds the `plane` MCP (`https://mcp.plane.so/http/mcp`, user scope) to each profile if missing.
- Never shared or touched: `.credentials.json`, `.claude.json`, `skills/synced`, backups, cache, sessions, session-env, shell-snapshots, state.

## Steps
1. `git -C <repo> pull`. Stay on the branch the user tells you (`git status` first).
2. Back up before linking (exclude the big shared dirs):
   `tar -C ~ --exclude=projects --exclude=file-history --exclude=paste-cache --exclude=plugins -czf ~/claude-backup-$(date +%F).tgz .claude .claude-work .claude-korvy`
   (skip dirs that do not exist). Tell the user where the tarball is.
3. Inspect what already exists in `~/.claude`, `~/.claude-work`, `~/.claude-korvy`: CLAUDE.md, settings.json, `skills/` (anything not in `skills.txt` and not `synced`), and memories (`projects/*/memory`).
   - If CLAUDE.md / settings.json differ from `claude/`, MERGE what is missing into the repo copy (ask about conflicts) instead of overwriting. Check the result has no absolute `/home/...` or `/Users/...` paths.
   - Skills present locally but not in `skills.txt`: ask the user whether to add them to the list.
   - Memories are NOT versioned and NOT copied from Linux (absolute paths, private data). Leave any that exist where they are.
   - A real (non-symlink) dir/file inside a profile where a symlink belongs: do not delete; ask.
4. Run the step: `bash mac/setup.sh 10` (macOS) or `bash arch/setup.sh 9` (Arch). Run it a second time: output must report no changes and `git status` must stay clean.
5. Verify: `~/.claude/CLAUDE.md` is a symlink into the repo and `~/.claude/settings.json` is a real file containing the repo keys; both profiles' links resolve (`ls -l ~/.claude-work ~/.claude-korvy`); `grep -c 'CLAUDE_PLUGIN_ROOT\|claude-work' ~/.claude/skills/ui-ux-pro-max/SKILL.md` is 0; `CLAUDE_CONFIG_DIR=~/.claude-work claude plugin list` and `... claude mcp list` work (same for korvy).
6. macOS only, Keychain: each `CLAUDE_CONFIG_DIR` must use its own Keychain entry. After the user has logged in to each profile, run `security dump-keychain 2>/dev/null | grep -i 'Claude Code-credentials'` (or `security find-generic-password -s "Claude Code-credentials"` and the suffixed variants) and confirm there are separate entries for the default, `~/.claude-work` and `~/.claude-korvy` profiles. If they share one entry, STOP and warn the user: logins overwrite each other and billing is no longer separated.
7. Tell the user to run, in each profile (`claude`, `claude-work`, `claude-korvy`): `/login` with that profile's account, then `/mcp` to authenticate `plane`.

## Migration note (2026-10-21): settings.json is no longer a symlink
Verified on macOS (Claude Code 2.1.306): running `/model` in an interactive session replaces a symlinked
`~/.claude/settings.json` with a real file, so the repo link broke silently. `claude plugin ...` (CLI) does
write through the symlink. The step now merges `claude/settings.json` into a real file with `jq` instead.
On a machine (e.g. the Arch PC) that ran the old step:
1. `git pull`, then `bash arch/setup.sh 9`. The step removes the old `~/.claude/settings.json` symlink and
   writes the merged real file. Check: `ls -l ~/.claude/settings.json` is NOT a link, `jq . ~/.claude/settings.json`
   contains the repo keys.
2. If the symlink had already been broken by `/model`, `~/.claude/settings.json` is a real file with local
   changes: the merge keeps them (repo keys win). Look for keys there that should go into the repo and ask the user.
3. If a profile (`~/.claude-work`, `~/.claude-korvy`) has a real `settings.json`, the step prints
   "is a real file/dir — skipped". Merge its keys into `~/.claude/settings.json` (ask about conflicts), delete it
   and run the step again so it becomes a symlink to `~/.claude/settings.json` (that link survives `/model`).
4. Leftover `~/.claude/settings.json.bak*` files from the old step: show them to the user before deleting.
5. `ponytail-statusline.sh` in each profile may be a dangling link (only exists if ponytail's statusline was
   installed). Harmless; do not "fix" it by creating the file.
