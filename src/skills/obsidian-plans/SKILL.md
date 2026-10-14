---
name: obsidian-plans
description: Writes and recalls plans for the current repository in the Obsidian vault. Use when you start work in a git worktree, when the user starts planning, when the user promotes an inbox item to a plan, when you edit a plan, or when a plan is finished.
---

# Obsidian plans

A plan belongs to one branch.
The user and you both edit a plan.

## Scripts

- Run `plans-resolve` from the current directory.
  Read the notes folder path from the `notes=` line.
  Use only the `notes=` line.
  The output has a `worktree=` line only in a worktree.
- If the shell reports that `plans-resolve` or `plans-worktree` is not found, tell the user to run `src/install --vault <dir>` in the obsidian-plans repository.
  Then stop.
- If `plans-resolve` fails, show its stderr message to the user.
  If the message is about the config, tell the user to run `src/install --vault <dir>` in the obsidian-plans repository.
  Then stop.

## Files

- Write files only in `<notes>/plans/` and `<notes>/inbox/`.
- Use plain file operations only.
  The user handles version control of the vault.
- Put each path in double quotes, such as `"<notes>/plans/"`.

## The user's edits

The user edits notes by hand.
Treat the user's version of a note as correct.

- Keep every front matter field that you do not know.
- Keep every section that you do not know.
- Keep the user's formatting and wording.
- Change only the lines that your task needs.
- Never rewrite or reformat a whole note.
- If the plan has no Log section, ask the user before you add one.
- If you cannot tell where an entry belongs, ask the user.

Plan recall finds a plan by the exact line `branch: <branch>`.
If the user writes the branch in another form, recall does not find the plan.
Any other field the user adds is safe.

## Marked notes

A note is a plan or an inbox item.
You never delete a note.
To remove a note, you mark it.
The user deletes marked notes.

- **Mark:** add `marked-for-deletion: <YYYY-MM-DD>` as the last line of the note's front matter.
  Use `date +%F` for the date.
  If the file has no front matter, add a front matter block at the top with only this field.
  Change nothing else in the file.
- **Marked note:** a note with the `marked-for-deletion` field is gone.
  Treat it as if it does not exist.
- **Restore:** restore a marked note only when the user asks.
  To restore, remove the `marked-for-deletion` line.
  Change nothing else in the file.

## Search open notes

Every search and every listing of notes skips marked notes.
Use these two commands.

- **Find open plans for a branch:**

  ```bash
  rg --no-ignore --files-without-match --null '^marked-for-deletion:' "<notes>/plans/" | xargs -0 -r rg --no-ignore -l -F -x 'branch: <branch>'
  ```

- **Find open notes that match a keyword:**

  ```bash
  rg --no-ignore --files-without-match --null '^marked-for-deletion:' "<notes>/<folder>/" | xargs -0 -r rg --no-ignore -l -i '<keyword>'
  ```

  Replace `<folder>` with `plans` or `inbox`.

If the output is empty, there are no matches.
The exit code is then 123.

## Recall in a worktree

1. Run `plans-resolve`.
2. If the output has no `worktree=` line, stop.
3. Run `git branch --show-current` in the worktree to get the branch.
4. Find open plans for the branch.
5. If there is a match, offer in one line: "Load the plan `<file>`?"
6. Read the plan only after the user says yes.

## Create a plan

1. Run `plans-resolve`.
2. If the output has no `worktree=` line, offer in one line: "Create a worktree for this plan with `plans-worktree`?"
   If the user says yes, run `plans-worktree <branch>` and work in the path it prints.
   If the user says no, use the current branch.
3. Find open inbox items that match a keyword for the planning area.
4. If there are matches, show them.
   Ask the user if the plan promotes one of them.
5. Write the plan from the template.
6. If the plan promotes an inbox item, mark that item.

While you plan, you can find new deferred discoveries.
Ask the user before you create each inbox item.
Use the `obsidian-inbox` skill to write it.

## Plan template

Save the plan as `<notes>/plans/<YYYY-MM-DD>-<slug>.md`.
Use `date +%F` for the date.
Use a short kebab-case slug.

```markdown
---
branch: <branch>
created: <YYYY-MM-DD>
promoted-from: <inbox-file-name>
---

# <Title>

## Goal

<the outcome of the work>

## Context

<the facts that shaped the plan>

## Steps

- [ ] <step>

## Decisions

- <decision and the reason for it>

## Log

- <YYYY-MM-DD>: <entry>
```

- **`branch`:** the output of `git branch --show-current` in the checkout or worktree.
- **`created`:** the date of today.
- **`promoted-from`:** the promoted inbox file name without the `.md` extension, such as `2026-10-14-flaky-retry`, as plain text.
  Include it only when the plan promotes an inbox item.
- **`marked-for-deletion`:** optional.
  Add it only when you mark the plan.
- **Progress:** track progress with the Steps checkboxes and the Log.
  A new plan has only the fields above.
  The user may add more fields later.

## Edit a plan

1. Read the plan file again before each edit.
   The user can change it at any time.
2. Make the edit.

Add new Log entries at the end of the Log, as `- <YYYY-MM-DD>: <entry>`.

## Remove a finished plan

1. Ask in one line: "Remove the finished plan `<file>`?"
2. If the user declines, stop.
3. Mark the plan.
