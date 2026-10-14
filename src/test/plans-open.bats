#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

PLANS_OPEN="$BATS_TEST_DIRNAME/../bin/plans-open"
UNKNOWN_VAULT_LINE="plans-open: Open the vault once in Obsidian, then run plans-open again."

setup() {
  local sandbox
  sandbox=$(cd "$BATS_TEST_TMPDIR" && pwd -P)
  export HOME="$sandbox/home"
  export GHQ_ROOT="$sandbox/ghq"
  export OBSIDIAN_PLANS_CONFIG_DIR="$sandbox/plans-config"
  export OBSIDIAN_CONFIG_DIR="$sandbox/obsidian-config"
  export PLANS_OPEN_COMMAND="$sandbox/fake-opener"
  VAULT="$sandbox/vault"
  NOTES_ROOT="$VAULT/obsidian-plans"
  OPENED_FILE="$sandbox/opened"
  mkdir -p "$HOME" "$GHQ_ROOT" "$OBSIDIAN_CONFIG_DIR" "$VAULT/.obsidian"
  write_plans_config "$VAULT"
  create_fake_opener
}

write_plans_config() {
  mkdir -p "$OBSIDIAN_PLANS_CONFIG_DIR"
  printf 'vault=%s\n' "$1" >"$OBSIDIAN_PLANS_CONFIG_DIR/config"
}

create_fake_opener() {
  printf '#!/usr/bin/env bash\necho "noise on stdout"\necho "$1" >>"%s"\n' "$OPENED_FILE" \
    >"$PLANS_OPEN_COMMAND"
  chmod +x "$PLANS_OPEN_COMMAND"
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

notes_of() {
  echo "$NOTES_ROOT/$1"
}

config_file() {
  echo "$OBSIDIAN_CONFIG_DIR/obsidian.json"
}

register_vault() {
  printf '{"vaults":{"aaaaaaaaaaaaaaaa":{"path":"%s","ts":1}}}\n' "$1" >"$(config_file)"
}

checksum_of_config() {
  sha256sum "$(config_file)" | cut -d ' ' -f 1
}

encoded() {
  jq -rn --arg path "$1" '$path | @uri'
}

expected_url() {
  echo "obsidian://open?path=$(encoded "$1/index.md")"
}

opener_calls() {
  if [[ -f $OPENED_FILE ]]; then
    wc -l <"$OPENED_FILE"
  else
    echo 0
  fi
}

list_vault_outside_notes_root() {
  (cd "$VAULT" && find . -path ./obsidian-plans -prune -o -printf '%p %y %s %T@\n' | sort)
}

open_from() {
  cd "$1"
  run --separate-stderr "$PLANS_OPEN"
}

@test "opens index.md of the notes folder for a known vault" {
  create_checkout github.com/acme/widget
  register_vault "$VAULT"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(cat "$OPENED_FILE")" = "$(expected_url "$(notes_of github.com/acme/widget)")" ]
  [ "$(opener_calls)" -eq 1 ]
}

@test "does not modify obsidian.json" {
  create_checkout github.com/acme/widget
  register_vault "$VAULT"
  local before
  before=$(checksum_of_config)

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(checksum_of_config)" = "$before" ]
  [ "$(ls "$OBSIDIAN_CONFIG_DIR")" = "obsidian.json" ]
}

@test "fails with the exact message when the vault is unknown" {
  create_checkout github.com/acme/widget
  printf '{"vaults":{"bbbbbbbbbbbbbbbb":{"path":"/other/vault","ts":5}}}\n' >"$(config_file)"
  local before
  before=$(checksum_of_config)

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ "$stderr" = "$UNKNOWN_VAULT_LINE" ]
  [ "$(checksum_of_config)" = "$before" ]
  [ "$(opener_calls)" -eq 0 ]
}

@test "fails with the exact message when obsidian.json has no vaults" {
  create_checkout github.com/acme/widget
  echo '{}' >"$(config_file)"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [ "$stderr" = "$UNKNOWN_VAULT_LINE" ]
  [ "$(opener_calls)" -eq 0 ]
}

