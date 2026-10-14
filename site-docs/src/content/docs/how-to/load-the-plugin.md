---
title: Load the plugin
description: Show the open inbox items and plans of the current repository in Claude Code.
sidebar:
  order: 2
---

The plugin shows you the open inbox items and plans of the current repository.
Nothing that it shows enters the model context.

The plugin runs with your permissions.
It runs only `plans-list` and draws the result.

## Check the requirements

- You need Claude Code 2.1.287 or later.
- `plans-list` must be on your `PATH`.
  To put it there, [install the tools](/how-to/install-the-tools/).
  The install script links `plans-list` into `~/.local/bin`.
- The plugin draws in the terminal and in the Desktop app.
  Elsewhere, it draws nothing.

## Start Claude Code with the plugin

Run this command, and replace the placeholder with the path to your obsidian-plans checkout.

```bash
claude --plugin-dir <path to this repository>/src/plugin
```

When a session starts, a toast shows how many inbox items and plans are open.
If `plans-list` prints nothing or fails, no toast appears.

## Show the list

1. Run `/plans`.
   A pane opens with the inbox items and the plans.
2. Press **Esc** to close the pane.

For the full behavior of the toast and the pane, read the [plugin reference](/reference/plugin/).
