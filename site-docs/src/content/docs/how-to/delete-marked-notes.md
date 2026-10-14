---
title: Delete marked notes
description: Find the notes that agents marked for deletion, restore the notes that you want, and delete the rest.
sidebar:
  order: 3
---

An agent never deletes a note.
The agent adds `marked-for-deletion: <date>` to the front matter of the note.
Agents and scripts then treat the note as gone.
To learn why, read [Why notes are marked, not deleted](/explanation/why-notes-are-marked-not-deleted/).

## Find your notes root

The notes root is `<vault>/<subfolder>`.
The [config file](/reference/config-file/) holds the vault and the subfolder.
In the commands on this page, replace `<notes root>` with that path.

## List the marked notes

Run this command.

```bash
rg --files-with-matches --glob '*.md' '^marked-for-deletion:' <notes root>
```

## Restore a note

To restore a note, ask the agent.
You can also remove the `marked-for-deletion` line from the front matter yourself.

## Delete the marked notes

:::caution
The deletion is permanent.
Check the list of marked notes before you delete them.
:::

1. Run the command in [List the marked notes](#list-the-marked-notes).
2. Check each path in the output.
3. Run the same command with the output piped to `rm`.

```bash
rg --files-with-matches --null --glob '*.md' '^marked-for-deletion:' <notes root> | xargs -0 rm
```