@test "fails with the exact message when obsidian.json is missing" {
  create_checkout github.com/acme/widget
  rm -rf "$OBSIDIAN_CONFIG_DIR"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ "$stderr" = "$UNKNOWN_VAULT_LINE" ]
  [ ! -e "$OBSIDIAN_CONFIG_DIR" ]
  [ "$(opener_calls)" -eq 0 ]
}

@test "fails and leaves obsidian.json alone when it is not valid JSON" {
  create_checkout github.com/acme/widget
  echo 'not json' >"$(config_file)"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"cannot read"* ]]
  [ "$(cat "$(config_file)")" = "not json" ]
  [ "$(opener_calls)" -eq 0 ]
}

@test "fails with a clear message when the opener is missing" {
  create_checkout github.com/acme/widget
  register_vault "$VAULT"
  export PLANS_OPEN_COMMAND="$BATS_TEST_TMPDIR/no-such-opener"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"no-such-opener"* ]]
  [[ "$stderr" == *"not found"* ]]
}

@test "fails with a clear message when the opener fails" {
  create_checkout github.com/acme/widget
  register_vault "$VAULT"
  printf '#!/usr/bin/env bash\necho "opener noise"\nexit 3\n' >"$PLANS_OPEN_COMMAND"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"failed"* ]]
}

@test "fails before doing anything when jq is missing" {
  create_checkout github.com/acme/widget
  register_vault "$VAULT"
  local empty_path="$BATS_TEST_TMPDIR/empty-path"
  mkdir -p "$empty_path"
  cd "$GHQ_ROOT/github.com/acme/widget"

  run --separate-stderr env PATH="$empty_path" "$BASH" "$PLANS_OPEN"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"jq"* ]]
  [ "$(opener_calls)" -eq 0 ]
  [ ! -e "$(notes_of github.com/acme/widget)" ]
}

@test "encodes spaces and at signs in the path" {
  create_checkout "git.example.com/user@corp/my widget"
  register_vault "$VAULT"

  open_from "$GHQ_ROOT/git.example.com/user@corp/my widget"

  [ "$status" -eq 0 ]
  local url
  url=$(cat "$OPENED_FILE")
  [ "$url" = "$(expected_url "$(notes_of "git.example.com/user@corp/my widget")")" ]
  [[ "$url" == *"user%40corp"* ]]
  [[ "$url" == *"my%20widget"* ]]
  [[ "$url" == *"index.md" ]]
  [[ "$url" != *" "* ]]
}

@test "runs from a worktree" {
  create_checkout github.com/acme/widget
  create_worktree github.com/acme/widget feature/login
  register_vault "$VAULT"

  open_from "$GHQ_ROOT/worktrees/github.com/acme/widget/feature-login"

  [ "$status" -eq 0 ]
  [ "$(cat "$OPENED_FILE")" = "$(expected_url "$(notes_of github.com/acme/widget)")" ]
}

@test "runs from inside a notes folder" {
  create_checkout gitlab.com/group/subgroup/widget
  register_vault "$VAULT"
  local notes
  notes=$(notes_of gitlab.com/group/subgroup/widget)
  mkdir -p "$notes/inbox"
  touch "$notes/.plans-vault"

  open_from "$notes/inbox"

  [ "$status" -eq 0 ]
  [ "$(cat "$OPENED_FILE")" = "$(expected_url "$notes")" ]
}

@test "prints nothing on stdout" {
  create_checkout github.com/acme/widget
  register_vault "$VAULT"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "never changes the vault outside the notes root" {
  create_checkout github.com/acme/widget
  register_vault "$VAULT"
  (cd "$GHQ_ROOT/github.com/acme/widget" && "$BATS_TEST_DIRNAME/../bin/plans-resolve" >/dev/null)
  local before after
  before=$(list_vault_outside_notes_root)

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  after=$(list_vault_outside_notes_root)
  [ "$before" = "$after" ]
}

@test "fails outside a checkout, a worktree, and a notes folder" {
  register_vault "$VAULT"
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"

  open_from "$BATS_TEST_TMPDIR/elsewhere"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ -n "$stderr" ]
  [ "$(opener_calls)" -eq 0 ]
}

