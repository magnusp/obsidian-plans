---
title: How the pieces fit
description: How a checkout, a worktree, and a notes folder relate, and which tool does what.
sidebar:
  order: 1
---

This page explains how the parts of obsidian-plans work together.
The [reference pages](/reference/concepts/) hold the exact rules.

## One path names three places

Each repository has a relative path below the ghq root, such as `github.com/acme/widget`.
The same relative path names three places.

- **Checkout:** `<ghq root>/github.com/acme/widget`.
- **Worktrees:** `<ghq root>/worktrees/github.com/acme/widget/<branch-with-dashes>`.
- **Notes folder:** `<notes root>/github.com/acme/widget`.

The notes folder mirrors the layout that `ghq` uses for checkouts.
So the path of one place gives you the paths of the other two.
A worktree for the branch `feature/login` is the directory `feature-login` below the worktrees of the repository.
All worktrees of a repository share one notes folder, because the notes folder follows the main checkout.

## How plans-resolve finds the repository

`plans-resolve` turns your current directory into the three paths.
It handles three starting points.

- **A checkout or a worktree:** `git rev-parse --git-common-dir` gives the main checkout.
  The path of the main checkout below the ghq root is the relative path.
- **A notes folder:** The scripts never run git in the vault.
  So `plans-resolve` walks up to the `.plans-vault` marker instead.
  The path of the marker folder below the notes root is the relative path.
- **Anywhere else:** `plans-resolve` fails.

`plans-worktree`, `plans-list`, and `plans-open` call `plans-resolve` from their own directory.
The skills call it by name.
So the config rules, the depth rule, and the path rules live in one script.

## Which tool does what

- **`install`:** Writes the config file and links the scripts and the skills.
  It never touches the vault.
- **`plans-resolve`:** Prints the checkout, the vault, and the notes folder.
  It creates the notes folder if the folder is missing.
- **`plans-worktree`:** Creates or removes a worktree at the mirrored path.
  On removal, it warns about a plan for the branch and keeps the plan.
- **`plans-list`:** Prints the open inbox items and plans.
  It creates nothing.
- **`plans-open`:** Opens the `index.md` of the notes folder in Obsidian.
- **`obsidian-inbox` skill:** Writes and recalls inbox items, after you agree.
- **`obsidian-plans` skill:** Writes, recalls, and removes plans, after you agree.
- **Plugin:** Runs `plans-list` and draws the result for you, outside the model context.

## Who writes to the vault

These actors change the vault.
`plans-resolve` creates the notes folder and `index.md`.
The agents write inbox items and plans through the skills.
You edit anything you like in Obsidian.

`plans-worktree` and `plans-open` call `plans-resolve` without `--no-create`, so they can also create a notes folder.
`plans-list` uses `--no-create`.
The README gives the reason for `plans-list`, which is that you can run it in any repository.
The plugin runs `plans-list` at every session start.
By inference, a listing that created folders would add a notes folder for each repository where you start Claude Code.
