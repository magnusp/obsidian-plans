#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

PLANS_RESOLVE="$BATS_TEST_DIRNAME/../bin/plans-resolve"
PLANS_WORKTREE="$BATS_TEST_DIRNAME/../bin/plans-worktree"

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

create_worktree() {
  local relative_repo=$1 branch=$2
  local worktree="$GHQ_ROOT/worktrees/$relative_repo/${branch//\//-}"
  mkdir -p "$(dirname "$worktree")"
  git -C "$GHQ_ROOT/$relative_repo" worktree add -q -b "$branch" "$worktree"
}

resolve_in() {
  cd "$1"
  run --separate-stderr "$PLANS_RESOLVE"
}

output_value() {
  local key=$1
  printf '%s\n' "$output" | sed -n "s/^$key=//p"
}

@test "resolves a checkout" {
  create_checkout github.com/acme/widget

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value repo)" = "$GHQ_ROOT/github.com/acme/widget" ]
  [ "$(output_value vault)" = "$VAULT" ]
  [ "$(output_value notes)" = "$NOTES_ROOT/github.com/acme/widget" ]
  [ -z "$(output_value worktree)" ]
}

@test "prints the keys in a fixed order" {
  create_checkout github.com/acme/widget
  create_worktree github.com/acme/widget feature/login

  resolve_in "$GHQ_ROOT/worktrees/github.com/acme/widget/feature-login"

  [ "${lines[0]%%=*}" = "repo" ]
  [ "${lines[1]%%=*}" = "vault" ]
  [ "${lines[2]%%=*}" = "notes" ]
  [ "${lines[3]%%=*}" = "worktree" ]
  [ "${#lines[@]}" -eq 4 ]
}

@test "resolves from a subdirectory of a checkout" {
  create_checkout github.com/acme/widget
  mkdir -p "$GHQ_ROOT/github.com/acme/widget/src/deep"

  resolve_in "$GHQ_ROOT/github.com/acme/widget/src/deep"

  [ "$status" -eq 0 ]
  [ "$(output_value repo)" = "$GHQ_ROOT/github.com/acme/widget" ]
}

@test "creates the notes folder with marker, inbox, plans, and index" {
  create_checkout github.com/acme/widget

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  local notes="$NOTES_ROOT/github.com/acme/widget"
  [ -f "$notes/.plans-vault" ]
  [ ! -s "$notes/.plans-vault" ]
  [ -d "$notes/inbox" ]
  [ -d "$notes/plans" ]
  [ -f "$notes/index.md" ]
}

@test "writes an index note with the repository path and two sentences" {
  create_checkout github.com/acme/widget

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  local index="$NOTES_ROOT/github.com/acme/widget/index.md"
  [ "$(sed -n 1p "$index")" = "# github.com/acme/widget" ]
  [ -z "$(sed -n 2p "$index")" ]
  [[ "$(sed -n 3p "$index")" == *"inbox/"* ]]
  [[ "$(sed -n 4p "$index")" == *"plans/"* ]]
  [ "$(wc -l <"$index")" -eq 4 ]
}

@test "never overwrites an existing index note" {
  create_checkout github.com/acme/widget
  mkdir -p "$NOTES_ROOT/github.com/acme/widget"
  echo "my own index" >"$NOTES_ROOT/github.com/acme/widget/index.md"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(cat "$NOTES_ROOT/github.com/acme/widget/index.md")" = "my own index" ]
}

@test "creates the notes root when it does not exist" {
  create_checkout github.com/acme/widget
  [ ! -e "$NOTES_ROOT" ]

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ -d "$NOTES_ROOT/github.com/acme/widget" ]
}

obsidian_snapshot() {
  (cd "$VAULT/.obsidian" && find . | sort && find . -type f -exec cksum {} +)
}

@test "never touches the obsidian folder" {
  create_checkout github.com/acme/widget
  echo '{"keep":true}' >"$VAULT/.obsidian/app.json"
  local before
  before=$(obsidian_snapshot)

  resolve_in "$GHQ_ROOT/github.com/acme/widget"
  [ "$status" -eq 0 ]
  resolve_in "$NOTES_ROOT/github.com/acme/widget/inbox"
  [ "$status" -eq 0 ]

  [ "$(obsidian_snapshot)" = "$before" ]
}

