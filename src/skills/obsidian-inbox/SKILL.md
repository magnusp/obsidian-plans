---
name: obsidian-inbox
description: Holds deferred discoveries for the current repository in the Obsidian vault inbox. It holds deferred discoveries only, not facts or user preferences. Use when you find an issue that is out of scope for the current task, when the user says "put this in the inbox", when the user asks what is deferred, or when the user drops an inbox item.
---

# Obsidian inbox

An inbox item is a deferred discovery that is not ready to plan.
An item in `inbox/` is open until it is marked.

## Scripts

- Run `plans-resolve` from the current directory.
  Read the notes folder path from the `notes=` line.
  Use only the `notes=` line.
- If the shell reports that `plans-resolve` is not found, tell the user to run `src/install --vault <dir>` in the obsidian-plans repository.
  Then stop.
- If `plans-resolve` fails, show its stderr message to the user.
  If the message is about the config, tell the user to run `src/install --vault <dir>` in the obsidian-plans repository.
  Then stop.

## Files

- Write files only in `<notes>/inbox/`.
- Use plain file operations only.
  The user handles version control of the vault.
- Put each path in double quotes, such as `"<notes>/inbox/"`.

## The user's edits

The user edits items by hand.
Treat the user's version of an item as correct.

- Keep every front matter field that you do not know.
- Keep every section that you do not know.
- Keep the user's formatting and wording.
- Change only the lines that your task needs.
- Never rewrite or reformat a whole item.

## Marked items

You never delete a note.
To remove an item, you mark it.
The user deletes marked items.

- **Mark:** add `marked-for-deletion: <YYYY-MM-DD>` as the last line of the item's front matter.
  Use `date +%F` for the date.
  If the file has no front matter, add a front matter block at the top with only this field.
  Change nothing else in the file.
- **Marked item:** an item with the `marked-for-deletion` field is gone.
  Treat it as if it does not exist.
- **Restore:** restore a marked item only when the user asks.
  To restore, remove the `marked-for-deletion` line.
  Change nothing else in the file.

## Search open items

Every search and every listing of items skips marked items.
Use these two commands.

- **List open items:**

  ```bash
  rg --no-ignore --files-without-match '^marked-for-deletion:' "<notes>/inbox/"
  ```

- **Find open items that match a keyword:**

  ```bash
  rg --no-ignore --files-without-match --null '^marked-for-deletion:' "<notes>/inbox/" | xargs -0 -r rg --no-ignore -l -i '<keyword>'
  ```

  If the output is empty, there are no matches.
  The exit code is then 123.

## Add an item

1. Run `plans-resolve`.
2. Pick one or two keywords for the topic.
3. Find open items that match each keyword.
4. If the user asked you directly to add the item, go to step 6.
5. Offer in one line: "Add to the inbox?"
   If the user declines, stop.
6. If step 3 found matches, show at most 2 of them.
   Ask the user to choose: append to one of them, or create a new item.
7. Write the new item from the template, or append to the chosen item.

Write an item only after the user accepts it or asks for it.

## Item template

Save the item as `<notes>/inbox/<YYYY-MM-DD>-<slug>.md`.
Use `date +%F` for the date.
Use a short kebab-case slug.

```markdown
---
created: <YYYY-MM-DD>
branch: <branch>
source: <user|agent>
affects: <host>/<owner>/<repo>
---

**Found:** <what was found>

**Why it matters:** <why it matters>

**Where to look:** <where to look>
```

- **`created`:** the date of today.
- **`branch`:** the output of `git branch --show-current` in the checkout or worktree.
  If the output is empty, the `HEAD` is detached.
  Then remove the `branch` line.
- **`source`:** `user` if the user brought up the discovery.
  `agent` if you found it.
- **`affects`:** include it only when the item belongs to another repository.
  Use the repository path below the ghq root.
- **`marked-for-deletion`:** optional.
  Add it only when you mark the item.
- **Body:** keep each of the three parts to one or two sentences.
- **Code references:** use them only when the item needs them.
  Write a repository-relative path plus a short SHA.
  Quote at most a few lines.

To append, add the new finding at the end of the body.
Keep the three parts: found, why it matters, and where to look.

## Recall

Read items from `inbox/` in these two cases only:

1. The user asks what is deferred.
   List the open items.
   Read them and summarize them.
2. The user starts planning in an area.
   Find open items that match a keyword for the area.
   Show the matches.

## Drop an item

When the user asks to drop an item, mark it.

To promote an item to a plan, use the `obsidian-plans` skill.
Promotion also marks the item.
