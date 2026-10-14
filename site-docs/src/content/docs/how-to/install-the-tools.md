---
title: Install the tools
description: Install the scripts and the skills, and point them at your Obsidian vault.
sidebar:
  order: 1
---

You need `mise` and an Obsidian vault that you already have.

## Install the scripts and the skills

1. Go to the root of your obsidian-plans checkout.
2. Run `mise install`.
   The command installs `bats` and the other tools that `mise.toml` pins.
3. Run `src/install --vault <path to your vault>`.

```bash
mise install
src/install --vault <path to your vault>
```

The install script does three things:

- It writes the [config file](/reference/config-file/) with the vault and the subfolder.
- It symlinks the scripts into `~/.local/bin`.
- It symlinks the skills into `~/.claude/skills`.

If a file exists and it is not a symlink, the script does not overwrite it.
The script reports the file and continues.

## Use a different subfolder

The default subfolder is `obsidian-plans`.
To use a different subfolder, add `--subfolder <name>`.

```bash
src/install --vault <path to your vault> --subfolder <name>
```

## Change the vault

To change the vault, run the install script again with a new `--vault`.
The script replaces the config file.

## Run the script again

You can run the install script again at any time.
Two runs give the same result.

For every option and every error, read the [install reference](/reference/install/).
To see your inbox items and plans in Claude Code, [load the plugin](/how-to/load-the-plugin/).
