#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

PLANS_WORKTREE="$BATS_TEST_DIRNAME/../bin/plans-worktree"
REPO="github.com/acme/widget"

setup() {
  local sandbox
  sandbox=$(cd "$BATS_TEST_TMPDIR" && pwd -P)
  export HOME="$sandbox/home"
  export GHQ_ROOT="$sandbox/ghq"
  export OBSIDIAN_PLANS_CONFIG_DIR="$sandbox/config"
  VAULT="$sandbox/vault"
  NOTES_ROOT="$VAULT/obsidian-plans"
  mkdir -p "$HOME" "$GHQ_ROOT" "$VAULT/.obsidian"
  write_config "vault=$VAULT"
}

write_config() {
  mkdir -p "$OBSIDIAN_PLANS_CONFIG_DIR"
  printf '%s\n' "$@" >"$OBSIDIAN_PLANS_CONFIG_DIR/config"
}

create_checkout() {
  local repo="$GHQ_ROOT/$1"
  git init -q -b main "$repo"
  git -C "$repo" config user.name "Test User"
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config commit.gpgsign false
  git -C "$repo" commit -q --allow-empty -m "initial"
}

commit_on() {
  local repo=$1 branch=$2 message=$3
  git -C "$repo" switch -q -c "$branch"
  git -C "$repo" commit -q --allow-empty -m "$message"
}

worktree_path_for() {
  echo "$GHQ_ROOT/worktrees/$REPO/$1"
}

run_in() {
  local dir=$1
  shift
  cd "$dir"
  run --separate-stderr "$PLANS_WORKTREE" "$@"
}

run_in_checkout() {
  run_in "$GHQ_ROOT/$REPO" "$@"
}

head_of() {
  git -C "$1" rev-parse HEAD
}

branch_of() {
  git -C "$1" symbolic-ref --short HEAD
}

write_plan() {
  local name=$1 branch=$2
  mkdir -p "$NOTES_ROOT/$REPO/plans"
  printf -- '---\nbranch: %s\ncreated: 2026-01-01\n---\n\n# Goal\n' "$branch" \
    >"$NOTES_ROOT/$REPO/plans/$name.md"
}

@test "creates a worktree on a new branch" {
  create_checkout "$REPO"

  run_in_checkout feature

  [ "$status" -eq 0 ]
  [ "$output" = "$(worktree_path_for feature)" ]
  [ -d "$output" ]
  [ "$(branch_of "$output")" = "feature" ]
  [ "$(head_of "$output")" = "$(head_of "$GHQ_ROOT/$REPO")" ]
}

@test "checks out an existing branch" {
  create_checkout "$REPO"
  commit_on "$GHQ_ROOT/$REPO" existing "work on existing"
  local existing_head
  existing_head=$(head_of "$GHQ_ROOT/$REPO")
  git -C "$GHQ_ROOT/$REPO" switch -q main

  run_in_checkout existing

  [ "$status" -eq 0 ]
  [ "$output" = "$(worktree_path_for existing)" ]
  [ "$(branch_of "$output")" = "existing" ]
  [ "$(head_of "$output")" = "$existing_head" ]
}

@test "replaces a slash in the branch name with a dash" {
  create_checkout "$REPO"

  run_in_checkout feature/x

  [ "$status" -eq 0 ]
  [ "$output" = "$(worktree_path_for feature-x)" ]
  [ "$(branch_of "$output")" = "feature/x" ]
}

@test "creates a worktree for a repository at four levels" {
  create_checkout gitlab.com/group/subgroup/widget

  run_in "$GHQ_ROOT/gitlab.com/group/subgroup/widget" fix/bug

  [ "$status" -eq 0 ]
  [ "$output" = "$GHQ_ROOT/worktrees/gitlab.com/group/subgroup/widget/fix-bug" ]
  [ -d "$output" ]
}

@test "fails when another branch maps to the same directory name" {
  create_checkout "$REPO"
  run_in_checkout feature/x
  [ "$status" -eq 0 ]

  run_in_checkout feature-x

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"feature-x"* ]]
  [[ "$stderr" == *"another branch"* ]]
  [ "$(branch_of "$(worktree_path_for feature-x)")" = "feature/x" ]
}

@test "fails for the reverse collision" {
  create_checkout "$REPO"
  run_in_checkout feature-x
  [ "$status" -eq 0 ]

  run_in_checkout feature/x

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"another branch"* ]]
}

