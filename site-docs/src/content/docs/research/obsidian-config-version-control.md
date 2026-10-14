---
title: Version control for the Obsidian configuration folder
---

This note explains how to put the `.obsidian/` folder of a vault under Git.
It covers which files to share, which files to ignore, known problems, and nested repositories.
It ends with a recommended `.gitignore`.

Research date: 2026-10-14.

## How to read the evidence

Each claim has a source tag.

- **Official:** The claim comes from Obsidian's help site or the obsidian-git documentation.
- **Community:** The claim comes from forum threads, plugin pages, or blog posts.
- **Tested:** The claim comes from a local test with Git 2.43.0.
- **Unverified:** The claim comes from general knowledge, and no source confirmed it.

## Summary

- **Ignore by default:** Ignore `workspace.json`, `workspace-mobile.json`, `.trash/`, and OS files. (Official, Community)
- **Share by default:** Share `app.json`, `appearance.json`, `core-plugins.json`, `community-plugins.json`, `hotkeys.json`, `themes/`, and `snippets/`. (Community)
- **Plugins:** Decide per vault. Never commit a `data.json` file that holds a secret. (Community)
- **Nested repository:** A subfolder with its own `.git` is not a problem for Obsidian. Git itself treats it as an embedded repository. (Tested)

## What the `.obsidian/` folder contains

Obsidian creates the `.obsidian/` folder in the root of the vault.
It holds preferences that belong to that vault.
The official page gives hotkeys, themes, and community plugins as examples.
(Official: How Obsidian stores data.)

The official page names two files as noisy.
These files are `.obsidian/workspace.json` and `.obsidian/workspaces.json`.
They record the workspace layout.
They change each time you open a file.
The page tells Git users to add both files to `.gitignore`.
(Official.)

## Files to ignore

- **`workspace.json`:** Stores the open tabs and the layout. It changes on almost every action. Ignore it. (Official)
- **`workspaces.json`:** Stores layouts saved by the core Workspaces plugin. The official page says to ignore it. You may keep it if you want shared named layouts. (Official for the ignore advice, Unverified for the sharing case)
- **`workspace-mobile.json`:** Stores the layout of the mobile app. The obsidian-git documentation lists it as a file to exclude. (Official)
- **`.trash/`:** Holds deleted files if you choose the **Move to Obsidian trash** option. Ignore it. The obsidian-git documentation lists it. (Official)
- **`.DS_Store`:** An operating system file. Ignore it. (Official)
- **`cache`:** Some tutorials ignore `.obsidian/cache`. I found no official source for this entry. (Community, Unverified)
- **Large plugin indexes:** Plugins such as Smart Connections and Copilot write large index files. One forum user ignores them. Each device then rebuilds the index. (Community)

A forum thread points out a common typo.
Many posts write `workspaces.json` when the user means `workspace.json`.
Use both names in your ignore file.
(Community.)

### Files that change without your action

A forum user reported changes in the Git view while they did nothing.
The user blamed `workspace.json`, `app.json`, and some `data.json` files.
The user ignored `workspace.json` and `app.json` as volatile UI state.
(Community.)

Treat this with care.
The `app.json` file also holds shared editor settings.
Ignore it only if the churn bothers you.

## Files to share

I found no official list of the files to share.
The files below are the ones that community posts usually keep.
They hold settings that you want on every device.

- **`app.json`:** Editor and file settings. (Community)
- **`appearance.json`:** Theme choice, font, and enabled snippets. (Community)
- **`core-plugins.json`:** The list of enabled core plugins. (Community)
- **`community-plugins.json`:** The list of enabled community plugins. (Community)
- **`hotkeys.json`:** Your custom hotkeys. (Community)
- **`themes/`:** Installed themes. (Community)
- **`snippets/`:** Your CSS snippets. (Community)
- **`plugins/*/data.json`:** Plugin settings. Share it only after you check it for secrets. (Community)

One forum user ignored `.obsidian/themes` and `.obsidian/appearance.json`.
That user wanted to share content but keep personal settings.
Another user warned that ignoring all of `.obsidian/` forces you to redo setup on every machine.
(Community.)

Obsidian Sync offers a useful comparison.
By default, it syncs the main settings, appearance, themes and snippets, hotkeys, the active core plugin list, and core plugin settings.
It does not sync community plugins unless you turn on two options.
These options are **Active community plugin list** and **Installed community plugin list**.
(Official: Obsidian Sync settings.)
This list matches the shared set above.