@test "never creates a git repository in the vault" {
  create_checkout github.com/acme/widget

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ ! -e "$VAULT/.git" ]
  [ ! -e "$NOTES_ROOT/.git" ]
  [ ! -e "$NOTES_ROOT/github.com/acme/widget/.git" ]
}

@test "resolves a worktree to the main checkout and prints the worktree" {
  create_checkout github.com/acme/widget
  create_worktree github.com/acme/widget feature/login

  resolve_in "$GHQ_ROOT/worktrees/github.com/acme/widget/feature-login"

  [ "$status" -eq 0 ]
  [ "$(output_value repo)" = "$GHQ_ROOT/github.com/acme/widget" ]
  [ "$(output_value vault)" = "$VAULT" ]
  [ "$(output_value notes)" = "$NOTES_ROOT/github.com/acme/widget" ]
  [ "$(output_value worktree)" = "$GHQ_ROOT/worktrees/github.com/acme/widget/feature-login" ]
}

@test "resolves from a subdirectory of a worktree" {
  create_checkout github.com/acme/widget
  create_worktree github.com/acme/widget feature/login
  local worktree="$GHQ_ROOT/worktrees/github.com/acme/widget/feature-login"
  mkdir -p "$worktree/src"

  resolve_in "$worktree/src"

  [ "$status" -eq 0 ]
  [ "$(output_value worktree)" = "$worktree" ]
}

@test "resolves a repository at two levels" {
  create_checkout example.com/widget

  resolve_in "$GHQ_ROOT/example.com/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value notes)" = "$NOTES_ROOT/example.com/widget" ]
  [ -f "$NOTES_ROOT/example.com/widget/.plans-vault" ]
}

@test "resolves a repository at three levels" {
  create_checkout github.com/acme/widget

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$(output_value notes)" = "$NOTES_ROOT/github.com/acme/widget" ]
}

@test "resolves a repository at four levels" {
  create_checkout gitlab.com/group/subgroup/widget
  create_worktree gitlab.com/group/subgroup/widget fix/bug

  resolve_in "$GHQ_ROOT/worktrees/gitlab.com/group/subgroup/widget/fix-bug"

  [ "$status" -eq 0 ]
  [ "$(output_value repo)" = "$GHQ_ROOT/gitlab.com/group/subgroup/widget" ]
  [ "$(output_value notes)" = "$NOTES_ROOT/gitlab.com/group/subgroup/widget" ]
}

@test "resolves from inside a notes folder" {
  create_checkout github.com/acme/widget
  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  resolve_in "$NOTES_ROOT/github.com/acme/widget/plans"

  [ "$status" -eq 0 ]
  [ "$(output_value repo)" = "$GHQ_ROOT/github.com/acme/widget" ]
  [ "$(output_value vault)" = "$VAULT" ]
  [ "$(output_value notes)" = "$NOTES_ROOT/github.com/acme/widget" ]
  [ -z "$(output_value worktree)" ]
}

@test "resolves from a nested directory inside a notes folder" {
  create_checkout gitlab.com/group/subgroup/widget
  resolve_in "$GHQ_ROOT/gitlab.com/group/subgroup/widget"
  mkdir -p "$NOTES_ROOT/gitlab.com/group/subgroup/widget/plans/archive"

  resolve_in "$NOTES_ROOT/gitlab.com/group/subgroup/widget/plans/archive"

  [ "$status" -eq 0 ]
  [ "$(output_value notes)" = "$NOTES_ROOT/gitlab.com/group/subgroup/widget" ]
}

@test "fails inside the notes root when no marker exists" {
  mkdir -p "$NOTES_ROOT/github.com/acme/orphan"

  resolve_in "$NOTES_ROOT/github.com/acme/orphan"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *".plans-vault"* ]]
}

@test "fails from the notes root itself" {
  mkdir -p "$NOTES_ROOT"

  resolve_in "$NOTES_ROOT"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *".plans-vault"* ]]
}

@test "fails for a path inside the vault but outside the notes root" {
  mkdir -p "$VAULT/daily"

  resolve_in "$VAULT/daily"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"outside the notes root"* ]]
  [ ! -e "$NOTES_ROOT" ]
}

@test "fails from the vault root itself" {
  resolve_in "$VAULT"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"outside the notes root"* ]]
  [ ! -e "$NOTES_ROOT" ]
}

@test "fails for a path outside all roots" {
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"

  resolve_in "$BATS_TEST_TMPDIR/elsewhere"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"outside"* ]]
}

