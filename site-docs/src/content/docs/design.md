---
title: Design contract
---

This document is the shared contract for all scripts and skills.
If you find a conflict or a gap, stop and report it.
Do not invent behavior.

## Concepts

- **Checkout:** A repository that `ghq` cloned to `<ghq root>/<host>/<owner>/.../<repo>`.
- **Worktree:** A git worktree at `<ghq root>/worktrees/<host>/<owner>/.../<repo>/<branch-with-dashes>`.
- **Vault:** An existing Obsidian vault that you choose.
  The config file names it.
  The vault has an `.obsidian/` folder.
  The scripts never change anything in `.obsidian/`.
- **Notes root:** `<vault>/<subfolder>`.
  The config file names the subfolder.
  The default subfolder is `obsidian-plans`.
- **Notes folder:** `<notes root>/<host>/<owner>/.../<repo>`.
  Each repository has one notes folder.
- **Ghq root:** The output of `ghq root`.
- **Depth:** A repository path has at least two levels below the root, such as `<host>/<repo>`.
  There is no maximum.
  A shallower path fails with a message on stderr.
- **Submodules and bare repositories:** Neither is a checkout.
  `plans-resolve` fails with a message on stderr when you run it inside either one.
- **Marked for deletion:** A tool or an agent never deletes a note.
  It adds the front matter field `marked-for-deletion: <ISO 8601 date>` to the note.
  A note with this field is gone, but not yet deleted.
  Every search for inbox items or plans skips these notes.
  The agent restores a note only when you ask.
  You can also restore a note by hand.
  Restoring means removing the field.
  You delete the marked notes yourself.
  The README documents one command for it.
- **Version control:** The tools never run git commands in the vault.
  The tools never commit, stage, or push.
  You version the vault, or you do not.

## Config file

The path is `<config dir>/config`.
The config dir is `$OBSIDIAN_PLANS_CONFIG_DIR`, or `${XDG_CONFIG_HOME:-$HOME/.config}/obsidian-plans`.

The file has plain `key=value` lines.
Scripts parse the lines and never `source` the file.
Blank lines and lines that start with `#` are ignored.
Spaces around the key and the value are trimmed.
A leading `~` in a value expands to `$HOME`.
One matching pair of single or double quotes around a value is removed before `~` expands.
A byte-order mark at the start of the file is ignored.
If `HOME` is unset and no config dir override is set, the script fails with the same kind of message.

- `vault`: required. The absolute path of an existing vault. A relative path fails.
- `subfolder`: optional. The default is `obsidian-plans`.
  The value is a single folder name with no `/`.
  The value is not `.` or `..`.

Every script that needs the config fails with a message on stderr and a non-zero exit in these cases.
The message tells you to run `install --vault <dir>`.

- The config file is missing.
- `vault` is missing.
- `vault` is not an existing directory.
- `vault` has no `.obsidian/` folder.
- `subfolder` is empty or contains `/`.

## Repository layout

- `src/bin/`: the scripts `plans-resolve`, `plans-worktree`, `plans-open`, and `plans-list`.
- `src/plugin/`: the Claude Code plugin that shows inbox items and plans to you.
- `src/skills/obsidian-inbox/SKILL.md` and `src/skills/obsidian-plans/SKILL.md`.
- `src/test/`: the `bats` tests.
- `site-docs/`: the Astro Starlight site that holds this contract.
- `src/install`: the install script.
- `mise.toml`, `README.md`, and `.gitignore` stay at the repository root.

All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
Tests create temporary directories and never touch the real `~/src`, `~/.config`, or any real vault.
Scripts read these environment variables to allow testing:

- `OBSIDIAN_PLANS_CONFIG_DIR`: overrides the config dir.
- `GHQ_ROOT`: overrides the output of `ghq root`.
- `OBSIDIAN_CONFIG_DIR`: overrides `~/.config/obsidian`. Only `plans-open` reads it.
- `PLANS_OPEN_COMMAND`: overrides `xdg-open`. Only `plans-open` reads it.

