---
title: Skill rules
description: The rules that the obsidian-inbox and obsidian-plans skills follow.
sidebar:
  order: 13
---

## Names

The skills are named `obsidian-inbox` and `obsidian-plans`.

## Scripts

- The skills call the scripts by name, such as `plans-resolve`.
- The skills read `notes=` from the output and never use `vault=`.
- If a script is missing, the skill tells you to run `install`.

## Vault

- The skills never run a git command in the vault.
- The skills never commit.
- The skills never run `rm` or any other command that deletes a note.
- The skills only add or remove the `marked-for-deletion` field.
- To find notes without the field, the skills use `rg --files-without-match '^marked-for-deletion:'`.

## Wording

- The word "memory" does not appear in the skills.
  Claude has a built-in memory, and the vault is a separate concept.
- The skills are written with the `writing-for-agents` skill.
