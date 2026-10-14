---
title: obsidian-plans
description: Keep plans and deferred discoveries for each repository in an Obsidian vault.
---

`obsidian-plans` is a set of Bash scripts, two Claude skills, and a Claude Code plugin.
They keep one folder of plans and inbox items for each repository in a vault that you already have.

## How-to guides

- [Install the tools](/how-to/install-the-tools/) to set up the scripts and the skills for your vault.
- [Load the plugin](/how-to/load-the-plugin/) to see the open inbox items and plans in Claude Code.
- [Delete marked notes](/how-to/delete-marked-notes/) to remove the notes that agents marked for deletion.
- [Put the Obsidian folder under Git](/how-to/put-the-obsidian-folder-under-git/) to share the settings of a vault through Git.
- [Run the tests](/how-to/run-the-tests/) before you open a pull request.

## Reference

The reference pages are the contract for every script, skill, and the plugin.
Start with the [concepts](/reference/concepts/) page for the terms that the other pages use.

## Explanation

- [How the pieces fit](/explanation/how-the-pieces-fit/) shows how a checkout, a worktree, and a notes folder relate.
- [Why notes are marked, not deleted](/explanation/why-notes-are-marked-not-deleted/) explains the `marked-for-deletion` field.
- [Why your edits win](/explanation/why-your-edits-win/) explains why agents treat your version of a note as correct.
- [The Obsidian config folder and Git](/explanation/obsidian-config-and-git/) explains which files in `.obsidian/` to share and which to ignore.