@test "creates the branch from the start point" {
  create_checkout "$REPO"
  commit_on "$GHQ_ROOT/$REPO" release "release commit"
  local release_head
  release_head=$(head_of "$GHQ_ROOT/$REPO")
  git -C "$GHQ_ROOT/$REPO" switch -q main

  run_in_checkout feature release

  [ "$status" -eq 0 ]
  [ "$(head_of "$output")" = "$release_head" ]
}

@test "defaults the start point to origin/HEAD" {
  create_checkout "$REPO"
  local checkout="$GHQ_ROOT/$REPO"
  git init -q --bare "$BATS_TEST_TMPDIR/origin.git"
  git -C "$checkout" remote add origin "$BATS_TEST_TMPDIR/origin.git"
  commit_on "$checkout" develop "develop commit"
  git -C "$checkout" push -q origin develop
  git -C "$checkout" remote set-head origin develop
  local develop_head
  develop_head=$(head_of "$checkout")
  git -C "$checkout" switch -q main

  run_in_checkout feature

  [ "$status" -eq 0 ]
  [ "$(head_of "$output")" = "$develop_head" ]
}

@test "falls back to main when origin/HEAD is missing" {
  create_checkout "$REPO"
  local checkout="$GHQ_ROOT/$REPO"
  local main_head
  main_head=$(head_of "$checkout")
  commit_on "$checkout" other "other commit"

  run_in_checkout feature

  [ "$status" -eq 0 ]
  [ "$(head_of "$output")" = "$main_head" ]
}

add_origin() {
  local checkout=$1
  git init -q --bare "$BATS_TEST_TMPDIR/origin.git"
  git -C "$checkout" remote add origin "$BATS_TEST_TMPDIR/origin.git"
  git -C "$checkout" push -q origin main
  git -C "$checkout" remote set-head origin main
}

@test "checks out a branch that exists only on origin and tracks it" {
  create_checkout "$REPO"
  local checkout="$GHQ_ROOT/$REPO"
  add_origin "$checkout"
  commit_on "$checkout" remote-only "remote commit"
  git -C "$checkout" push -q origin remote-only
  local remote_head main_head
  remote_head=$(head_of "$checkout")
  git -C "$checkout" switch -q main
  main_head=$(head_of "$checkout")
  git -C "$checkout" branch -q -D remote-only

  run_in_checkout remote-only

  [ "$status" -eq 0 ]
  [ "$(branch_of "$output")" = "remote-only" ]
  [ "$(head_of "$output")" = "$remote_head" ]
  [ "$(head_of "$output")" != "$main_head" ]
  [ "$(git -C "$output" rev-parse --abbrev-ref remote-only@{upstream})" = "origin/remote-only" ]
}

@test "does not set an upstream on a new branch" {
  create_checkout "$REPO"
  local checkout="$GHQ_ROOT/$REPO"
  add_origin "$checkout"

  run_in_checkout feature

  [ "$status" -eq 0 ]
  [ "$(head_of "$output")" = "$(head_of "$checkout")" ]
  run ! git -C "$output" rev-parse --abbrev-ref feature@{upstream}
}

@test "falls back to the current HEAD when there is no main and no origin" {
  local checkout="$GHQ_ROOT/$REPO"
  git init -q -b master "$checkout"
  git -C "$checkout" config user.name "Test User"
  git -C "$checkout" config user.email "test@example.com"
  git -C "$checkout" config commit.gpgsign false
  git -C "$checkout" commit -q --allow-empty -m "initial"

  run_in_checkout feature

  [ "$status" -eq 0 ]
  [ "$(head_of "$output")" = "$(head_of "$checkout")" ]
}

@test "leaves no directory behind when git fails" {
  create_checkout "$REPO"

  run_in_checkout feature no-such-start-point

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ ! -e "$GHQ_ROOT/worktrees" ]
}

@test "keeps existing sibling worktrees when a later run fails" {
  create_checkout "$REPO"
  run_in_checkout first
  [ "$status" -eq 0 ]

  run_in_checkout second no-such-start-point

  [ "$status" -ne 0 ]
  [ -d "$(worktree_path_for first)" ]
  [ ! -e "$(worktree_path_for second)" ]
}

