# obsidian-plans

obsidian-plans is a set of Bash scripts, two Claude skills, and a Claude Code plugin.
They keep the plans and the inbox items of each repository in an Obsidian vault that you already have.
The folders in the vault mirror the layout that `ghq` uses for checkouts.
The tools never run a git command in your vault.

## Get started

Run these commands from the root of this repository.

```bash
mise install
src/install --vault <path to your vault>
```

For the options and the result, read [Install the tools](site-docs/src/content/docs/how-to/install-the-tools.md).

## Documentation

The documentation is a Starlight site in `site-docs/`.
These links go to the source pages.

- **How-to guides:**
  - [Install the tools](site-docs/src/content/docs/how-to/install-the-tools.md)
  - [Load the plugin](site-docs/src/content/docs/how-to/load-the-plugin.md)
  - [Delete marked notes](site-docs/src/content/docs/how-to/delete-marked-notes.md)
  - [Put the Obsidian folder under Git](site-docs/src/content/docs/how-to/put-the-obsidian-folder-under-git.md)
  - [Run the tests](site-docs/src/content/docs/how-to/run-the-tests.md)
- **Reference:**
  - [Concepts](site-docs/src/content/docs/reference/concepts.md) defines the terms that the other pages use.
  - [The reference folder](site-docs/src/content/docs/reference/) holds the contract for each script, skill, and the plugin.
- **Explanation:**
  - [How the pieces fit](site-docs/src/content/docs/explanation/how-the-pieces-fit.md)
  - [Why notes are marked, not deleted](site-docs/src/content/docs/explanation/why-notes-are-marked-not-deleted.md)
  - [Why your edits win](site-docs/src/content/docs/explanation/why-your-edits-win.md)
  - [The Obsidian config folder and Git](site-docs/src/content/docs/explanation/obsidian-config-and-git.md)