I could not verify the role of other files.
These files are `graph.json`, `bookmarks.json`, `canvas.json`, `daily-notes.json`, `templates.json`, `types.json`, and `backlink.json`.
From general knowledge, they hold settings for core features.
`graph.json` changes when you adjust the graph view.
You may share or ignore each file.
(Unverified.)

## Plugin code or plugin settings only

A community plugin lives in `.obsidian/plugins/<plugin-id>/`.
A plugin release has three files: `main.js`, `manifest.json`, and `styles.css`.
The `styles.css` file is optional.
(Official: developer documentation on releases.)
The `data.json` file is not part of a release.
The plugin writes it at run time to store settings.
(Unverified as an official statement. This matches how plugins behave.)

### Option 1: Commit everything under `plugins/`

- **Benefit:** A new device gets the same plugins and the same versions without a download.
- **Benefit:** Mobile devices get the plugins through `git pull`.
- **Cost:** The repository holds minified code that you do not review.
- **Cost:** Updates create large, unreadable diffs.
- **Cost:** `data.json` can hold secrets. See the next section.
- **Cost:** Some plugins write caches or indexes in their folder.

### Option 2: Commit only plugin settings

- **Benefit:** The repository stays small, and the diffs are readable.
- **Benefit:** You commit no third-party code.
- **Cost:** Each device must install the plugins again.
- **Cost:** The device may install different plugin versions.
- **Cost:** The `community-plugins.json` file lists the plugins, but it does not install them.

### Option 3: Ignore all plugin files

The obsidian-git documentation offers `.obsidian/plugins` as an ignore entry.
The comment says this helps stop a plugin from exposing sensitive data.
(Official.)

A forum user adds a trade-off.
If the notes need a plugin, each contributor must install that plugin.
(Community.)

### Practical rule

- **Personal vault on few devices:** Commit `plugins/` if no `data.json` holds a secret.
- **Shared repository or public repository:** Commit settings only, or commit no plugin files.
- **Mixed approach:** Ignore `plugins/*/main.js`, `plugins/*/manifest.json`, and `plugins/*/styles.css`. Track `plugins/*/data.json` after a review. (Unverified as a documented pattern. It follows from the facts above.)

## Known problems

### Secrets in `data.json`

Many plugins store API keys and tokens in plain text in `data.json`.
A GitHub issue on the AI Research Assistant plugin says this.
Any plugin and any code with file access can read the key.
(Community.)

CVE-2025-58401 is a documented case.
The Obsidian GitHub Copilot plugin before version 1.1.7 stored a GitHub token without encryption.
(Community: Tenable and OSV entries.)

One forum user lost an OpenAI key.
The user published a Hugo site from Git, and the key was exposed.
The user then added `.obsidian/plugins/*/data.json` to `.gitignore`.
(Community.)

Obsidian 1.11.0 added a `SecretStorage` API for plugins.
One research note says it encrypts secrets with the operating system on desktop.
I could not verify this on an official page.
The note also says few plugins use the API yet.
(Community, Unverified.)

What to do:

1. Search every `data.json` for keys, tokens, and passwords before the first commit.
2. If a secret was ever committed, rotate it. Removing the file from the latest commit is not enough.
3. If you cannot review each plugin, ignore `plugins/*/data.json`.

### Merge conflicts

- **Cause:** Two devices change `workspace.json` or a plugin `data.json`. Git then reports a conflict.
- **Evidence:** A forum thread reports a conflict on `workspace.json`. (Community)
- **Fix when the file is already tracked:** Adding a file to `.gitignore` does not stop Git from tracking it. Run `git rm --cached .obsidian/workspace.json`. (Community. This is standard Git behavior.)
- **Warning:** One user reported that a pull deleted the existing `.obsidian` folder after they ignored it. Back up the folder first. (Community)
- **Prevention:** Ignore the noisy files. Use commit-and-sync often. The obsidian-git documentation recommends an automatic interval. (Official)

The obsidian-git documentation warns about live use.
It says Git does not share changes live to the cloud or to another person.
(Official.)

### Mobile and desktop differences

- **Separate layout file:** The mobile app uses `workspace-mobile.json`. Ignore it. (Official)
- **Plugin availability:** Some community plugins work only on desktop. The shared `community-plugins.json` file can enable a plugin that fails on mobile. (Unverified)
- **obsidian-git on mobile:** The plugin uses a different Git implementation on mobile. (Official)
  - No SSH authentication.
  - Limited repository size because of memory.
  - No rebase merge strategy.
  - No submodule support.
  - The app can crash or run without end on a large repository.
