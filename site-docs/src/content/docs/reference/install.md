---
title: install
description: How the install script writes the config file and links the scripts and the skills.
sidebar:
  order: 9
---

## Usage

```bash
install [--vault <dir> [--subfolder <name>]]
```

An unknown argument, or an option without a value, fails with a usage message on stderr and a non-zero exit.

## Config file

- If you pass `--vault`, `install` validates it as the [config file](/reference/config-file/) rules say.
- `install` trims spaces and tabs around the `--vault` value first.
  It also trims spaces and tabs around the `--subfolder` value.
- A leading `~` in the `--vault` value expands to `$HOME` when the `~` is the whole value or a `/` follows it.
- After a valid `--vault`, `install` writes the config file and replaces an existing one.
  This is how you repair a broken config.
- If you do not pass `--vault` and a config file exists, `install` keeps the file and reports that.
- If you do not pass `--vault` and no config file exists, `install` fails.
- If you pass `--subfolder` without `--vault`, `install` fails.
- If you pass `--vault` without `--subfolder`, `install` writes the default subfolder.
- A failed validation leaves an existing config unchanged.
- `install` also needs `HOME`, so it fails when `HOME` is unset.

## Links

- `install` symlinks each file in `src/bin/` into `~/.local/bin`.
- It symlinks each directory in `src/skills/` into `~/.claude/skills`.
- It never overwrites an existing file that is not a symlink.
  It reports the file and continues.
- It replaces an existing symlink.

## Limits

- `install` never runs a git command.
- It never creates or changes anything in the vault.
- Two runs of `install` give the same result.
