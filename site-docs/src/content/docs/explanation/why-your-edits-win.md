---
title: Why your edits win
description: Why agents treat your version of a note as correct, and why scripts and skills read so few fields.
sidebar:
  order: 3
---

You and the agents share the same notes.
You edit them by hand in Obsidian, and the agents edit them through the skills.
The contract settles every conflict in one direction, which is that your version of a note is correct.
The [notes that you edit](/reference/user-edited-notes/) page states the rules.
This page explains what they protect and what they cost.

## Agents change only what the task needs

An agent keeps every front matter field and every section that it does not know.
It keeps your formatting and wording.
It never rewrites or reformats a whole note.

You can change a plan at any time, even while an agent works on it.
The `obsidian-plans` skill tells the agent to read the plan again before each edit for that reason.
By inference, an agent that rewrote a whole note from its own copy would undo edits that it never saw.
A change limited to the lines of the task leaves your other edits in place.

## Scripts and skills read few fields

Scripts and skills read only the fields that the reference pages name.
Any other field is safe, so you can add your own fields and sections without breaking a tool.

The price is that the fields they do read have a fixed form.
Recall finds a plan only by the exact front matter line `branch: <branch>`.
If you write that line in another form, recall does not find the plan.
The `plans-worktree --remove` warning then also misses the plan.

## Where this leaves you

The rules put the burden of format on a small set of lines.
In return, everything else in a note belongs to you.
That split seems right for notes that a person reads and writes every day.
A tool that needs more structure would have to add a named field to the contract first.