- **Advice from the maintainer:** For a large vault, stage single files and commit only staged files. (Official)
- **No `.git` on a device:** If the plugin runs where no `.git` folder exists, enable **Disable on this device** under **Advanced**. This setting is not synced. (Official)

### The `.trash` folder

With the **Move to Obsidian trash** option, Obsidian moves deleted files to `.trash/` in the vault.
(Community summary of the help page. I could not fetch the exact help page.)
Ignore `.trash/`.
The obsidian-git documentation lists it.
(Official.)

### Line endings

- **Symptom:** On Windows, Obsidian can remove the carriage return when you open a note. Git then shows a change, although the text is the same. (Community)
- **Cause:** The editor normalizes line endings to LF. (Community)
- **Recommendation from one forum guide:** Use LF on all systems. Add `* text=auto eol=lf` to `.gitattributes`. Set `core.autocrlf` to `false`. (Community)
- **Conflicting advice:** Another user needed `autocrlf=true` on Windows. The right value depends on your setup. (Community)
- **Official guidance:** The obsidian-git documentation pages that I could fetch say nothing on line endings. I could not open its Common Issues page. (Unverified)

A `.gitattributes` file in the vault root is the safest choice.
It makes the result the same on every device.

## Nested Git repositories in a vault

This section covers a subfolder with its own `.git`.
The vault may or may not be a Git repository.

### How Obsidian treats the folder

- **Hidden folders:** Obsidian does not show folders that start with a dot, such as `.git`. They do not appear in the file explorer, search, or graph. (Community. I found no official statement.)
- **The `.git` folder:** The `.git` folder inside a subfolder is hidden for this reason. Obsidian does not index it. (Community)
- **Files in the nested repository:** The other files in the subfolder are normal files. Obsidian indexes the Markdown files in them. (Unverified. This follows from the rules above.)
- **Obsidian Sync:** The official help page says Sync skips files and folders that start with a dot. The examples include `.git`. The only exception is `.obsidian`. (Official)
- **Result for Sync:** The nested repository content syncs, but its `.git` folder does not. A forum user reports four and a half years of use without problems. (Community)

### How Git treats the nested repository

I tested this with Git 2.43.0.

- **Parent repository, nested folder not ignored:** The command `git add .` prints a warning. The warning says `adding embedded git repository`. Git stores the folder as a single entry with mode `160000`. This entry is a gitlink. It holds a commit hash. It does not hold the files. (Tested)
- **Before `git add`:** The status command shows the folder as untracked (`?? sub/`). It does not list the files inside. (Tested)
- **Parent repository, folder ignored:** If `.gitignore` has `sub/`, the folder does not appear in the status. (Tested)
- **Clones:** A clone of the parent repository does not contain the nested files. Git does not know how to get them. This comes from the Git hint text. (Tested)
- **Nested repository itself:** Git commands inside the subfolder use only the nested repository. The parent `.gitignore` does not affect them. (Tested)
- **Vault not a repository:** No parent exists. The nested repository is independent. Nothing special happens. (Tested for plain Git behavior)

### How obsidian-git treats it

- **Which repository:** The plugin runs Git commands for the vault. I could not confirm how it finds the repository when the vault is a subfolder of a repository. (Unverified)
- **Known issue:** Issue 660 reports that line authoring does not work if the vault is not the repository root. Other features worked. (Community)
- **Submodules:** The README lists submodule support as desktop-only and opt-in. Mobile has no submodule support. (Official)
- **Nested repositories:** The README does not use the term nested repository. I found no official statement on how the plugin treats them. (Unverified)
- **Community plugins for this case:** Git Subbridge scans for sub-repositories and asks you to disable obsidian-git. Not Submodules adds a `*-git-repo/` line to `.gitignore`. (Community)
- **Workaround from the documentation:** Keep the `.git` directory elsewhere. Add a `.git` file in the vault that holds `gitdir: <path>`. I saw this only in a search summary. (Community, Unverified)

### Recommendation

1. If the nested repository must stay independent, add its folder to the parent `.gitignore`.
2. If you want the parent to track the pointer, use `git submodule add <url> <path>`.
3. Do not run `git add .` in the parent without checking for the embedded repository warning.
4. Do not rely on obsidian-git for the nested repository. Run Git commands for it in a terminal.
5. Do not install two Git plugins for the same repository.

