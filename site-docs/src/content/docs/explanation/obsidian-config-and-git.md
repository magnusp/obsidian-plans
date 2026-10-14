---
title: The Obsidian config folder and Git
description: What the .obsidian folder holds, which files to share or ignore in Git, the known problems, and how nested repositories behave.
sidebar:
  order: 4
---

This page explains what happens when you put the `.obsidian/` folder of a vault under Git.
It covers the files to share, the files to ignore, the known problems, and nested repositories.
For the steps and the recommended `.gitignore`, read [Put the Obsidian folder under Git](/how-to/put-the-obsidian-folder-under-git/).

The research for this page is from 2026-10-14.

## How to read the evidence tags

Each claim has a source tag in parentheses.

- **Official:** The claim comes from Obsidian's help site or the obsidian-git documentation.
- **Community:** The claim comes from forum threads, plugin pages, or blog posts.
- **Tested:** The claim comes from a local test with Git 2.43.0.
- **Unverified:** The claim comes from general knowledge, and no source confirmed it.

## The short version

- **Ignore by default:** Ignore `workspace.json`, `workspace-mobile.json`, `.trash/`, and operating system files. (Official, Community)
- **Share by default:** Share `app.json`, `appearance.json`, `core-plugins.json`, `community-plugins.json`, `hotkeys.json`, `themes/`, and `snippets/`. (Community)
- **Plugins:** Decide for each vault.
  Never commit a `data.json` file that holds a secret. (Community)
- **Nested repository:** A subfolder with its own `.git` is not a problem for Obsidian.
  Git itself treats the subfolder as an embedded repository. (Tested)

## What the folder holds

Obsidian creates the `.obsidian/` folder in the root of the vault.
The folder holds the preferences of that vault.
The official page gives hotkeys, themes, and community plugins as examples.
(Official, from the page "How Obsidian stores data".)

The official page names two files as noisy.
These files are `.obsidian/workspace.json` and `.obsidian/workspaces.json`.
They record the workspace layout.
They change each time you open a file.
The page tells Git users to add both files to `.gitignore`.
(Official.)

## Why some files stay out of Git

This list names each file to ignore and the reason.

- **`workspace.json`:** Stores the open tabs and the layout.
  It changes on almost every action.
  Ignore it. (Official)
- **`workspaces.json`:** Stores the layouts that you save with the core Workspaces plugin.
  The official page says to ignore it.
  If you want shared named layouts, you can keep it. (Official for the ignore advice, Unverified for the sharing case)
- **`workspace-mobile.json`:** Stores the layout of the mobile app.
  The obsidian-git documentation lists it as a file to exclude. (Official)
- **`.trash/`:** Holds deleted files if you choose the **Move to Obsidian trash** option.
  Ignore it.
  The obsidian-git documentation lists it. (Official)
- **`.DS_Store`:** An operating system file.
  Ignore it. (Official)
- **`cache`:** Some tutorials ignore `.obsidian/cache`.
  The research found no official source for this entry. (Community, Unverified)
- **Large plugin indexes:** Plugins such as Smart Connections and Copilot write large index files.
  One forum user ignores them.
  Each device then rebuilds the index. (Community)

A forum thread points out a common typo.
Many posts write `workspaces.json` when the author means `workspace.json`.
Use both names in your ignore file.
(Community.)

### Files that change without your action

A forum user reported changes in the Git view while they did nothing.
The user blamed `workspace.json`, `app.json`, and some `data.json` files.
The user ignored `workspace.json` and `app.json` as volatile UI state.
(Community.)

Treat this report with care.
The `app.json` file also holds shared editor settings.
Ignore `app.json` only if the changes bother you.

## Which files to share

The research found no official list of the files to share.
The files below are the files that community posts usually keep.
They hold settings that you want on every device.

- **`app.json`:** Editor and file settings. (Community)
- **`appearance.json`:** The theme choice, the font, and the enabled snippets. (Community)
- **`core-plugins.json`:** The list of enabled core plugins. (Community)
- **`community-plugins.json`:** The list of enabled community plugins. (Community)
- **`hotkeys.json`:** Your custom hotkeys. (Community)
- **`themes/`:** The installed themes. (Community)
- **`snippets/`:** Your CSS snippets. (Community)
- **`plugins/*/data.json`:** Plugin settings.
  Share it only after you check it for secrets. (Community)