@test "warns and exits 0 when the checkout is missing" {
  mkdir -p "$NOTES_ROOT/github.com/acme/gone"
  touch "$NOTES_ROOT/github.com/acme/gone/.plans-vault"

  resolve_in "$NOTES_ROOT/github.com/acme/gone"

  [ "$status" -eq 0 ]
  [ "$(output_value repo)" = "$GHQ_ROOT/github.com/acme/gone" ]
  [ "$(output_value notes)" = "$NOTES_ROOT/github.com/acme/gone" ]
  [[ "$stderr" == *"warning"* ]]
  [[ "$stderr" == *"$GHQ_ROOT/github.com/acme/gone"* ]]
}

@test "does not warn when the checkout exists" {
  create_checkout github.com/acme/widget

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ -z "$stderr" ]
}

@test "gives the same result when run twice" {
  create_checkout github.com/acme/widget

  resolve_in "$GHQ_ROOT/github.com/acme/widget"
  local first_output=$output first_status=$status
  local first_listing
  first_listing=$(cd "$VAULT" && find . | sort)

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq "$first_status" ]
  [ "$output" = "$first_output" ]
  [ "$(cd "$VAULT" && find . | sort)" = "$first_listing" ]
}

@test "keeps existing inbox and plan files on a second run" {
  create_checkout github.com/acme/widget
  resolve_in "$GHQ_ROOT/github.com/acme/widget"
  echo "keep" >"$NOTES_ROOT/github.com/acme/widget/inbox/item.md"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$(cat "$NOTES_ROOT/github.com/acme/widget/inbox/item.md")" = "keep" ]
}

@test "fails for a checkout only one level below the ghq root" {
  create_checkout scratch

  resolve_in "$GHQ_ROOT/scratch"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"two"* ]]
  [ ! -e "$NOTES_ROOT/scratch" ]
}

@test "fails for a notes folder only one level below the notes root" {
  mkdir -p "$NOTES_ROOT/scratch"
  touch "$NOTES_ROOT/scratch/.plans-vault"

  resolve_in "$NOTES_ROOT/scratch"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"two"* ]]
}

@test "fails in a git submodule" {
  create_checkout github.com/acme/library
  create_checkout github.com/acme/widget
  git -C "$GHQ_ROOT/github.com/acme/widget" -c protocol.file.allow=always \
    submodule add -q "$GHQ_ROOT/github.com/acme/library" vendor/library

  resolve_in "$GHQ_ROOT/github.com/acme/widget/vendor/library"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ "${#stderr_lines[@]}" -eq 1 ]
  [[ "$stderr" == "plans-resolve: "*"submodule"* ]]
  [ ! -e "$NOTES_ROOT/github.com/acme/widget/vendor" ]
}

@test "ignores comments and blank lines in the config" {
  create_checkout github.com/acme/widget
  write_config "# a comment" "" "#vault=/nowhere" "vault=$VAULT" "   # indented comment"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$VAULT" ]
}

@test "trims spaces around the key and the value" {
  create_checkout github.com/acme/widget
  write_config "  vault  =   $VAULT   " "	subfolder =  notes  "

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$VAULT" ]
  [ "$(output_value notes)" = "$VAULT/notes/github.com/acme/widget" ]
}

@test "expands a leading tilde in the vault to home" {
  create_checkout github.com/acme/widget
  mkdir -p "$HOME/my vault/.obsidian"
  write_config "vault=~/my vault"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$HOME/my vault" ]
}

@test "does not expand a tilde that is not leading" {
  create_checkout github.com/acme/widget
  write_config "vault=$VAULT/~"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"$VAULT/~"* ]]
}

@test "uses a custom subfolder" {
  create_checkout github.com/acme/widget
  write_config "vault=$VAULT" "subfolder=repo-notes"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value notes)" = "$VAULT/repo-notes/github.com/acme/widget" ]
  [ -f "$VAULT/repo-notes/github.com/acme/widget/.plans-vault" ]
  [ ! -e "$NOTES_ROOT" ]
}

@test "resolves from inside a custom subfolder" {
  create_checkout github.com/acme/widget
  write_config "vault=$VAULT" "subfolder=repo-notes"
  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  resolve_in "$VAULT/repo-notes/github.com/acme/widget/inbox"

  [ "$status" -eq 0 ]
  [ "$(output_value repo)" = "$GHQ_ROOT/github.com/acme/widget" ]
}

