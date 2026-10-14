# obsidian-plans

Bash scripts and two Claude skills that keep per-repository plans and inbox items in an existing Obsidian vault.

## Contract first

`docs/design.md` is the single source of truth for behavior.
Edit the contract before you change a script or a skill.
Report a gap or a conflict in the contract instead of choosing a behavior silently.

## Workflow

- `main` is protected. Open a pull request from a branch.
- CI runs `mise run test` on each pull request. Run it locally first.
- Write the failing `bats` test first, then the fix.
- Pin tool versions in `mise.toml` and GitHub Actions to a commit SHA.

## Tests

- Tests are black-box. They call the scripts as commands.
- Each test builds a temporary vault, config, and ghq root, and sets `OBSIDIAN_PLANS_CONFIG_DIR`, `GHQ_ROOT`, and a temporary `HOME`.
- The real config at `~/.config/obsidian-plans` and the real vault stay out of every test.
- Running `plans-resolve` or `plans-open` by hand creates folders in the real vault. Do it only to verify real behavior.

## Scripts

- Scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Scripts only create and read notes. A note is removed by marking it with `marked-for-deletion`, never by deleting it.
- Scripts and skills run no git command in the vault, never commit there, and never push anywhere.
- Scripts call each other from their own directory, not from `PATH`.

## Skills

- Edit the skills with the `writing-for-agents` skill.
- `~/.claude/skills` symlinks to `src/skills`, so an edit is live in the next session.
- Skills use the words "inbox item" and "plan". The word "memory" belongs to Claude's built-in memory.