A script compares paths by their real path, so symlinks do not break a comparison.
This applies to the vault, the notes root, the worktrees root, and the vault paths in `obsidian.json`.
A script prints the configured form of a path where it prints a path.
`plans-open` builds its URL from the vault path that `obsidian.json` lists.

## Notes folder contents

- `.plans-vault`: an empty marker file.
  It lets a script walk up from a path inside the notes folder.
- `index.md`: a short landing note.
  `plans-resolve` creates it if missing and never overwrites it.
- `inbox/`: inbox items.
- `plans/`: plans.

The index note has a heading with the repository path.
It has two short sentences that say where inbox items and plans live.

## plans-resolve

Usage: `plans-resolve [--no-create]`.
Run from a checkout, a worktree, or a directory inside a notes folder.

Output on stdout, one `key=value` per line:

- `repo=<path>`: the checkout path.
- `vault=<path>`: the vault path.
- `notes=<path>`: the notes folder path.
- `worktree=<path>`: the worktree path. Printed only when you run it from a worktree.

Behavior:

1. Read and validate the config file.
2. From a checkout or a worktree, find the main checkout with `git rev-parse --git-common-dir`.
   Compute the relative path below the ghq root.
3. From inside a notes folder, walk up from the current directory to the nearest `.plans-vault`.
   The notes folder path relative to the notes root gives the relative repository path.
   If there is no marker, fail with a clear message on stderr and a non-zero exit.
4. Print `repo=`, `vault=`, and `notes=` always.
   If the checkout does not exist, print the expected path and a warning on stderr.
   Exit 0.
5. Create the notes folder, `.plans-vault`, `inbox/`, `plans/`, and `index.md` if missing.
   With `--no-create`, create nothing.
   The output stays the same.
6. Never create the vault.
   Never write inside `.obsidian/`.
   Never run any git command in the vault.
7. If the path is outside the ghq root, the worktrees root, and the notes root, fail with a message on stderr and a non-zero exit.
   A path inside the vault but outside the notes root also fails.

Calling it twice gives the same result.

## plans-worktree

Usage: `plans-worktree <branch> [<start-point>]` and `plans-worktree --remove <branch>`.

1. Resolve the main checkout.
   Fail if you run it outside the ghq root.
   Fail if you run it from inside the notes root.
2. Replace `/` in the branch name with `-` to get the directory name.
3. Create `<ghq root>/worktrees/<host>/<owner>/.../<repo>/<directory>`.
4. If the branch exists, check it out.
   If the branch exists only on `origin`, create a local branch at the remote head that tracks it.
   Otherwise, create the branch from the start point, with no upstream.
   The default start point is `origin/HEAD`.
   The first fallback is a local `main`.
   The last fallback is the `HEAD` of the main checkout.
   If git fails, leave no new directory behind.
5. Fail if another branch already maps to the same directory name.
6. Print only the worktree path on stdout.
7. With `--remove`, run `git worktree remove`.
   If a plan with `branch: <branch>` exists in the notes folder, print a warning on stderr.
   Skip a plan that has `marked-for-deletion`.
   Never delete the plan or the notes folder.

## plans-list

Usage: `plans-list`.
Run it from a checkout, a worktree, or a directory inside a notes folder.

1. Resolve the notes folder with `plans-resolve --no-create`.
   If it fails, `plans-list` fails with the same message on stderr and a non-zero exit.
2. Create nothing and write nothing.
   If the notes folder, `inbox/`, or `plans/` is missing, that part has no entries.
   Exit 0.
3. An open note is a file `*.md` directly in `inbox/` or `plans/`.
   Its front matter has no `marked-for-deletion` field.
   Front matter is the block between a first line `---` and the next line `---`.
   A file without front matter is open.
   A file that has a first line `---` and no closing `---` has no front matter.
4. Print to stdout, one entry per line, with tab characters between the fields.
   Print the inbox entries first and then the plan entries.
   Sort each group by file name.
   - `inbox<TAB><name>`: `<name>` is the file name without `.md`.
   - `plan<TAB><name><TAB><branch>`: `<branch>` is the value of the exact front matter line `branch: <branch>`, trimmed.
     It is empty if the plan has no such line.
