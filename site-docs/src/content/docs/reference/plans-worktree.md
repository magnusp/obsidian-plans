---
title: plans-worktree
description: How plans-worktree creates and removes a worktree for a branch.
sidebar:
  order: 6
---

## Usage

```bash
plans-worktree <branch> [<start-point>]
plans-worktree --remove <branch>
```

Any other set of arguments fails with a usage message on stderr and a non-zero exit.

## Behavior

1. `plans-worktree` resolves the main checkout.
   It fails if you run it outside the ghq root.
   It fails if you run it from inside the notes root.
   Like `plans-resolve`, it creates the notes folder, `.plans-vault`, `inbox/`, `plans/`, and `index.md` if they are missing.
2. It replaces `/` in the branch name with `-` to get the directory name.
   It fails if the branch name is not a valid git branch name.
3. It creates `<ghq root>/worktrees/<host>/<owner>/.../<repo>/<directory>`.
4. It picks the branch for the worktree in this order.
   - If the branch exists, it checks out the branch.
   - If the branch exists only on `origin`, it creates a local branch at the remote head that tracks the remote branch.
   - Otherwise, it creates the branch from the start point, with no upstream.

   The default start point is `origin/HEAD`.
   The first fallback is a local `main`.
   The last fallback is the `HEAD` of the main checkout.
   If git fails, `plans-worktree` leaves no new directory behind.
5. It fails if another branch already maps to the same directory name.
   If the directory already holds a worktree for the same branch, it prints the path and exits 0.
6. It prints only the worktree path on stdout.
7. With `--remove`, it runs `git worktree remove`.
   It fails if the directory for the branch holds no worktree for that branch.
   If a plan with `branch: <branch>` exists in the notes folder, it prints a warning on stderr.
   The line counts only in the [front matter](/reference/concepts/#front-matter) of the plan.
   It skips a plan that has `marked-for-deletion`.
   It never deletes the plan or the notes folder.
