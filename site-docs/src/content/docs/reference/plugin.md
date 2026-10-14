---
title: Plugin
description: How the Claude Code plugin shows the open inbox items and plans without adding them to the model context.
sidebar:
  order: 14
---

- The plugin lives in `src/plugin/`.
- The plugin is a Claude Code plugin with a mod.
  A mod is code that runs inside Claude Code and draws in its interface.
- The plugin shows you the open inbox items and plans.
  Nothing that it shows enters the model context.

## Limits

- The plugin never returns text from a command.
  Claude reads the text of a command, so the plugin returns an empty result.
- The plugin calls `plans-list` by name, in the working directory of the session.
- The plugin writes no note, runs no git command, and changes nothing in the vault.

## Session start

- At session start, the plugin runs `plans-list`.
- If `plans-list` exits 0 and prints at least one line, the plugin shows one toast.
  The toast text is `inbox <n> · plans <m>`.
- If `plans-list` fails or prints nothing, the plugin shows nothing.

## The plans command

- The plugin adds the command `/plans`.
- The command runs `plans-list` and opens a pane with the id `plans` and the title `Plans`.
- **Esc** closes the pane.
- The pane has the heading `Inbox (<n>)`, then one row for each inbox item with its name.
- The pane has the heading `Plans (<m>)`, then one row for each plan.
  A row is the name, followed by `[<branch>]` if the plan has a branch.
- A group with no entries shows the row `None.`.
- If `plans-list` fails, the pane shows its stderr message.
- If `plans-list` is not found, the pane tells you to run `src/install --vault <dir>` in the obsidian-plans repository.

## Requirements

- The plugin needs Claude Code 2.1.287 or later.
- The plugin draws in the terminal and in the Desktop app.
  Elsewhere, it draws nothing.

## Loading

- You load the plugin with `claude --plugin-dir <path to src/plugin>`, or you install it from a marketplace.
- `install` does not load the plugin.

## Tests

- The `bats` tests do not cover the plugin.
- `claude plugin test` runs the plugin tests.
