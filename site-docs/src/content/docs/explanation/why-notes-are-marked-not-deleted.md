---
title: Why notes are marked, not deleted
description: Why no tool or agent deletes a note, and what the marked-for-deletion field costs you.
sidebar:
  order: 2
---

No script, skill, or plugin in obsidian-plans deletes a note.
To remove a note, an agent adds one front matter line, `marked-for-deletion: <date>`.
You delete the marked notes yourself, with the command in the README.
The [marked for deletion](/reference/concepts/#marked-for-deletion) rules state the contract.
This page explains why the design takes that path.

## The vault may have no history

The tools never run git in the vault.
They never commit, stage, or push.
You version the vault, or you do not.

So obsidian-plans cannot count on a history to bring a note back.
The README says that the deletion of marked notes is permanent.
By inference, a delete by an agent in a vault without history would lose the note for good.
A marked note comes back when you remove one line.

## Marking keeps your text

Your version of a note is correct, and agents change only the lines that a task needs.
Marking fits that rule, because it adds one line to the front matter and changes nothing else.
The rest of the note stays as you wrote it, so a restore gives you back the exact note.

`plans-worktree --remove` follows the same idea.
It removes the worktree, but it keeps the plan for the branch and prints a warning instead.

## What the marks cost

Marked notes stay on disk until you delete them.
Every search by a script or a skill skips them.
By inference, Obsidian treats the field as plain front matter.
So marked notes still show up when you browse or search the vault in Obsidian.

The scripts and the skills also read the field in slightly different places.
The scripts read it only in the front matter.
The skills match it at the start of any line.
So a body line that starts with `marked-for-deletion:` hides a note from agents, but not from `plans-list`.
The contract records this difference as known and accepted.

On balance, the trade favors you.
The cost is a cleanup step that you run when you choose.
In exchange, no agent action can lose a note that you wrote.
