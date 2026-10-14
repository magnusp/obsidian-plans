# obsidian-plans

Tools and Claude skills that store plans and deferred discoveries in an Obsidian vault.
The tools use one folder per repository inside a vault that you already have.
The folder layout mirrors the layout that `ghq` uses for checkouts.

## How it works

- **Checkout:** `<ghq root>/<host>/<owner>/.../<repo>`.
- **Worktree:** `<ghq root>/worktrees/<host>/<owner>/.../<repo>/<branch-with-dashes>`.
- **Notes folder:** `<vault>/<subfolder>/<host>/<owner>/.../<repo>`.

You choose the vault and the subfolder.
The default subfolder is `obsidian-plans`.
A config file stores both.
The file is `~/.config/obsidian-plans/config`, or `$XDG_CONFIG_HOME/obsidian-plans/config` if you set that variable.

Each notes folder has these items:

- **`inbox/`:** Deferred discoveries that are not ready to plan.
- **`plans/`:** Plans that live while the work is in progress.
- **`index.md`:** A landing note for the repository.
- **`.plans-vault`:** An empty marker file for the scripts.

The tools never run git commands in your vault.
The tools never commit or push.
You version the vault yourself, or you do not.
The tools never change anything in the `.obsidian/` folder of your vault.

For the full contract, read [the design contract](docs/design.md).

## Install

1. Run `mise install` to get `bats`.
2. Run `src/install --vault <path to your vault>`.

Use `--subfolder <name>` to change the subfolder.
The install script writes the config file when you pass `--vault`.
To change the vault, run the install script again with a new `--vault`.
The script then symlinks the scripts into `~/.local/bin`.
The script also symlinks the skills into `~/.claude/skills`.
The script never overwrites an existing file that is not a symlink.
You can run the script again at any time.

## Scripts

- **`plans-resolve`:** Prints `repo=`, `vault=`, and `notes=`, and `worktree=` in a worktree.
  It creates the notes folder if the folder is missing.
  Run it from a checkout, a worktree, or a directory inside a notes folder.
- **`plans-worktree <branch> [<start-point>]`:** Creates a worktree and prints its path.
  Use `--remove <branch>` to remove a worktree.
  The script keeps the notes folder and any plan.
- **`plans-open`:** Opens the `index.md` of the current repository in Obsidian.
  If Obsidian does not know the vault, open the vault once in Obsidian.
  Then run the script again.

## Skills

- **`obsidian-inbox`:** The agent suggests an inbox item.
  You accept it before the agent writes it.
  The agent searches for duplicates first.
- **`obsidian-plans`:** The agent saves a plan, loads a plan for the current branch, and removes a finished plan.
  The agent asks you before each of these actions.

## Delete notes that agents removed

An agent never deletes a note.
The agent adds `marked-for-deletion: <date>` to the front matter of the note.
Agents and scripts then treat the note as gone.
To restore a note, ask the agent, or remove the field yourself.

To list the marked notes, run this command.
Replace the path with your notes root, which is `<vault>/<subfolder>`.

```bash
rg --files-with-matches --glob '*.md' '^marked-for-deletion:' ~/Documents/obsidian/Fortnox/obsidian-plans
```

To delete the marked notes, run the same command with the output piped to `rm`.
Check the list first, because the deletion is permanent.

```bash
rg --files-with-matches --null --glob '*.md' '^marked-for-deletion:' ~/Documents/obsidian/Fortnox/obsidian-plans | xargs -0 rm
```

## Test

Run `mise run test`.
The tests use temporary directories.
They never touch your real `~/src`, `~/.config`, or vault.
