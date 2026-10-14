---
title: Repository layout
description: Where each part of obsidian-plans lives, which environment variables the scripts read, and how scripts compare paths.
sidebar:
  order: 3
---

## Layout

- **`src/bin/`:** The scripts `plans-resolve`, `plans-worktree`, `plans-open`, and `plans-list`.
- **`src/plugin/`:** The Claude Code plugin that shows inbox items and plans to you.
- **`src/skills/`:** The skills `src/skills/obsidian-inbox/SKILL.md` and `src/skills/obsidian-plans/SKILL.md`.
- **`src/test/`:** The `bats` tests.
- **`site-docs/`:** The Astro Starlight site that holds this contract.
- **`src/install`:** The install script.
- **Repository root:** `mise.toml`, `README.md`, and `.gitignore` stay at the repository root.

## Scripts and tests

- All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Tests create temporary directories.
- Tests never touch the real `~/src`, `~/.config`, or any real vault.

## Environment variables

Scripts read these environment variables to allow testing.

- **`OBSIDIAN_PLANS_CONFIG_DIR`:** Overrides the config dir.
- **`GHQ_ROOT`:** Overrides the output of `ghq root`.
- **`OBSIDIAN_CONFIG_DIR`:** Overrides `~/.config/obsidian`.
  Only `plans-open` reads it.
- **`PLANS_OPEN_COMMAND`:** Overrides `xdg-open`.
  Only `plans-open` reads it.

## Path comparison

- A script compares paths by their real path, so symlinks do not break a comparison.
- This rule applies to the vault, the notes root, the worktrees root, and the vault paths in `obsidian.json`.
- Where a script prints a path, it prints the configured form of the path.
- `plans-open` builds its URL from the vault path that `obsidian.json` lists.
