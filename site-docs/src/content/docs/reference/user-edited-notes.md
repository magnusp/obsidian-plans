---
title: Notes that you edit
description: What agents keep when they change a note, and which fields scripts and skills read.
sidebar:
  order: 12
---

- You edit inbox items and plans by hand.
- Your version of a note is correct.

## Agent edits

- Agents keep every unknown front matter field.
- Agents keep every unknown section.
- Agents keep your formatting and wording.
- Agents change only the lines that the task needs.
- Agents never rewrite or reformat a whole note.

## Fields that scripts and skills read

- Scripts and skills read only the fields that the reference pages name.
  Any other field is safe.
- Recall and the `plans-worktree --remove` warning find a plan by the exact front matter line `branch: <branch>`.
  Another form of that line hides the plan from recall.
  Another form also hides the plan from the `plans-worktree --remove` warning.
- The scripts read `marked-for-deletion` only in the front matter.
  The skills match the field at the start of any line.
  A body line that starts with `marked-for-deletion:` hides the note from agents.
  This difference is known and accepted.
