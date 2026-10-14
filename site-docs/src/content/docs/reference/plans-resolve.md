---
title: plans-resolve
description: How plans-resolve finds the checkout, the vault, and the notes folder of the current repository.
sidebar:
  order: 5
---

## Usage

```bash
plans-resolve [--no-create]
```

- You run `plans-resolve` from a checkout, a worktree, or a directory inside a notes folder.
- An unknown argument fails with a message on stderr and a non-zero exit.

## Output

`plans-resolve` prints these lines on stdout, one `key=value` per line.

- **`repo=<path>`:** The checkout path.
- **`vault=<path>`:** The vault path.
- **`notes=<path>`:** The notes folder path.
- **`worktree=<path>`:** The worktree path.
  `plans-resolve` prints this line only when you run it from a worktree.

## Behavior

1. `plans-resolve` reads and validates the config file.
2. From a checkout or a worktree, it finds the main checkout with `git rev-parse --git-common-dir`.
   It computes the relative path below the ghq root.
3. From inside a notes folder, it walks up from the current directory to the nearest `.plans-vault`.
   The notes folder path relative to the notes root gives the relative repository path.
   If there is no marker, it fails with a clear message on stderr and a non-zero exit.
4. It always prints `repo=`, `vault=`, and `notes=`.
   If the checkout does not exist, it prints the expected path and a warning on stderr.
   It then exits 0.
5. It creates the notes folder, `.plans-vault`, `inbox/`, `plans/`, and `index.md` if they are missing.
   With `--no-create`, it creates nothing.
   The output stays the same.
6. It never creates the vault.
   It never writes inside `.obsidian/`.
   It never runs any git command in the vault.
7. If the path is outside all three roots, it fails with a message on stderr and a non-zero exit.
   The three roots are the ghq root, the worktrees root, and the notes root.
   A path inside the vault but outside the notes root also fails.

## Repeated runs

Two runs of `plans-resolve` give the same result.