@test "defaults the subfolder to obsidian-plans" {
  create_checkout github.com/acme/widget

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$(output_value notes)" = "$VAULT/obsidian-plans/github.com/acme/widget" ]
}

@test "does not execute the config file" {
  create_checkout github.com/acme/widget
  write_config "vault=$VAULT" "touch $BATS_TEST_TMPDIR/executed" "\$(touch $BATS_TEST_TMPDIR/executed)=1"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ ! -e "$BATS_TEST_TMPDIR/executed" ]
}

@test "uses the last value when a key repeats" {
  create_checkout github.com/acme/widget
  write_config "subfolder=first" "vault=$VAULT" "subfolder=second"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$(output_value notes)" = "$VAULT/second/github.com/acme/widget" ]
}

@test "reads the config from the XDG config home when no override is set" {
  create_checkout github.com/acme/widget
  unset OBSIDIAN_PLANS_CONFIG_DIR
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/xdg"
  mkdir -p "$XDG_CONFIG_HOME/obsidian-plans"
  echo "vault=$VAULT" >"$XDG_CONFIG_HOME/obsidian-plans/config"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$VAULT" ]
}

@test "reads the config from the home config folder when nothing else is set" {
  create_checkout github.com/acme/widget
  unset OBSIDIAN_PLANS_CONFIG_DIR XDG_CONFIG_HOME
  mkdir -p "$HOME/.config/obsidian-plans"
  echo "vault=$VAULT" >"$HOME/.config/obsidian-plans/config"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$VAULT" ]
}

assert_config_failure() {
  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"install --vault <dir>"* ]]
  [ ! -e "$NOTES_ROOT" ]
  [ ! -e "$VAULT/.plans-vault" ]
}

@test "fails and points to install when the config file is missing" {
  create_checkout github.com/acme/widget
  rm "$OBSIDIAN_PLANS_CONFIG_DIR/config"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  assert_config_failure
  [[ "$stderr" == *"$OBSIDIAN_PLANS_CONFIG_DIR/config"* ]]
}

@test "fails and points to install when vault is missing" {
  create_checkout github.com/acme/widget
  write_config "subfolder=notes"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  assert_config_failure
  [[ "$stderr" == *"vault is missing"* ]]
}

@test "fails and points to install when vault is empty" {
  create_checkout github.com/acme/widget
  write_config "vault="

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  assert_config_failure
  [[ "$stderr" == *"vault is missing"* ]]
}

