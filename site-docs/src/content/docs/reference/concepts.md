---
title: Concepts
description: The terms that every script, skill, and reference page uses.
sidebar:
  order: 1
---

## Scope of the contract

The pages in the reference section are the shared contract for all scripts and skills.
If you find a conflict or a gap in the contract, you stop and report it.
You do not invent behavior.

## Checkout

A checkout is a repository that `ghq` cloned to `<ghq root>/<host>/<owner>/.../<repo>`.

## Worktree

A worktree is a git worktree at `<ghq root>/worktrees/<host>/<owner>/.../<repo>/<branch-with-dashes>`.
The worktrees root is `<ghq root>/worktrees`.

## Vault

- The vault is an existing Obsidian vault that you choose.
- The config file names the vault.
- The vault has an `.obsidian/` folder.
- The scripts never change anything in `.obsidian/`.

## Notes root

- The notes root is `<vault>/<subfolder>`.
- The config file names the subfolder.
- The default subfolder is `obsidian-plans`.

## Notes folder

- The notes folder is `<notes root>/<host>/<owner>/.../<repo>`.
- Each repository has one notes folder.

## Note

A note is an inbox item or a plan.

## Ghq root

The ghq root is the output of `ghq root`.

## Depth

- A repository path has at least two levels below the root, such as `<host>/<repo>`.
- There is no maximum depth.
- A shallower path fails with a message on stderr.

## Submodules and bare repositories

- Neither a submodule nor a bare repository is a checkout.
- `plans-resolve` fails with a message on stderr when you run it inside either one.

## Marked for deletion

- A tool or an agent never deletes a note.
- The tool or the agent adds the front matter field `marked-for-deletion: <ISO 8601 date>` to the note.
- A note with this field is gone, but not yet deleted.
- Every search for inbox items or plans skips these notes.
- The agent restores a note only when you ask.
- You can also restore a note by hand.
- Restoring a note means removing the field.
- You delete the marked notes yourself.
- The README documents one command that deletes them.

## Version control

- The tools never run git commands in the vault.
- The tools never commit, stage, or push.
- You version the vault, or you do not.