@test "works when run from a worktree" {
  create_checkout "$REPO"
  run_in_checkout feature/one
  [ "$status" -eq 0 ]

  run_in "$(worktree_path_for feature-one)" feature/two

  [ "$status" -eq 0 ]
  [ "$output" = "$(worktree_path_for feature-two)" ]
  [ "$(branch_of "$output")" = "feature/two" ]
}

@test "works when run from a subdirectory of a checkout" {
  create_checkout "$REPO"
  mkdir -p "$GHQ_ROOT/$REPO/src/deep"

  run_in "$GHQ_ROOT/$REPO/src/deep" feature

  [ "$status" -eq 0 ]
  [ "$output" = "$(worktree_path_for feature)" ]
}

@test "fails outside the ghq root" {
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
  git init -q "$BATS_TEST_TMPDIR/elsewhere"

  run_in "$BATS_TEST_TMPDIR/elsewhere" feature

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"outside"* ]]
  [ ! -e "$GHQ_ROOT/worktrees" ]
}

@test "fails when run from inside the notes root" {
  create_checkout "$REPO"
  mkdir -p "$NOTES_ROOT/$REPO/plans"
  touch "$NOTES_ROOT/$REPO/.plans-vault"

  run_in "$NOTES_ROOT/$REPO/plans" feature

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"notes root"* ]]
  [[ "$stderr" == *"checkout or worktree"* ]]
  [ ! -e "$GHQ_ROOT/worktrees" ]
}

@test "fails when run from the notes folder itself" {
  create_checkout "$REPO"
  mkdir -p "$NOTES_ROOT/$REPO"
  touch "$NOTES_ROOT/$REPO/.plans-vault"

  run_in "$NOTES_ROOT/$REPO" feature

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"notes root"* ]]
  [ ! -e "$GHQ_ROOT/worktrees" ]
}

@test "fails when run from the notes root without a marker" {
  create_checkout "$REPO"
  mkdir -p "$NOTES_ROOT"

  run_in "$NOTES_ROOT" feature

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ ! -e "$GHQ_ROOT/worktrees" ]
}

@test "fails when run from inside the vault but outside the notes root" {
  create_checkout "$REPO"
  mkdir -p "$VAULT/daily"

  run_in "$VAULT/daily" feature

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"notes root"* ]]
  [ ! -e "$GHQ_ROOT/worktrees" ]
}

@test "fails inside a custom subfolder" {
  create_checkout "$REPO"
  write_config "vault=$VAULT" "subfolder=repo-notes"
  mkdir -p "$VAULT/repo-notes/$REPO/plans"
  touch "$VAULT/repo-notes/$REPO/.plans-vault"

  run_in "$VAULT/repo-notes/$REPO/plans" feature

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"notes root"* ]]
  [ ! -e "$GHQ_ROOT/worktrees" ]
}

@test "reads plans from a custom subfolder when removing" {
  create_checkout "$REPO"
  write_config "vault=$VAULT" "subfolder=repo-notes"
  run_in_checkout feature/x
  mkdir -p "$VAULT/repo-notes/$REPO/plans"
  printf -- '---\nbranch: feature/x\n---\n' >"$VAULT/repo-notes/$REPO/plans/2026-01-01-login.md"

  run_in_checkout --remove feature/x

  [ "$status" -eq 0 ]
  [[ "$stderr" == *"$VAULT/repo-notes/$REPO/plans/2026-01-01-login.md"* ]]
}

@test "fails and points to install when the config file is missing" {
  create_checkout "$REPO"
  rm "$OBSIDIAN_PLANS_CONFIG_DIR/config"

  run_in_checkout feature

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"install --vault <dir>"* ]]
  [ ! -e "$GHQ_ROOT/worktrees" ]
}

@test "does not touch the obsidian folder" {
  create_checkout "$REPO"
  echo '{"keep":true}' >"$VAULT/.obsidian/app.json"

  run_in_checkout feature
  [ "$status" -eq 0 ]
  run_in_checkout --remove feature
  [ "$status" -eq 0 ]

  [ "$(find "$VAULT/.obsidian" | sort)" = "$(printf '%s\n' "$VAULT/.obsidian" "$VAULT/.obsidian/app.json")" ]
  [ "$(cat "$VAULT/.obsidian/app.json")" = '{"keep":true}' ]
}