@test "fails and points to install when vault is not an existing directory" {
  create_checkout github.com/acme/widget
  write_config "vault=$BATS_TEST_TMPDIR/no-such-vault"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  assert_config_failure
  [[ "$stderr" == *"not an existing directory"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/no-such-vault" ]
}

@test "fails and points to install when vault is a file" {
  create_checkout github.com/acme/widget
  touch "$BATS_TEST_TMPDIR/a-file"
  write_config "vault=$BATS_TEST_TMPDIR/a-file"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  assert_config_failure
  [[ "$stderr" == *"not an existing directory"* ]]
}

@test "fails and points to install when the vault has no obsidian folder" {
  create_checkout github.com/acme/widget
  mkdir -p "$BATS_TEST_TMPDIR/plain"
  write_config "vault=$BATS_TEST_TMPDIR/plain"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  assert_config_failure
  [[ "$stderr" == *".obsidian"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/plain/.obsidian" ]
  [ ! -e "$BATS_TEST_TMPDIR/plain/obsidian-plans" ]
}

@test "fails and points to install when subfolder is empty" {
  create_checkout github.com/acme/widget
  write_config "vault=$VAULT" "subfolder="

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  assert_config_failure
  [[ "$stderr" == *"subfolder"* ]]
}

@test "fails and points to install when subfolder is a dot folder" {
  create_checkout github.com/acme/widget

  for name in . ..; do
    write_config "vault=$VAULT" "subfolder=$name"

    resolve_in "$GHQ_ROOT/github.com/acme/widget"

    assert_config_failure
    [[ "$stderr" == *"subfolder"* ]]
  done
}

@test "fails and points to install when vault is a relative path" {
  create_checkout github.com/acme/widget
  write_config "vault=relative/vault"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  assert_config_failure
  [[ "$stderr" == *"absolute"* ]]
}

@test "fails and points to install when subfolder contains a slash" {
  create_checkout github.com/acme/widget
  write_config "vault=$VAULT" "subfolder=deep/notes"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  assert_config_failure
  [[ "$stderr" == *"subfolder"* ]]
  [ ! -e "$VAULT/deep" ]
}

@test "reports a config failure even when run outside all roots" {
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
  rm "$OBSIDIAN_PLANS_CONFIG_DIR/config"

  resolve_in "$BATS_TEST_TMPDIR/elsewhere"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"install --vault <dir>"* ]]
}

sandbox_dir() {
  dirname "$VAULT"
}

@test "resolves from inside a notes folder when the subfolder is a symlink" {
  create_checkout github.com/acme/widget
  mkdir -p "$(sandbox_dir)/real-notes"
  ln -s "$(sandbox_dir)/real-notes" "$NOTES_ROOT"
  resolve_in "$GHQ_ROOT/github.com/acme/widget"
  [ "$status" -eq 0 ]

  resolve_in "$NOTES_ROOT/github.com/acme/widget/plans"

  [ "$status" -eq 0 ]
  [ "$(output_value repo)" = "$GHQ_ROOT/github.com/acme/widget" ]
  [ "$(output_value vault)" = "$VAULT" ]
  [ "$(output_value notes)" = "$NOTES_ROOT/github.com/acme/widget" ]
  [ -f "$(sandbox_dir)/real-notes/github.com/acme/widget/.plans-vault" ]
}

@test "resolves from inside a notes folder when the vault is a symlink" {
  create_checkout github.com/acme/widget
  local link="$(sandbox_dir)/vault-link"
  ln -s "$VAULT" "$link"
  write_config "vault=$link"
  resolve_in "$GHQ_ROOT/github.com/acme/widget"
  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$link" ]
  [ "$(output_value notes)" = "$link/obsidian-plans/github.com/acme/widget" ]

  resolve_in "$NOTES_ROOT/github.com/acme/widget/inbox"

  [ "$status" -eq 0 ]
  [ "$(output_value repo)" = "$GHQ_ROOT/github.com/acme/widget" ]
  [ "$(output_value vault)" = "$link" ]
  [ "$(output_value notes)" = "$link/obsidian-plans/github.com/acme/widget" ]
}

@test "fails for a path inside the vault but outside the notes root when the vault is a symlink" {
  local link="$(sandbox_dir)/vault-link"
  ln -s "$VAULT" "$link"
  write_config "vault=$link"
  mkdir -p "$VAULT/daily"

  resolve_in "$link/daily"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"outside the notes root"* ]]
}

@test "resolves from inside a worktree when the worktrees directory is a symlink" {
  create_checkout github.com/acme/widget
  mkdir -p "$(sandbox_dir)/real-worktrees"
  ln -s "$(sandbox_dir)/real-worktrees" "$GHQ_ROOT/worktrees"
  cd "$GHQ_ROOT/github.com/acme/widget"
  run --separate-stderr "$PLANS_WORKTREE" feature/login
  [ "$status" -eq 0 ]
  local worktree=$output
  [ "$worktree" = "$GHQ_ROOT/worktrees/github.com/acme/widget/feature-login" ]

  resolve_in "$worktree"

  [ "$status" -eq 0 ]
  [ "$(output_value repo)" = "$GHQ_ROOT/github.com/acme/widget" ]
  [ "$(output_value notes)" = "$NOTES_ROOT/github.com/acme/widget" ]
  [ "$(output_value worktree)" = "$worktree" ]
}

@test "resolves from a subdirectory of a worktree when the worktrees directory is a symlink" {
  create_checkout github.com/acme/widget
  mkdir -p "$(sandbox_dir)/real-worktrees"
  ln -s "$(sandbox_dir)/real-worktrees" "$GHQ_ROOT/worktrees"
  cd "$GHQ_ROOT/github.com/acme/widget"
  run --separate-stderr "$PLANS_WORKTREE" feature/login
  [ "$status" -eq 0 ]
  local worktree=$output
  mkdir -p "$worktree/src"

  resolve_in "$worktree/src"

  [ "$status" -eq 0 ]
  [ "$(output_value worktree)" = "$worktree" ]
}

assert_single_error_line() {
  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ "${#stderr_lines[@]}" -eq 1 ]
  [[ "$stderr" == "plans-resolve: "* ]]
  [[ "$stderr" != *"fatal:"* ]]
}