One forum user ignored `.obsidian/themes` and `.obsidian/appearance.json`.
That user wanted to share content but keep personal settings.
Another user warned that if you ignore all of `.obsidian/`, you must redo the setup on every machine.
(Community.)

Obsidian Sync gives a useful comparison.
By default, Sync syncs the main settings, appearance, themes and snippets, hotkeys, the active core plugin list, and core plugin settings.
Sync does not sync community plugins unless you turn on two options.
These options are **Active community plugin list** and **Installed community plugin list**.
(Official, from the page "Obsidian Sync settings".)
This list matches the shared set above.

The research could not verify the role of other files.
These files are `graph.json`, `bookmarks.json`, `canvas.json`, `daily-notes.json`, `templates.json`, `types.json`, and `backlink.json`.
From general knowledge, they hold settings for core features.
`graph.json` changes when you adjust the graph view.
You may share or ignore each file.
(Unverified.)

## Plugin code and plugin settings

A community plugin lives in `.obsidian/plugins/<plugin-id>/`.
A plugin release has three files: `main.js`, `manifest.json`, and `styles.css`.
The `styles.css` file is optional.
(Official, from the developer documentation on releases.)
The `data.json` file is not part of a release.
The plugin writes `data.json` at run time to store settings.
(Unverified as an official statement. This matches how plugins behave.)

