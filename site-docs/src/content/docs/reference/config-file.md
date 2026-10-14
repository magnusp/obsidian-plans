---
title: Config file
description: Where the config file lives, how scripts parse it, and when a script rejects it.
sidebar:
  order: 2
---

## Location

- The config file is `<config dir>/config`.
- The config dir is `$OBSIDIAN_PLANS_CONFIG_DIR`.
- If `OBSIDIAN_PLANS_CONFIG_DIR` is not set, the config dir is `${XDG_CONFIG_HOME:-$HOME/.config}/obsidian-plans`.

## Format

- The file has plain `key=value` lines.
- Scripts parse the lines and never `source` the file.
- Scripts ignore blank lines and lines that start with `#`.
- Scripts ignore a line without `=` and a line with an unknown key.
- Scripts trim spaces around the key and the value.
- If a key appears more than once, the last value wins.
- Scripts remove one matching pair of single or double quotes around a value before `~` expands.
- A pair of quotes with nothing between them gives an empty value.
- A leading `~` in a value expands to `$HOME` when the `~` is the whole value or a `/` follows it.
- A `~` that a name follows stays as written.
- Scripts ignore a byte-order mark at the start of the file.

## Keys

- **`vault`:** Required.
  The value is the absolute path of an existing vault.
  A relative path fails.
- **`subfolder`:** Optional.
  The default is `obsidian-plans`.
  The value is a single folder name with no `/`.
  The value is not `.` or `..`.

## Failures

Every script that needs the config fails with a message on stderr and a non-zero exit in these cases.
The message tells you to run `install --vault <dir>`.

- The config file is missing.
- `vault` is missing.
- `vault` is a relative path.
- `vault` is not an existing directory.
- `vault` has no `.obsidian/` folder.
- `subfolder` is empty or contains `/`.
- `subfolder` is `.` or `..`.
- `HOME` is unset, and neither `OBSIDIAN_PLANS_CONFIG_DIR` nor `XDG_CONFIG_HOME` is set.
- A value is `~` or starts with `~/`, and `HOME` is unset.