@test "fails once when a directory under the ghq root is not a git repository" {
  mkdir -p "$GHQ_ROOT/github.com/acme/plain"

  resolve_in "$GHQ_ROOT/github.com/acme/plain"

  assert_single_error_line
  [[ "$stderr" == *"not inside a git repository"* ]]
  [ ! -e "$NOTES_ROOT/github.com" ]
}

@test "fails once when a directory under the worktrees root is not a git repository" {
  mkdir -p "$GHQ_ROOT/worktrees/github.com/acme/plain/feature"

  resolve_in "$GHQ_ROOT/worktrees/github.com/acme/plain/feature"

  assert_single_error_line
  [[ "$stderr" == *"not inside a git repository"* ]]
  [ ! -e "$NOTES_ROOT/github.com" ]
}

@test "fails once in a bare repository" {
  git init -q --bare "$GHQ_ROOT/github.com/acme/bare.git"

  resolve_in "$GHQ_ROOT/github.com/acme/bare.git"

  assert_single_error_line
  [[ "$stderr" == *"bare"* ]]
  [ ! -e "$NOTES_ROOT/github.com" ]
}

@test "fails once in a submodule of a worktree" {
  create_checkout github.com/acme/library
  create_checkout github.com/acme/widget
  create_worktree github.com/acme/widget feature/login
  local worktree="$GHQ_ROOT/worktrees/github.com/acme/widget/feature-login"
  git -C "$worktree" -c protocol.file.allow=always \
    submodule add -q "$GHQ_ROOT/github.com/acme/library" vendor/library

  resolve_in "$worktree/vendor/library"

  assert_single_error_line
  [[ "$stderr" == *"submodule"* ]]
}

@test "fails and points to install when HOME is unset and no config dir is set" {
  create_checkout github.com/acme/widget
  unset HOME OBSIDIAN_PLANS_CONFIG_DIR XDG_CONFIG_HOME

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ "${#stderr_lines[@]}" -eq 1 ]
  [[ "$stderr" == "plans-resolve: "*"HOME"*"Run install --vault <dir>" ]]
  [[ "$stderr" != *"unbound"* ]]
}

@test "fails and points to install when the vault starts with a tilde and HOME is unset" {
  create_checkout github.com/acme/widget
  write_config "vault=~/vault"
  unset HOME

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ "${#stderr_lines[@]}" -eq 1 ]
  [[ "$stderr" == "plans-resolve: "*"HOME"*"Run install --vault <dir>" ]]
  [[ "$stderr" != *"unbound"* ]]
}

@test "works with HOME unset when a config dir is set" {
  create_checkout github.com/acme/widget
  unset HOME

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$VAULT" ]
}

@test "removes double quotes around the vault" {
  create_checkout github.com/acme/widget
  mkdir -p "$(sandbox_dir)/My Vault/.obsidian"
  write_config "vault=\"$(sandbox_dir)/My Vault\""

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$(sandbox_dir)/My Vault" ]
  [ "$(output_value notes)" = "$(sandbox_dir)/My Vault/obsidian-plans/github.com/acme/widget" ]
}

@test "removes single quotes around the vault and the subfolder" {
  create_checkout github.com/acme/widget
  write_config "vault='$VAULT'" "subfolder = 'quoted notes'"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$VAULT" ]
  [ "$(output_value notes)" = "$VAULT/quoted notes/github.com/acme/widget" ]
}

@test "removes quotes before it expands a leading tilde" {
  create_checkout github.com/acme/widget
  mkdir -p "$HOME/my vault/.obsidian"
  write_config "vault=\"~/my vault\""

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$HOME/my vault" ]
}

@test "keeps quotes that do not match" {
  create_checkout github.com/acme/widget
  write_config "vault=\"$VAULT'"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"absolute"* ]]
}

@test "removes only one pair of quotes" {
  create_checkout github.com/acme/widget
  write_config "vault=\"'$VAULT'\""

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"absolute"* ]]
}

@test "ignores a byte-order mark at the start of the config" {
  create_checkout github.com/acme/widget
  printf '\xEF\xBB\xBFvault=%s\nsubfolder=bom-notes\n' "$VAULT" >"$OBSIDIAN_PLANS_CONFIG_DIR/config"

  resolve_in "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(output_value vault)" = "$VAULT" ]
  [ "$(output_value notes)" = "$VAULT/bom-notes/github.com/acme/widget" ]
}