@test "fails when the plans config is missing" {
  create_checkout github.com/acme/widget
  register_vault "$VAULT"
  rm -rf "$OBSIDIAN_PLANS_CONFIG_DIR"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"install --vault"* ]]
  [ "$(opener_calls)" -eq 0 ]
}

sandbox_dir() {
  dirname "$VAULT"
}

@test "opens with the registered symlink path when the config uses the real path" {
  create_checkout github.com/acme/widget
  local link="$(sandbox_dir)/vault-link"
  ln -s "$VAULT" "$link"
  register_vault "$link"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(cat "$OPENED_FILE")" = "$(expected_url "$link/obsidian-plans/github.com/acme/widget")" ]
}

@test "opens with the registered real path when the config uses a symlink path" {
  create_checkout github.com/acme/widget
  local link="$(sandbox_dir)/vault-link"
  ln -s "$VAULT" "$link"
  write_plans_config "$link"
  register_vault "$VAULT"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(cat "$OPENED_FILE")" = "$(expected_url "$VAULT/obsidian-plans/github.com/acme/widget")" ]
}

@test "opens with the registered path when the subfolder is a symlink" {
  create_checkout github.com/acme/widget
  mkdir -p "$(sandbox_dir)/real-notes"
  ln -s "$(sandbox_dir)/real-notes" "$NOTES_ROOT"
  register_vault "$VAULT"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(cat "$OPENED_FILE")" = "$(expected_url "$VAULT/obsidian-plans/github.com/acme/widget")" ]
}

@test "opens from inside a notes folder when the vault is registered by a symlink path" {
  create_checkout github.com/acme/widget
  local link="$(sandbox_dir)/vault-link"
  ln -s "$VAULT" "$link"
  register_vault "$link"
  (cd "$GHQ_ROOT/github.com/acme/widget" && "$BATS_TEST_DIRNAME/../bin/plans-resolve" >/dev/null)

  open_from "$NOTES_ROOT/github.com/acme/widget/inbox"

  [ "$status" -eq 0 ]
  [ "$(cat "$OPENED_FILE")" = "$(expected_url "$link/obsidian-plans/github.com/acme/widget")" ]
}

@test "matches a registered path that has a trailing slash" {
  create_checkout github.com/acme/widget
  register_vault "$VAULT/"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(cat "$OPENED_FILE")" = "$(expected_url "$VAULT/obsidian-plans/github.com/acme/widget")" ]
}

@test "skips a registered path that no longer exists" {
  create_checkout github.com/acme/widget
  printf '{"vaults":{"a":{"path":"/no/such/vault"},"b":{"path":"%s"}}}\n' "$VAULT" >"$(config_file)"

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(cat "$OPENED_FILE")" = "$(expected_url "$VAULT/obsidian-plans/github.com/acme/widget")" ]
}

@test "fails with a clear message when HOME is unset and no Obsidian config dir is set" {
  create_checkout github.com/acme/widget
  unset HOME OBSIDIAN_CONFIG_DIR

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ "${#stderr_lines[@]}" -eq 1 ]
  [[ "$stderr" == "plans-open: "*"HOME"*"OBSIDIAN_CONFIG_DIR"* ]]
  [[ "$stderr" != *"unbound"* ]]
  [ "$(opener_calls)" -eq 0 ]
}

@test "fails with a clear message when HOME is unset and no plans config dir is set" {
  create_checkout github.com/acme/widget
  unset HOME OBSIDIAN_PLANS_CONFIG_DIR XDG_CONFIG_HOME

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ "${#stderr_lines[@]}" -eq 1 ]
  [[ "$stderr" == *"HOME"*"Run install --vault <dir>" ]]
  [[ "$stderr" != *"unbound"* ]]
  [ "$(opener_calls)" -eq 0 ]
}

@test "works with HOME unset when both config dirs are set" {
  create_checkout github.com/acme/widget
  register_vault "$VAULT"
  unset HOME

  open_from "$GHQ_ROOT/github.com/acme/widget"

  [ "$status" -eq 0 ]
  [ "$(opener_calls)" -eq 1 ]
}
