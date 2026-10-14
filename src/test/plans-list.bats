#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

PLANS_LIST="$BATS_TEST_DIRNAME/../bin/plans-list"
TAB=$'\t'

setup() {
  local sandbox
  sandbox=$(cd "$BATS_TEST_TMPDIR" && pwd -P)
  export HOME="$sandbox/home"
  export GHQ_ROOT="$sandbox/ghq"
  export OBSIDIAN_PLANS_CONFIG_DIR="$sandbox/config"
  VAULT="$sandbox/vault"
  NOTES_ROOT="$VAULT/obsidian-plans"
  REPO="github.com/acme/widget"
  NOTES="$NOTES_ROOT/$REPO"
  mkdir -p "$HOME" "$GHQ_ROOT" "$VAULT/.obsidian" "$OBSIDIAN_PLANS_CONFIG_DIR"
  printf 'vault=%s\n' "$VAULT" >"$OBSIDIAN_PLANS_CONFIG_DIR/config"
  git init -q -b main "$GHQ_ROOT/$REPO"
}

write_note() {
  local path="$NOTES/$1"
  mkdir -p "$(dirname "$path")"
  cat >"$path"
}

list_in_repo() {
  cd "$GHQ_ROOT/$REPO"
  run --separate-stderr "$PLANS_LIST" "$@"
}

@test "prints nothing and creates nothing when the notes folder is missing" {
  list_in_repo

  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -e "$NOTES_ROOT" ]
}

@test "prints nothing for empty inbox and plans folders" {
  mkdir -p "$NOTES/inbox" "$NOTES/plans"

  list_in_repo

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "prints an inbox item by its file name without the extension" {
  write_note inbox/2026-10-01-flaky-test.md <<'NOTE'
---
created: 2026-10-01
source: agent
---
Body.
NOTE

  list_in_repo

  [ "$status" -eq 0 ]
  [ "$output" = "inbox${TAB}2026-10-01-flaky-test" ]
}

@test "prints a plan with its branch" {
  write_note plans/2026-10-10-hook-mod.md <<'NOTE'
---
branch: feature/hook-mod
created: 2026-10-10
---
NOTE

  list_in_repo

  [ "$status" -eq 0 ]
  [ "$output" = "plan${TAB}2026-10-10-hook-mod${TAB}feature/hook-mod" ]
}

@test "prints a plan without a branch line with an empty branch" {
  write_note plans/2026-10-10-loose.md <<'NOTE'
---
created: 2026-10-10
---
NOTE

  list_in_repo

  [ "$status" -eq 0 ]
  [ "$output" = "plan${TAB}2026-10-10-loose${TAB}" ]
}

@test "prints a note without front matter" {
  write_note inbox/2026-10-02-bare.md <<'NOTE'
Just text.
NOTE

  list_in_repo

  [ "$status" -eq 0 ]
  [ "$output" = "inbox${TAB}2026-10-02-bare" ]
}

@test "skips an inbox item and a plan marked for deletion" {
  write_note inbox/2026-10-01-gone.md <<'NOTE'
---
created: 2026-10-01
marked-for-deletion: 2026-10-05
---
NOTE
  write_note plans/2026-10-01-gone.md <<'NOTE'
---
branch: old
marked-for-deletion: 2026-10-05
---
NOTE
  write_note inbox/2026-10-03-kept.md <<'NOTE'
---
created: 2026-10-03
---
NOTE

  list_in_repo

  [ "$status" -eq 0 ]
  [ "$output" = "inbox${TAB}2026-10-03-kept" ]
}

@test "ignores a marked-for-deletion line in the body" {
  write_note inbox/2026-10-04-body.md <<'NOTE'
---
created: 2026-10-04
---
marked-for-deletion: 2026-10-05
NOTE

  list_in_repo

  [ "$status" -eq 0 ]
  [ "$output" = "inbox${TAB}2026-10-04-body" ]
}

@test "treats a note with an unclosed front matter block as having none" {
  write_note plans/2026-10-10-unclosed.md <<'NOTE'
---
created: 2026-10-10
branch: not-a-branch
marked-for-deletion: 2026-10-11
NOTE

  list_in_repo

  [ "$status" -eq 0 ]
  [ "$output" = "plan${TAB}2026-10-10-unclosed${TAB}" ]
}

@test "ignores a branch line in the body" {
  write_note plans/2026-10-10-body.md <<'NOTE'
---
created: 2026-10-10
---
branch: not-the-branch
NOTE

  list_in_repo

  [ "$status" -eq 0 ]
  [ "$output" = "plan${TAB}2026-10-10-body${TAB}" ]
}

@test "ignores files that are not markdown and files in subfolders" {
  write_note inbox/notes.txt <<<"text"
  write_note inbox/nested/2026-10-01-deep.md <<<"deep"
  write_note inbox/2026-10-01-real.md <<<"real"

  list_in_repo

  [ "$status" -eq 0 ]
  [ "$output" = "inbox${TAB}2026-10-01-real" ]
}

@test "prints inbox items before plans, each sorted by file name" {
  write_note plans/2026-10-02-b.md <<<"b"
  write_note plans/2026-10-01-a.md <<<"a"
  write_note inbox/2026-10-04-d.md <<<"d"
  write_note inbox/2026-10-03-c.md <<<"c"

  list_in_repo

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "inbox${TAB}2026-10-03-c" ]
  [ "${lines[1]}" = "inbox${TAB}2026-10-04-d" ]
  [ "${lines[2]}" = "plan${TAB}2026-10-01-a${TAB}" ]
  [ "${lines[3]}" = "plan${TAB}2026-10-02-b${TAB}" ]
}

@test "lists the notes of the repository from a worktree" {
  git -C "$GHQ_ROOT/$REPO" -c user.name=T -c user.email=t@example.com commit -q --allow-empty -m initial
  local worktree="$GHQ_ROOT/worktrees/$REPO/feature-x"
  mkdir -p "$(dirname "$worktree")"
  git -C "$GHQ_ROOT/$REPO" worktree add -q -b feature/x "$worktree"
  write_note inbox/2026-10-01-shared.md <<<"shared"

  cd "$worktree"
  run --separate-stderr "$PLANS_LIST"

  [ "$status" -eq 0 ]
  [ "$output" = "inbox${TAB}2026-10-01-shared" ]
}

@test "lists the notes from a directory inside the notes folder" {
  write_note inbox/2026-10-01-here.md <<<"here"
  touch "$NOTES/.plans-vault"

  cd "$NOTES/inbox"
  run --separate-stderr "$PLANS_LIST"

  [ "$status" -eq 0 ]
  [ "$output" = "inbox${TAB}2026-10-01-here" ]
}

@test "fails with the resolve message when the config is missing" {
  rm "$OBSIDIAN_PLANS_CONFIG_DIR/config"

  list_in_repo

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ $stderr == *"install --vault"* ]]
}

@test "fails outside the ghq root" {
  cd "$HOME"
  run --separate-stderr "$PLANS_LIST"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ $stderr == *"outside the ghq root"* ]]
}

@test "gives the same result when run twice" {
  write_note inbox/2026-10-01-a.md <<<"a"

  list_in_repo
  local first=$output
  list_in_repo

  [ "$output" = "$first" ]
}