You have three options for the `plugins/` folder.
To pick one, follow the rule in [Choose how to handle plugin files](/how-to/put-the-obsidian-folder-under-git/#choose-how-to-handle-plugin-files).

### Commit everything under `plugins/`

- **Benefit:** A new device gets the same plugins and the same versions without a download.
- **Benefit:** Mobile devices get the plugins through `git pull`.
- **Cost:** The repository holds minified code that you do not review.
- **Cost:** Updates create large diffs that you cannot read.
- **Cost:** `data.json` can hold secrets.
  Read [Secrets in `data.json`](#secrets-in-datajson).
- **Cost:** Some plugins write caches or indexes in their folder.

### Commit only plugin settings

- **Benefit:** The repository stays small, and the diffs are readable.
- **Benefit:** You commit no third-party code.
- **Cost:** Each device must install the plugins again.
- **Cost:** The device may install different plugin versions.
- **Cost:** The `community-plugins.json` file lists the plugins, but it does not install them.

### Ignore all plugin files

The obsidian-git documentation offers `.obsidian/plugins` as an ignore entry.
The comment says that this entry helps stop a plugin from exposing sensitive data.
(Official.)

A forum user adds a trade-off.
If the notes need a plugin, each contributor must install that plugin.
(Community.)

## Known problems

### Secrets in `data.json`

Many plugins store API keys and tokens in plain text in `data.json`.
A GitHub issue on the AI Research Assistant plugin says this.
Any plugin and any code with file access can read the key.
(Community.)

CVE-2025-58401 is a documented case.
The Obsidian GitHub Copilot plugin before version 1.1.7 stored a GitHub token without encryption.
(Community, from the Tenable and OSV entries.)

One forum user lost an OpenAI key.
The user published a Hugo site from Git, and the key was exposed.
The user then added `.obsidian/plugins/*/data.json` to `.gitignore`.
(Community.)

Obsidian 1.11.0 added a `SecretStorage` API for plugins.
One research note says that the API encrypts secrets with the operating system on desktop.
The research could not verify this claim on an official page.
The note also says that few plugins use the API yet.
(Community, Unverified.)

For what to do, read [Check plugin settings for secrets](/how-to/put-the-obsidian-folder-under-git/#check-plugin-settings-for-secrets).

### Merge conflicts

- **Cause:** Two devices change `workspace.json` or a plugin `data.json`.
  Git then reports a conflict.
- **Evidence:** A forum thread reports a conflict on `workspace.json`. (Community)

The obsidian-git documentation warns about live use.
It says that Git does not share changes live to the cloud or to another person.
(Official.)

To fix a tracked file and to prevent conflicts, read [Stop tracking files that you now ignore](/how-to/put-the-obsidian-folder-under-git/#stop-tracking-files-that-you-now-ignore) and [Keep conflicts rare](/how-to/put-the-obsidian-folder-under-git/#keep-conflicts-rare).

### Mobile and desktop differences

- **Separate layout file:** The mobile app uses `workspace-mobile.json`.
  Ignore it. (Official)
- **Plugin availability:** Some community plugins work only on desktop.
  The shared `community-plugins.json` file can enable a plugin that fails on mobile. (Unverified)
- **obsidian-git on mobile:** The plugin uses a different Git implementation on mobile. (Official)
  It has these limits:
  - No SSH authentication.
  - A limit on the repository size because of memory.
  - No rebase merge strategy.
  - No submodule support.
  - The app can crash or run without end on a large repository.

For the maintainer's advice on mobile, read [Set up obsidian-git on each device](/how-to/put-the-obsidian-folder-under-git/#set-up-obsidian-git-on-each-device).

### The `.trash` folder

With the **Move to Obsidian trash** option, Obsidian moves deleted files to `.trash/` in the vault.
(Community summary of the help page. The research could not fetch the exact help page.)
Ignore `.trash/`.
The obsidian-git documentation lists it.
(Official.)

### Line endings

- **Symptom:** On Windows, Obsidian can remove the carriage return when you open a note.
  Git then shows a change, although the text is the same. (Community)
- **Cause:** The editor normalizes line endings to LF. (Community)
- **Official guidance:** The obsidian-git documentation pages that the research could fetch say nothing on line endings.
  The research could not open its Common Issues page. (Unverified)

For the forum advice and the conflicting advice, read [Set the line endings](/how-to/put-the-obsidian-folder-under-git/#set-the-line-endings).

## Nested Git repositories in a vault

This section covers a subfolder with its own `.git`.
The vault may or may not be a Git repository.

### How Obsidian treats the folder

- **Hidden folders:** Obsidian does not show folders that start with a dot, such as `.git`.
  They do not appear in the file explorer, the search, or the graph. (Community. The research found no official statement.)
- **The `.git` folder:** For this reason, the `.git` folder inside a subfolder is hidden.
  Obsidian does not index it. (Community)
- **Files in the nested repository:** The other files in the subfolder are normal files.
  Obsidian indexes the Markdown files in them. (Unverified. This follows from the rules above.)
- **Obsidian Sync:** The official help page says that Sync skips files and folders that start with a dot.
  The examples include `.git`.
  The only exception is `.obsidian`. (Official)
- **Result for Sync:** The content of the nested repository syncs, but its `.git` folder does not.
  A forum user reports four and a half years of use without problems. (Community)

### How Git treats the nested repository

The research tested this with Git 2.43.0.

- **Parent repository, nested folder not ignored:** The command `git add .` prints a warning.
  The warning says `adding embedded git repository`.
  Git stores the folder as a single entry with mode `160000`.
  This entry is a gitlink.
  It holds a commit hash.
  It does not hold the files. (Tested)
- **Before `git add`:** The status command shows the folder as untracked (`?? sub/`).
  It does not list the files inside. (Tested)
- **Parent repository, folder ignored:** If `.gitignore` has `sub/`, the folder does not appear in the status. (Tested)
- **Clones:** A clone of the parent repository does not contain the nested files.
  Git does not know how to get them.
  This comes from the Git hint text. (Tested)
- **Nested repository itself:** Git commands inside the subfolder use only the nested repository.
  The parent `.gitignore` does not affect them. (Tested)
- **Vault not a repository:** No parent exists.
  The nested repository is independent.
  Nothing special happens. (Tested for plain Git behavior)

### How obsidian-git treats it

- **Which repository:** The plugin runs Git commands for the vault.
  The research could not confirm how the plugin finds the repository when the vault is a subfolder of a repository. (Unverified)
- **Known issue:** Issue 660 reports that line authoring does not work if the vault is not the repository root.
  Other features worked. (Community)
- **Submodules:** The obsidian-git README lists submodule support as desktop-only and opt-in.
  Mobile has no submodule support. (Official)
- **Nested repositories:** The obsidian-git README does not use the term nested repository.
  The research found no official statement on how the plugin treats them. (Unverified)
- **Community plugins for this case:** Git Subbridge scans for sub-repositories and asks you to disable obsidian-git.
  Not Submodules adds a `*-git-repo/` line to `.gitignore`. (Community)
- **Workaround from the documentation:** Keep the `.git` directory elsewhere.
  Add a `.git` file in the vault that holds `gitdir: <path>`.
  The research saw this workaround only in a search summary. (Community, Unverified)

For what to do with a nested repository, read [Handle a nested repository](/how-to/put-the-obsidian-folder-under-git/#handle-a-nested-repository).

## What the research could not verify

- **Official `.obsidian/` file list:** No official page lists every file and its purpose.
- **`graph.json` and other core files:** The advice comes from general knowledge.
- **`.obsidian/cache`:** No source confirmed this path.
- **Official statement on hidden folders in the vault:** Only community sources describe it.
  The Sync page is official, but it covers Sync only.
- **obsidian-git Common Issues page:** The page was not reachable.
- **obsidian-git with nested repositories:** No documentation or issue confirmed the behavior.
- **`SecretStorage` details:** The research did not see an official page.
- **The `.trash` help text:** The research saw it only in a search summary.

## Sources

- [Obsidian help: How Obsidian stores data](https://obsidian.md/help/Files+and+folders/How+Obsidian+stores+data) (Official).
  Describes `.obsidian/` and the two workspace files.
- [Obsidian help: Sync settings and selective sync](https://obsidian.md/help/sync/settings) (Official).
  Describes hidden files, `.git`, and the `.obsidian` exception.
- [Obsidian developer docs: Release your plugin with GitHub Actions](https://docs.obsidian.md/Plugins/Releasing/Release+your+plugin+with+GitHub+Actions) (Official).
  Lists the three release files.
- [obsidian-git documentation: Tips and tricks](https://publish.obsidian.md/git-doc/Tips-and-Tricks) (Official).
  Gives the `.gitignore` examples.
- [obsidian-git documentation: Start here](https://publish.obsidian.md/git-doc/Start+here) (Official).
  Explains the purpose and the terms of the plugin.
- [obsidian-git README](https://github.com/Vinzent03/obsidian-git) (Official).
  Lists the mobile limits and the desktop-only submodule support.
- [Forum: What files should I ignore in git when using Obsidian?](https://forum.obsidian.md/t/what-files-should-i-ignore-in-git-when-using-obsidian/45554) (Community)
- [Forum: Looking for an example .gitignore file](https://forum.obsidian.md/t/looking-for-an-example-gitignore-file/47351) (Community)
- [Forum: What should I gitignore for my vault's GitHub repository?](https://forum.obsidian.md/t/what-should-i-gitignore-for-my-vaults-github-repository/101077) (Community)
- [Forum: Solving Git sync issues caused by different system line endings](https://forum.obsidian.md/t/solving-git-sync-issues-caused-by-different-system-line-endings/92253) (Community)
- [Forum: Store secrets like API key outside of data.json](https://forum.obsidian.md/t/store-secrets-like-api-key-outside-of-data-json/56035) (Community)
- [Forum: Obsidian Sync ignores Git repos within vault](https://forum.obsidian.md/t/feat-obsidian-sync-ignores-git-repos-within-vault/112102) (Community)
- [Forum: Multiple vaults in one Git repository](https://forum.obsidian.md/t/multiple-vaults-in-one-git-repository/61886) (Community)
- [Forum: Hidden folders not showing in File Explorer](https://forum.obsidian.md/t/hidden-folders-dotfiles-not-showing-in-file-explorer-despite-detect-all-file-types-being-enabled/106685) (Community)
- [Tenable: CVE-2025-58401](https://www.tenable.com/cve/CVE-2025-58401) (Community).
  Covers the plaintext token in the GitHub Copilot plugin.
- [Git Subbridge plugin page](https://community.obsidian.md/plugins/git-subbridge) (Community)
- [Not Submodules plugin page](https://community.obsidian.md/plugins/not-submodules) (Community)
- Local test with Git 2.43.0 on 2026-10-14 (Tested).
  The test covered the embedded repository warning, the gitlink entry, and the effect of an ignore entry.