## Recommended `.gitignore`

This file is a starting point.
It keeps the shared settings and ignores the device state.
It ignores plugin code and caches.
It tracks plugin settings.

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

### Variants

If you cannot review plugin settings for secrets, add this line:

```gitignore
.obsidian/plugins/*/data.json
```

If you want a clean content-only repository, replace the plugin lines with this line:

```gitignore
.obsidian/
```

If a nested repository must stay independent, add its folder:

```gitignore
projects/my-repository/
```

If a file is already tracked, remove it from the index:

```fish
git rm --cached .obsidian/workspace.json
```

### Optional `.gitattributes`

```gitattributes
* text=auto eol=lf
```

## What I could not verify

- **Official `.obsidian/` file list:** No official page lists every file and its purpose.
- **`graph.json` and other core files:** I based the advice on general knowledge.
- **`.obsidian/cache`:** No source confirmed this path.
- **Official statement on hidden folders in the vault:** Only community sources describe it. The Sync page is official, but it covers Sync only.
- **obsidian-git Common Issues page:** The page was not reachable.
- **obsidian-git with nested repositories:** No documentation or issue confirmed the behavior.
- **`SecretStorage` details:** I did not see an official page.
- **The `.trash` help text:** I saw it only in a search summary.

## Sources

- [Obsidian help: How Obsidian stores data](https://obsidian.md/help/Files+and+folders/How+Obsidian+stores+data) (Official). Describes `.obsidian/` and the two workspace files.
- [Obsidian help: Sync settings and selective sync](https://obsidian.md/help/sync/settings) (Official). Describes hidden files, `.git`, and the `.obsidian` exception.
- [Obsidian developer docs: Release your plugin with GitHub Actions](https://docs.obsidian.md/Plugins/Releasing/Release+your+plugin+with+GitHub+Actions) (Official). Lists the three release files.
- [obsidian-git documentation: Tips and tricks](https://publish.obsidian.md/git-doc/Tips-and-Tricks) (Official). Gives the `.gitignore` examples.
- [obsidian-git documentation: Start here](https://publish.obsidian.md/git-doc/Start+here) (Official). Explains the plugin's purpose and terms.
- [obsidian-git README](https://github.com/Vinzent03/obsidian-git) (Official). Lists mobile limits and desktop-only submodule support.
- [Forum: What files should I ignore in git when using Obsidian?](https://forum.obsidian.md/t/what-files-should-i-ignore-in-git-when-using-obsidian/45554) (Community)
- [Forum: Looking for an example .gitignore file](https://forum.obsidian.md/t/looking-for-an-example-gitignore-file/47351) (Community)
- [Forum: What should I gitignore for my vault's GitHub repository?](https://forum.obsidian.md/t/what-should-i-gitignore-for-my-vaults-github-repository/101077) (Community)
- [Forum: Solving Git sync issues caused by different system line endings](https://forum.obsidian.md/t/solving-git-sync-issues-caused-by-different-system-line-endings/92253) (Community)
- [Forum: Store secrets like API key outside of data.json](https://forum.obsidian.md/t/store-secrets-like-api-key-outside-of-data-json/56035) (Community)
- [Forum: Obsidian Sync ignores Git repos within vault](https://forum.obsidian.md/t/feat-obsidian-sync-ignores-git-repos-within-vault/112102) (Community)
- [Forum: Multiple vaults in one Git repository](https://forum.obsidian.md/t/multiple-vaults-in-one-git-repository/61886) (Community)
- [Forum: Hidden folders not showing in File Explorer](https://forum.obsidian.md/t/hidden-folders-dotfiles-not-showing-in-file-explorer-despite-detect-all-file-types-being-enabled/106685) (Community)
- [Tenable: CVE-2025-58401](https://www.tenable.com/cve/CVE-2025-58401) (Community). Covers the plaintext token in the GitHub Copilot plugin.
- [Git Subbridge plugin page](https://community.obsidian.md/plugins/git-subbridge) (Community)
- [Not Submodules plugin page](https://community.obsidian.md/plugins/not-submodules) (Community)
- Local test with Git 2.43.0 on 2026-10-14 (Tested). It covered the embedded repository warning, the gitlink entry, and the effect of an ignore entry.
