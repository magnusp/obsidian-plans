---
title: Plan
description: The file, the front matter, the body, and the agent rules of a plan.
sidebar:
  order: 11
---

## File

The file is `<notes>/plans/YYYY-MM-DD-<slug>.md`.

## Front matter

- **`branch`:** The worktree branch.
- **`created`:** The ISO 8601 date.
- **`promoted-from`:** The inbox item file name without `.md`, as plain text.
  The field is present only when it applies.
- **`marked-for-deletion`:** Optional.
  The ISO 8601 date of the removal.

A plan has no status field.
The only state is the optional `marked-for-deletion` field.

## Body

- The body has the sections Goal, Context, Steps, Decisions, and Log.
- The Steps section holds checkboxes.
- The Log has dated entries that you and the agent append to.
- You and the agent both edit a plan.

## Recall

- When an agent starts in a worktree, it looks for a plan with a matching `branch`.
- The lookup skips plans with `marked-for-deletion`.
- If the agent finds a plan, it offers in one line to load the plan.
- The agent never loads the plan without your answer.

## Creation outside a worktree

- If you start a plan in the main checkout, the agent offers in one line to create a worktree.
- If you decline, the plan records the current branch.

## Promotion

- Promoting an inbox item adds `marked-for-deletion` to the item.
- The plan records `promoted-from`.
- Planning may create new inbox items.
  The agent asks you first.

## Removal

- The agent asks before it removes a finished plan.
- Removal adds `marked-for-deletion` to the plan.
- The agent never deletes the file.