5. Print nothing if there are no open notes.
6. Never run a git command.
   Never change anything in the vault.

Calling it twice gives the same result.

## plans-open

Usage: `plans-open`.
Run it from a checkout, a worktree, or a directory inside a notes folder.

1. Check that the opener exists.
   The opener is `${PLANS_OPEN_COMMAND:-xdg-open}`.
   Check that `jq` exists.
   Fail with a message on stderr if either is missing.
2. Resolve the notes folder with `plans-resolve`.
3. Read `${OBSIDIAN_CONFIG_DIR:-$HOME/.config/obsidian}/obsidian.json`.
   Check that a vault entry has a `path` equal to the vault path.
   If the file is missing or has no matching entry, fail with this message on stderr:
   "Open the vault once in Obsidian, then run plans-open again."
4. Run the opener with `obsidian://open?path=<url-encoded absolute path of index.md>`.
   Percent-encode every byte outside `A-Za-z0-9._~-`.
5. Print nothing on stdout.
6. Never write to `obsidian.json`.
   Never read or write any other Obsidian file.

## install

Usage: `install [--vault <dir> [--subfolder <name>]]`.

1. If you pass `--vault`, validate it as the config rules say.
   Trim spaces around the value first.
   Then write the config file, and replace an existing one.
   This is how you repair a broken config.
   If you do not pass `--vault` and a config file exists, keep it and report that.
   If you do not pass `--vault` and no config file exists, fail.
   If you pass `--subfolder` without `--vault`, fail.
   Passing `--vault` without `--subfolder` writes the default subfolder.
   A failed validation leaves an existing config unchanged.
   `install` also needs `HOME`, so it fails when `HOME` is unset.
2. Symlink each file in `src/bin/` into `~/.local/bin`.
3. Symlink each directory in `src/skills/` into `~/.claude/skills`.
4. Never overwrite an existing file that is not a symlink.
   Report it and continue.
5. Never run a git command.
   Never create or change anything in the vault.
6. Calling it twice gives the same result.

## Plugin

The plugin lives in `src/plugin/`.
It is a Claude Code plugin with a mod.
A mod is code that runs inside Claude Code and draws in its interface.
The plugin shows you the open inbox items and plans.
Nothing that it shows enters the model context.

- The plugin never returns text from a command.
  Claude reads a command's text, so the plugin returns an empty result.
- The plugin calls `plans-list` by name, in the working directory of the session.
- The plugin writes no note, runs no git command, and changes nothing in the vault.
- At session start, the plugin runs `plans-list`.
  If it exits 0 and prints at least one line, the plugin shows one toast: `inbox <n> · plans <m>`.
  If it fails or prints nothing, the plugin shows nothing.
- The plugin adds the command `/plans`.
  The command runs `plans-list` and opens a pane with the id `plans` and the title `Plans`.
  Esc closes the pane.
  - The pane has the heading `Inbox (<n>)`, then one row per inbox item with its name.
  - The pane has the heading `Plans (<m>)`, then one row per plan.
    A row is the name, followed by `[<branch>]` if the plan has a branch.
  - A group with no entries shows the row `None.`.
  - If `plans-list` fails, the pane shows its stderr message.
  - If `plans-list` is not found, the pane tells you to run `src/install --vault <dir>` in the obsidian-plans repository.
- The plugin needs Claude Code 2.1.287 or later.
  It draws in the terminal and in the Desktop app.
  Elsewhere, it draws nothing.
- You load the plugin with `claude --plugin-dir <path to src/plugin>`, or install it from a marketplace.
  `install` does not load the plugin.
- The `bats` tests do not cover the plugin.
  `claude plugin test` runs its tests.

## Notes that the user edits

The user edits inbox items and plans by hand.
The user's version of a note is correct.

- Agents keep every unknown front matter field.
- Agents keep every unknown section.
- Agents keep the user's formatting and wording.
- Agents change only the lines that the task needs.
- Agents never rewrite or reformat a whole note.
- Scripts and skills read only the fields that this document names.
  Any other field is safe.