@test "prints only the worktree path on stdout" {
  create_checkout "$REPO"

  run_in_checkout feature

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "$output" = "$(worktree_path_for feature)" ]
}

@test "prints only the worktree path when the branch already exists" {
  create_checkout "$REPO"
  git -C "$GHQ_ROOT/$REPO" branch existing

  run_in_checkout existing

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "$output" = "$(worktree_path_for existing)" ]
}

@test "prints the same path when the worktree already exists for the branch" {
  create_checkout "$REPO"
  run_in_checkout feature/x
  local first=$output

  run_in_checkout feature/x

  [ "$status" -eq 0 ]
  [ "$output" = "$first" ]
}

@test "fails without arguments" {
  create_checkout "$REPO"

  run_in_checkout

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"usage"* ]]
}

@test "fails on an invalid branch name" {
  create_checkout "$REPO"

  run_in_checkout "bad..name"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"not a valid branch name"* ]]
}

@test "removes a worktree" {
  create_checkout "$REPO"
  run_in_checkout feature/x
  local worktree=$output

  run_in_checkout --remove feature/x

  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ -z "$stderr" ]
  [ ! -e "$worktree" ]
  git -C "$GHQ_ROOT/$REPO" show-ref --verify --quiet refs/heads/feature/x
}

@test "removes a worktree when run from another worktree" {
  create_checkout "$REPO"
  run_in_checkout feature/one
  run_in_checkout feature/two
  local second=$output

  run_in "$(worktree_path_for feature-one)" --remove feature/two

  [ "$status" -eq 0 ]
  [ ! -e "$second" ]
}

@test "warns and keeps the plan when removing a branch with a matching plan" {
  create_checkout "$REPO"
  run_in_checkout feature/x
  write_plan 2026-01-01-login feature/x
  local plan="$NOTES_ROOT/$REPO/plans/2026-01-01-login.md"
  local before
  before=$(cat "$plan")

  run_in_checkout --remove feature/x

  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"warning"* ]]
  [[ "$stderr" == *"$plan"* ]]
  [ ! -e "$(worktree_path_for feature-x)" ]
  [ "$(cat "$plan")" = "$before" ]
  [ -f "$NOTES_ROOT/$REPO/.plans-vault" ]
}

@test "does not warn about a plan for a different branch" {
  create_checkout "$REPO"
  run_in_checkout feature/x
  write_plan 2026-01-01-other feature/y

  run_in_checkout --remove feature/x

  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
}

@test "does not warn when the branch appears only in the plan body" {
  create_checkout "$REPO"
  run_in_checkout feature/x
  printf -- '---\nbranch: other\n---\n\nbranch: feature/x\n' \
    >"$NOTES_ROOT/$REPO/plans/2026-01-01-body.md"

  run_in_checkout --remove feature/x

  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
}

write_marked_plan() {
  local name=$1 branch=$2
  mkdir -p "$NOTES_ROOT/$REPO/plans"
  printf -- '---\nbranch: %s\nmarked-for-deletion: 2026-01-02\n---\n\n# Goal\n' "$branch" \
    >"$NOTES_ROOT/$REPO/plans/$name.md"
}

@test "does not warn about a plan marked for deletion" {
  create_checkout "$REPO"
  run_in_checkout feature/x
  write_marked_plan 2026-01-01-login feature/x

  run_in_checkout --remove feature/x

  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
}

@test "still warns about an unmarked plan next to a marked plan" {
  create_checkout "$REPO"
  run_in_checkout feature/x
  write_marked_plan 2026-01-01-marked feature/x
  write_plan 2026-01-02-unmarked feature/x

  run_in_checkout --remove feature/x

  [ "$status" -eq 0 ]
  [ "${#stderr_lines[@]}" -eq 1 ]
  [[ "$stderr" == *"2026-01-02-unmarked.md"* ]]
  [[ "$stderr" != *"2026-01-01-marked.md"* ]]
}

@test "still warns when the marked-for-deletion text appears only in the plan body" {
  create_checkout "$REPO"
  run_in_checkout feature/x
  printf -- '---\nbranch: feature/x\n---\n\nmarked-for-deletion: yes\n' \
    >"$NOTES_ROOT/$REPO/plans/2026-01-01-body.md"

  run_in_checkout --remove feature/x

  [ "$status" -eq 0 ]
  [[ "$stderr" == *"2026-01-01-body.md"* ]]
}

