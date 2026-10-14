---
title: Run the tests
description: Run the script tests, the plugin tests, and the site build before you open a pull request.
sidebar:
  order: 5
---

CI runs the same task on each pull request.
Run it on your machine first.

## Run all the tests

1. Go to the root of your obsidian-plans checkout.
2. Run `mise install`.
3. Run `mise run test`.

The `test` task runs three tasks:

- `test-scripts` runs the `bats` tests in `src/test`.
- `test-plugin` runs `claude plugin test` for the plugin in `src/plugin`.
- `test-site` installs the site dependencies and builds the site in `site-docs`.
  The build fails if an internal link is broken.

The tests use temporary directories.
They never touch your real `~/src`, your real `~/.config`, or your vault.

## Run one group of tests

To run one group, run its task by name.
For example, run `mise run test-scripts` to run only the `bats` tests.
