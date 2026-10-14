---
title: Inbox item
description: The file, the front matter, the body, and the agent rules of an inbox item.
sidebar:
  order: 10
---

An inbox item is a deferred discovery that is not ready to plan.
An inbox item is not a fact, and it is not a user preference.

## File

The file is `<notes>/inbox/YYYY-MM-DD-<slug>.md`.

## Front matter

- **`created`:** The ISO 8601 date.
- **`branch`:** The branch where the agent found the item.
  The agent omits this field on a detached `HEAD`.
- **`source`:** `user` or `agent`.
- **`affects`:** `<host>/<owner>/.../<repo>`.
  The field is present only when the item belongs to another repository.
- **`marked-for-deletion`:** Optional.
  The ISO 8601 date of the removal.

## Body

The body has three short parts.
The parts say what was found, why it matters, and where to look.

## Code references

- An inbox item avoids code references.
- If the item needs a code reference, it uses a repository-relative path plus a short SHA.
- The item quotes at most a few lines of code.

## Lifecycle

- An item in `inbox/` without `marked-for-deletion` is open.
- Promoting or dropping an item adds `marked-for-deletion` to the file.
- The agent never deletes the file.

## Agent rules

1. Agents never write an item silently.
2. Before the agent offers an item, it runs `rg` over `inbox/` for the topic.
   The search skips files with `marked-for-deletion`.
3. The agent offers the item in one line, "Add to the inbox?".
   If `rg` found matches, the agent shows at most 2 of them.
   You then choose to append to a match or to create a new item.
4. The agent writes only after you accept.
5. If you ask directly, such as "put this in the inbox", the agent skips the offer.
   The agent still runs the duplicate search.
6. Recall is on demand only.
   The agent reads `inbox/` in two cases.
   In the first case, you ask what is deferred.
   In the second case, you start planning in an area where an open item matches by `rg`.
   Both reads skip files with `marked-for-deletion`.
   The agent never loads every item at session start.