@test "fails to remove an unknown branch" {
  create_checkout "$REPO"

  run_in_checkout --remove nope

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"nope"* ]]
}

@test "fails to remove a branch whose directory belongs to another branch" {
  create_checkout "$REPO"
  run_in_checkout feature/x

  run_in_checkout --remove feature-x

  [ "$status" -ne 0 ]
  [ -d "$(worktree_path_for feature-x)" ]
}

@test "fails to remove without a branch" {
  create_checkout "$REPO"

  run_in_checkout --remove

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"usage"* ]]
}

install_git_spy() {
  local spy_dir="$BATS_TEST_TMPDIR/spy-bin"
  GIT_SPY_LOG="$BATS_TEST_TMPDIR/git-calls.log"
  mkdir -p "$spy_dir"
  printf '#!/usr/bin/env bash\nprintf "%%s\\t%%s\\n" "$PWD" "$*" >>"%s"\nexec "%s" "$@"\n' \
    "$GIT_SPY_LOG" "$(command -v git)" >"$spy_dir/git"
  chmod +x "$spy_dir/git"
  export PATH="$spy_dir:$PATH"
  : >"$GIT_SPY_LOG"
}

assert_no_git_call_in() {
  local dir=$1
  ! awk -F '\t' -v dir="$dir" '$1 == dir || index($1, dir "/") == 1 { found = 1 } END { exit !found }' "$GIT_SPY_LOG"
}

@test "never runs git in the notes folder" {
  create_checkout "$REPO"
  mkdir -p "$NOTES_ROOT/$REPO/plans"
  touch "$NOTES_ROOT/$REPO/.plans-vault"
  install_git_spy

  run_in "$NOTES_ROOT/$REPO/plans" feature

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ "${#stderr_lines[@]}" -eq 1 ]
  [[ "$stderr" == *"inside the notes root"* ]]
  assert_no_git_call_in "$VAULT"
}

@test "never runs git in the notes folder when the branch name is invalid" {
  create_checkout "$REPO"
  mkdir -p "$NOTES_ROOT/$REPO/plans"
  touch "$NOTES_ROOT/$REPO/.plans-vault"
  install_git_spy

  run_in "$NOTES_ROOT/$REPO/plans" "bad..name"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"inside the notes root"* ]]
  assert_no_git_call_in "$VAULT"
}

@test "never runs git in the notes folder when removing a worktree" {
  create_checkout "$REPO"
  mkdir -p "$NOTES_ROOT/$REPO"
  touch "$NOTES_ROOT/$REPO/.plans-vault"
  install_git_spy

  run_in "$NOTES_ROOT/$REPO" --remove feature

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"inside the notes root"* ]]
  assert_no_git_call_in "$VAULT"
}

@test "checks the branch name against the repository" {
  create_checkout "$REPO"
  install_git_spy

  run_in_checkout feature

  [ "$status" -eq 0 ]
  rg --quiet --fixed-strings -- "-C $GHQ_ROOT/$REPO check-ref-format --branch feature" "$GIT_SPY_LOG"
}

@test "fails inside a notes root that is a symlink" {
  create_checkout "$REPO"
  mkdir -p "$BATS_TEST_TMPDIR/real-notes/$REPO/plans"
  touch "$BATS_TEST_TMPDIR/real-notes/$REPO/.plans-vault"
  ln -s "$BATS_TEST_TMPDIR/real-notes" "$NOTES_ROOT"

  run_in "$NOTES_ROOT/$REPO/plans" feature

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"inside the notes root"* ]]
  [ ! -e "$GHQ_ROOT/worktrees" ]
}

@test "creates and removes a worktree when the worktrees directory is a symlink" {
  create_checkout "$REPO"
  mkdir -p "$BATS_TEST_TMPDIR/real-worktrees"
  ln -s "$BATS_TEST_TMPDIR/real-worktrees" "$GHQ_ROOT/worktrees"

  run_in_checkout feature/x

  [ "$status" -eq 0 ]
  [ "$output" = "$(worktree_path_for feature-x)" ]
  [ -d "$BATS_TEST_TMPDIR/real-worktrees/$REPO/feature-x" ]

  run_in_checkout --remove feature/x

  [ "$status" -eq 0 ]
  [ ! -e "$(worktree_path_for feature-x)" ]
}
