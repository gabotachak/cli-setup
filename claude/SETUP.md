# Claude Code setup — instructions for Claude

You are Claude Code running on one of the user's machines (macOS or Arch). Goal: reproduce the user's
3 Claude Code profiles from this repo. `~/.claude` is the default profile; `~/.claude-work` and
`~/.claude-korvy` (listed in `claude/profiles.txt`) share everything with it via symlinks and differ only
by account/billing (`.credentials.json`, `.claude.json`, Keychain entry).

Repo path: macOS `~/github.com/gabotachak/cli-setup`, Arch `~/Repos/cli-setup`. Never push, merge or
change git config without the user's explicit permission. If anything you find does not match what is
described here, STOP and ask the user.

## What the setup step does (`mac/setup.sh 10`, `arch/setup.sh 9`)
- Symlinks `~/.claude/CLAUDE.md` and `settings.json` to `claude/` in this repo (a differing real file is saved as `.bak`).
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
5. Verify: `~/.claude/CLAUDE.md` and `settings.json` are symlinks into the repo; both profiles' links resolve (`ls -l ~/.claude-work ~/.claude-korvy`); `grep -c 'CLAUDE_PLUGIN_ROOT\|claude-work' ~/.claude/skills/ui-ux-pro-max/SKILL.md` is 0; `CLAUDE_CONFIG_DIR=~/.claude-work claude plugin list` and `... claude mcp list` work (same for korvy).
6. macOS only, Keychain: each `CLAUDE_CONFIG_DIR` must use its own Keychain entry. After the user has logged in to each profile, run `security dump-keychain 2>/dev/null | grep -i 'Claude Code-credentials'` (or `security find-generic-password -s "Claude Code-credentials"` and the suffixed variants) and confirm there are separate entries for the default, `~/.claude-work` and `~/.claude-korvy` profiles. If they share one entry, STOP and warn the user: logins overwrite each other and billing is no longer separated.
7. Tell the user to run, in each profile (`claude`, `claude-work`, `claude-korvy`): `/login` with that profile's account, then `/mcp` to authenticate `plane`.
