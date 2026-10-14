---
title: plans-list
description: How plans-list prints the open inbox items and plans of the current repository.
sidebar:
  order: 7
---

## Usage

```bash
plans-list
```

You run `plans-list` from a checkout, a worktree, or a directory inside a notes folder.

## Behavior

1. `plans-list` resolves the notes folder with `plans-resolve --no-create`.
   If `plans-resolve` fails, `plans-list` fails with the same message on stderr and a non-zero exit.
   If `plans-resolve` prints a warning on stderr, `plans-list` passes the warning to stderr and still exits 0.
   One such warning says that the checkout does not exist.
2. It creates nothing and writes nothing.
   If the notes folder, `inbox/`, or `plans/` is missing, that part has no entries.
   It then exits 0.
3. It lists each open note.
   An open note is a file `*.md` directly in `inbox/` or `plans/`.
   The front matter of an open note has no `marked-for-deletion` field.
   `plans-list` skips a file whose name starts with `.`.
4. It prints the entries to stdout, one entry per line, with tab characters between the fields.
5. It prints nothing if there are no open notes.
6. It never runs a git command.
   It never changes anything in the vault.

## Front matter

- Front matter is the block between a first line `---` and the next line `---`.
- Each of the two delimiter lines is exactly `---`.
  A line with a trailing space or a trailing carriage return is not a delimiter line.
- A file without front matter is open.
- A file that has a first line `---` and no closing `---` has no front matter.
- A front matter line that starts with `marked-for-deletion:` marks the note.
  The line marks the note even when the value is empty.

## Entries

- `plans-list` prints the inbox entries first and then the plan entries.
- It sorts each group by file name.
  The sort compares the whole file name, with `.md`, byte by byte as `LC_ALL=C` does.
  For example, `a-b.md` sorts before `a.md`.
- **`inbox<TAB><name>`:** `<name>` is the file name without `.md`.
- **`plan<TAB><name><TAB><branch>`:** `<name>` is the file name without `.md`.
  `<branch>` is the value of the branch line, trimmed.

## Branch line

- The branch line is the exact front matter line `branch: <branch>`.
- A line matches when it starts with `branch: `, with one space after the colon.
- If more than one line matches, the first line wins.
- `plans-list` trims spaces and tabs around the value.
- A line such as `branch:feature` or ` branch: feature` does not match.
- `<branch>` is empty if the plan has no matching line.

## Repeated runs

Two runs of `plans-list` give the same result.