- A plan is found by the exact front matter line `branch: <branch>`.
  Another form of that line hides the plan from recall.
  Another form also hides the plan from the `plans-worktree --remove` warning.
- The scripts read `marked-for-deletion` only in the front matter.
  The skills match the field at the start of any line.
  A body line that starts with `marked-for-deletion:` hides the note from agents.
  This difference is known and accepted.

## Inbox item

An inbox item is a deferred discovery that is not ready to plan.
It is not a fact, and it is not a user preference.

- **File:** `<notes>/inbox/YYYY-MM-DD-<slug>.md`.
- **Front matter:**
  - `created`: the ISO 8601 date.
  - `branch`: the branch where the agent found it. Omit it on a detached `HEAD`.
  - `source`: `user` or `agent`.
  - `affects`: `<host>/<owner>/.../<repo>`. Only when the item belongs to another repository.
- **Body:** three short parts: what was found, why it matters, and where to look.
- **Lifecycle:** an item in `inbox/` without `marked-for-deletion` is open.
  Promoting or dropping an item adds `marked-for-deletion` to the file.
  The agent never deletes the file.
- **Front matter, optional:** `marked-for-deletion`: the ISO 8601 date of the removal.
- **Code references:** avoid them.
  If needed, use a repository-relative path plus a short SHA, and quote at most a few lines.

Agent rules:

1. Agents never write an item silently.
2. Before the agent offers, it runs `rg` over `inbox/` for the topic.
   The search skips files with `marked-for-deletion`.
3. The agent offers in one line: "Add to the inbox?"
   If `rg` found matches, it shows at most 2 and lets you choose to append or create.
4. The agent writes only after you accept.
5. If you ask directly ("put this in the inbox"), the agent skips the offer.
   It still runs the duplicate search.
6. Recall is on demand only. The agent reads `inbox/` in two cases.
   You ask what is deferred, or you start planning in an area where an open item matches by `rg`.
   Both reads skip files with `marked-for-deletion`.
   The agent never loads every item at session start.

## Plan

- **File:** `<notes>/plans/YYYY-MM-DD-<slug>.md`.
- **Front matter:**
  - `branch`: the worktree branch.
  - `created`: the ISO 8601 date.
  - `promoted-from`: the inbox item file name without `.md`, as plain text.
    Only when it applies.
  - `marked-for-deletion`: the ISO 8601 date of the removal. Optional.
- **No status field.**
  The only state is the optional `marked-for-deletion` field.
- **Body sections:** Goal, Context, Steps (checkboxes), Decisions, and Log.
  The Log has dated entries that you and the agent append to.
- You and the agent both edit a plan.
- **Recall:** When an agent starts in a worktree, it looks for a plan with a matching `branch`.
  The lookup skips plans with `marked-for-deletion`.
  If it finds one, it offers in one line to load it.
  It never loads the plan without your answer.
- **Creation outside a worktree:** If you start a plan in the main checkout, the agent offers in one line to create a worktree.
  If you decline, the plan records the current branch.
- **Promotion:** Promoting an inbox item adds `marked-for-deletion` to the item.
  The plan records `promoted-from`.
  Planning may create new inbox items. The agent asks you first.
- **Removal:** The agent asks before it removes a finished plan.
  Removal adds `marked-for-deletion` to the plan.
  The agent never deletes the file.

## Skill rules

- The skills are named `obsidian-inbox` and `obsidian-plans`.
- The skills call the scripts by name, such as `plans-resolve`.
  They read `notes=` from the output and never use `vault=`.
- The skills never run a git command in the vault.
  They never commit.
- The skills never run `rm` or any other command that deletes a note.
  They only add or remove the `marked-for-deletion` field.
- To find notes without the field, the skills use `rg --files-without-match '^marked-for-deletion:'`.
- If a script is missing, the skill tells you to run `install`.
- The word "memory" does not appear in the skills.
  Claude has a built-in memory, and the vault is a separate concept.
- Write the skills with the `writing-for-agents` skill.
