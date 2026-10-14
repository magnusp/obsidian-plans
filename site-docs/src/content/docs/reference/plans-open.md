---
title: plans-open
description: How plans-open opens the index note of the current repository in Obsidian.
sidebar:
  order: 8
---

## Usage

```bash
plans-open
```

You run `plans-open` from a checkout, a worktree, or a directory inside a notes folder.

## Behavior

1. `plans-open` checks that `jq` exists.
   It then checks that the opener exists.
   The opener is `${PLANS_OPEN_COMMAND:-xdg-open}`.
   It fails with a message on stderr for the first one that is missing.
2. It resolves the notes folder with `plans-resolve`.
3. It reads `${OBSIDIAN_CONFIG_DIR:-$HOME/.config/obsidian}/obsidian.json`.
   It checks that a vault entry has a `path` equal to the vault path.
   If `OBSIDIAN_CONFIG_DIR` is not set and `HOME` is unset, it fails with a message on stderr.
   If the file is not valid JSON, it fails with a message on stderr.
   If the file is missing or has no matching entry, it fails with this message on stderr.

   ```text
   plans-open: Open the vault once in Obsidian, then run plans-open again.
   ```

4. It runs the opener with `obsidian://open?path=<url-encoded absolute path of index.md>`.
   It percent-encodes every byte outside `A-Za-z0-9._~-`.
   If the opener exits with a non-zero status, `plans-open` fails with a message on stderr.
5. It prints nothing on stdout.
6. It never writes to `obsidian.json`.
   It never reads or writes any other Obsidian file.
