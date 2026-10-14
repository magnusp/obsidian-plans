---
title: Put the Obsidian folder under Git
description: Share the settings in the .obsidian folder of a vault through Git, and keep device state and secrets out.
sidebar:
  order: 4
---

These steps put the `.obsidian/` folder of a vault under Git.
The result shares the settings and ignores the device state.
For the reasons behind each step, read [The Obsidian config folder and Git](/explanation/obsidian-config-and-git/).

Each claim has a source tag in parentheses.
The [evidence tags](/explanation/obsidian-config-and-git/#how-to-read-the-evidence-tags) section explains them.
The research is from 2026-10-14.

## Check plugin settings for secrets

Many plugins store API keys and tokens in plain text in `data.json`.

1. Before the first commit, search every `data.json` for keys, tokens, and passwords.
2. If a secret was ever committed, rotate it.
   Removing the file from the latest commit is not enough.
3. If you cannot review each plugin, ignore `plugins/*/data.json`.
   The [variants](#adjust-the-gitignore-for-your-vault) show the line.

## Choose how to handle plugin files

Use this rule to choose what to commit from `.obsidian/plugins/`.

- **Personal vault on few devices:** Commit `plugins/` if no `data.json` holds a secret.
- **Shared repository or public repository:** Commit settings only, or commit no plugin files.
- **Mixed approach:** Ignore `plugins/*/main.js`, `plugins/*/manifest.json`, and `plugins/*/styles.css`.
  Track `plugins/*/data.json` after a review.
  (Unverified as a documented pattern. It follows from the facts on the [explanation page](/explanation/obsidian-config-and-git/#plugin-code-and-plugin-settings).)

## Add the recommended `.gitignore`

This file is a starting point.
It keeps the shared settings and ignores the device state.
It ignores plugin code and caches.
It tracks plugin settings.

Create a `.gitignore` file in the root of the vault with this content.

```gitignore
# Device-specific workspace state
.obsidian/workspace.json
.obsidian/workspaces.json
.obsidian/workspace-mobile.json

# Plugin code is installed per device
.obsidian/plugins/*/main.js
.obsidian/plugins/*/manifest.json
.obsidian/plugins/*/styles.css

# Plugin caches and indexes
.obsidian/cache
.smart-connections/
.obsidian/plugins/*/*-index*.json

# Obsidian trash
.trash/

# Operating system and editor files
.DS_Store
Thumbs.db
.idea/
.vscode/
```

## Adjust the `.gitignore` for your vault

If you cannot review plugin settings for secrets, add this line.

```gitignore
.obsidian/plugins/*/data.json
```

If you want a clean content-only repository, replace the plugin lines with this line.

```gitignore
.obsidian/
```

If a nested repository must stay independent, add its folder.

```gitignore
projects/my-repository/
```

## Stop tracking files that you now ignore

If you add a file to `.gitignore`, Git does not stop tracking the file.
(Community. This is standard Git behavior.)

:::caution
One user reported that a pull deleted the existing `.obsidian` folder after they ignored it.
Back up the folder first. (Community)
:::

1. Back up the `.obsidian/` folder.
2. Remove the file from the index.

```bash
git rm --cached .obsidian/workspace.json
```

## Set the line endings

This step is optional.
A `.gitattributes` file in the vault root is the safest choice.
It makes the result the same on every device.

One forum guide recommends LF on all systems. (Community)

1. Add this line to `.gitattributes` in the root of the vault.

   ```gitattributes
   * text=auto eol=lf
   ```

2. Set `core.autocrlf` to `false`.

:::note
The advice conflicts.
Another user needed `autocrlf=true` on Windows.
The right value depends on your setup. (Community)
:::

## Keep conflicts rare

- Ignore the noisy files, as the recommended `.gitignore` does.
- Run commit-and-sync often.
  The obsidian-git documentation recommends an automatic interval. (Official)

## Set up obsidian-git on each device

- **Large vault on mobile:** Stage single files, and commit only staged files.
  The maintainer of obsidian-git gives this advice. (Official)
- **Device with no `.git` folder:** If the plugin runs on that device, enable **Disable on this device** under **Advanced**.
  This setting does not sync. (Official)

## Handle a nested repository

A nested repository is a subfolder of the vault with its own `.git`.

1. If the nested repository must stay independent, add its folder to the parent `.gitignore`.
2. If you want the parent to track the pointer, run `git submodule add <url> <path>`.
3. Do not run `git add .` in the parent without a check for the embedded repository warning.
4. Do not rely on obsidian-git for the nested repository.
   Run Git commands for it in a terminal.
5. Do not install two Git plugins for the same repository.
