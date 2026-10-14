#!/usr/bin/env bats

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export OBSIDIAN_PLANS_CONFIG_DIR="$BATS_TEST_TMPDIR/config"
  unset XDG_CONFIG_HOME
  mkdir -p "$HOME"
  config_file="$OBSIDIAN_PLANS_CONFIG_DIR/config"

  vault="$BATS_TEST_TMPDIR/vault"
  mkdir -p "$vault/.obsidian"
  printf '{}\n' >"$vault/.obsidian/app.json"
  printf 'note\n' >"$vault/note.md"

  fake_repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$fake_repo/src/bin" "$fake_repo/src/skills/obsidian-inbox" "$fake_repo/src/skills/obsidian-plans"
  cp "$BATS_TEST_DIRNAME/../install" "$fake_repo/src/install"
  printf '#!/usr/bin/env bash\n' >"$fake_repo/src/bin/plans-resolve"
  printf '#!/usr/bin/env bash\n' >"$fake_repo/src/bin/plans-open"
  chmod +x "$fake_repo/src/bin/"*
  printf 'skill\n' >"$fake_repo/src/skills/obsidian-inbox/SKILL.md"
  printf 'skill\n' >"$fake_repo/src/skills/obsidian-plans/SKILL.md"
  install_script="$fake_repo/src/install"
}

list_vault() {
  (cd "$vault" && find . -printf '%p %y %s %T@\n' | sort)
}

@test "fresh install writes the config with the default subfolder" {
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [ "$(cat "$config_file")" = "$(printf 'vault=%s\nsubfolder=obsidian-plans' "$vault")" ]
  [[ "$output" == *"wrote config"* ]]
}

@test "fresh install writes the given subfolder" {
  run "$install_script" --vault "$vault" --subfolder "agent notes"
  [ "$status" -eq 0 ]
  [ "$(rg '^subfolder=' "$config_file")" = "subfolder=agent notes" ]
}

@test "install expands a leading tilde in the vault" {
  mkdir -p "$HOME/my vault/.obsidian"
  run "$install_script" --vault "~/my vault"
  [ "$status" -eq 0 ]
  [ "$(rg '^vault=' "$config_file")" = "vault=$HOME/my vault" ]
}

@test "install honors XDG_CONFIG_HOME when no config dir override is set" {
  unset OBSIDIAN_PLANS_CONFIG_DIR
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/xdg"
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [ -f "$XDG_CONFIG_HOME/obsidian-plans/config" ]
}

@test "install defaults the config dir to .config below HOME" {
  unset OBSIDIAN_PLANS_CONFIG_DIR
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/obsidian-plans/config" ]
}

@test "install --vault replaces an existing config" {
  mkdir -p "$OBSIDIAN_PLANS_CONFIG_DIR"
  printf 'vault=/somewhere/else\nsubfolder=old\n' >"$config_file"
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [ "$(cat "$config_file")" = "$(printf 'vault=%s\nsubfolder=obsidian-plans' "$vault")" ]
  [[ "$output" == *"wrote config"* ]]
}

@test "install --vault repairs a config whose vault moved away" {
  local moved="$BATS_TEST_TMPDIR/moved-vault"
  mkdir -p "$OBSIDIAN_PLANS_CONFIG_DIR"
  printf 'vault=%s\n' "$vault" >"$config_file"
  mv "$vault" "$moved"
  run "$install_script" --vault "$moved"
  [ "$status" -eq 0 ]
  [ "$(rg '^vault=' "$config_file")" = "vault=$moved" ]
}

@test "install keeps an existing config when you pass no arguments" {
  mkdir -p "$OBSIDIAN_PLANS_CONFIG_DIR"
  printf 'vault=%s\n' "$vault" >"$config_file"
  run "$install_script"
  [ "$status" -eq 0 ]
  [ "$(cat "$config_file")" = "vault=$vault" ]
  [ -L "$HOME/.local/bin/plans-resolve" ]
}

@test "install keeps an existing config byte for byte without --vault" {
  mkdir -p "$OBSIDIAN_PLANS_CONFIG_DIR"
  printf '\xef\xbb\xbf# mine\n  vault = "%s"  \n\nsubfolder=x' "$vault" >"$config_file"
  cp "$config_file" "$BATS_TEST_TMPDIR/config-before"
  run "$install_script"
  [ "$status" -eq 0 ]
  cmp "$config_file" "$BATS_TEST_TMPDIR/config-before"
  [[ "$output" == *"kept existing config"* ]]
}

@test "install fails on --subfolder without --vault when a config exists" {
  mkdir -p "$OBSIDIAN_PLANS_CONFIG_DIR"
  printf 'vault=%s\n' "$vault" >"$config_file"
  run "$install_script" --subfolder "other"
  [ "$status" -ne 0 ]
  [[ "$output" == *"--subfolder"*"--vault"* ]]
  [ "$(cat "$config_file")" = "vault=$vault" ]
  [ ! -e "$HOME/.local/bin" ]
}

@test "install fails on --subfolder without --vault and without a config" {
  run "$install_script" --subfolder "other"
  [ "$status" -ne 0 ]
  [[ "$output" == *"--vault"* ]]
  [ ! -e "$config_file" ]
}

@test "install validates --vault and keeps the existing config when validation fails" {
  mkdir -p "$OBSIDIAN_PLANS_CONFIG_DIR"
  printf 'vault=%s\n' "$vault" >"$config_file"
  run "$install_script" --vault "$BATS_TEST_TMPDIR/missing"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not an existing directory"* ]]
  [ "$(cat "$config_file")" = "vault=$vault" ]
  run "$install_script" --vault "$vault" --subfolder "a/b"
  [ "$status" -ne 0 ]
  [ "$(cat "$config_file")" = "vault=$vault" ]
}

@test "install trims spaces and tabs around --vault before validating and writing" {
  run "$install_script" --vault "$(printf ' \t%s \t' "$vault")"
  [ "$status" -eq 0 ]
  [ "$(rg '^vault=' "$config_file")" = "vault=$vault" ]
}

@test "install trims spaces and tabs around --subfolder before writing" {
  run "$install_script" --vault "$vault" --subfolder "$(printf ' \tnotes \t')"
  [ "$status" -eq 0 ]
  [ "$(rg '^subfolder=' "$config_file")" = "subfolder=notes" ]
}

@test "install keeps spaces inside --subfolder" {
  run "$install_script" --vault "$vault" --subfolder " agent notes "
  [ "$status" -eq 0 ]
  [ "$(rg '^subfolder=' "$config_file")" = "subfolder=agent notes" ]
}

@test "install fails when --vault is only spaces" {
  run "$install_script" --vault "   "
  [ "$status" -ne 0 ]
  [[ "$output" == *"vault is empty"* ]]
  [ ! -e "$config_file" ]
}

@test "install fails when --subfolder is only spaces" {
  run "$install_script" --vault "$vault" --subfolder "  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"subfolder is empty"* ]]
  [ ! -e "$config_file" ]
}

@test "install fails with a clear message when HOME is unset" {
  run env -u HOME "$install_script" --vault "$vault"
  [ "$status" -ne 0 ]
  [[ "$output" == *"HOME is not set"* ]]
  [[ "$output" != *"unbound variable"* ]]
  [ ! -e "$config_file" ]
}

@test "install fails with a clear message when HOME is unset and a config dir is set" {
  run env -u HOME -u XDG_CONFIG_HOME "$install_script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"HOME is not set"* ]]
}

@test "install fails without --vault and without a config" {
  run "$install_script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"install --vault <dir>"* ]]
  [ ! -e "$config_file" ]
  [ ! -e "$HOME/.local/bin" ]
  [ ! -e "$HOME/.claude/skills" ]
}

@test "install fails when the vault does not exist" {
  run "$install_script" --vault "$BATS_TEST_TMPDIR/missing"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not an existing directory"* ]]
  [ ! -e "$config_file" ]
  [ ! -e "$HOME/.local/bin" ]
}

@test "install fails when the vault is a file" {
  : >"$BATS_TEST_TMPDIR/file"
  run "$install_script" --vault "$BATS_TEST_TMPDIR/file"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not an existing directory"* ]]
  [ ! -e "$config_file" ]
}

@test "install fails when the vault has no .obsidian folder" {
  mkdir -p "$BATS_TEST_TMPDIR/plain"
  run "$install_script" --vault "$BATS_TEST_TMPDIR/plain"
  [ "$status" -ne 0 ]
  [[ "$output" == *".obsidian"* ]]
  [ ! -e "$config_file" ]
  [ ! -e "$BATS_TEST_TMPDIR/plain/.obsidian" ]
}

@test "install fails when the vault is a relative path" {
  cd "$BATS_TEST_TMPDIR"
  run "$install_script" --vault "vault"
  [ "$status" -ne 0 ]
  [[ "$output" == *"absolute"* ]]
  [ ! -e "$config_file" ]
}

@test "install fails when the subfolder contains a slash" {
  run "$install_script" --vault "$vault" --subfolder "a/b"
  [ "$status" -ne 0 ]
  [[ "$output" == *"subfolder"* ]]
  [ ! -e "$config_file" ]
  [ ! -e "$HOME/.local/bin" ]
}

@test "install fails when the subfolder is empty" {
  run "$install_script" --vault "$vault" --subfolder ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"subfolder"* ]]
  [ ! -e "$config_file" ]
}

@test "install fails on an unknown argument" {
  run "$install_script" --bogus
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown argument"* ]]
}

@test "install fails when an option has no value" {
  run "$install_script" --vault
  [ "$status" -ne 0 ]
  [[ "$output" == *"--vault needs"* ]]
}

@test "install symlinks bin files and skill directories" {
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.local/bin/plans-resolve" ]
  [ -L "$HOME/.local/bin/plans-open" ]
  [ "$(readlink "$HOME/.local/bin/plans-resolve")" = "$fake_repo/src/bin/plans-resolve" ]
  [ -L "$HOME/.claude/skills/obsidian-inbox" ]
  [ "$(readlink "$HOME/.claude/skills/obsidian-plans")" = "$fake_repo/src/skills/obsidian-plans" ]
  [ -f "$HOME/.claude/skills/obsidian-inbox/SKILL.md" ]
}

@test "install resolves sources through a symlink to the script" {
  ln -s "$install_script" "$BATS_TEST_TMPDIR/install-link"
  run "$BATS_TEST_TMPDIR/install-link" --vault "$vault"
  [ "$status" -eq 0 ]
  [ "$(readlink "$HOME/.local/bin/plans-resolve")" = "$fake_repo/src/bin/plans-resolve" ]
}

@test "install is idempotent" {
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  config_before="$(cat "$config_file")"
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [ "$(cat "$config_file")" = "$config_before" ]
  [ "$(readlink "$HOME/.local/bin/plans-resolve")" = "$fake_repo/src/bin/plans-resolve" ]
  [ "$(readlink "$HOME/.claude/skills/obsidian-inbox")" = "$fake_repo/src/skills/obsidian-inbox" ]
  [ "$(ls "$HOME/.local/bin" | wc -l)" -eq 2 ]
}

@test "install does not overwrite an existing regular file in bin" {
  mkdir -p "$HOME/.local/bin"
  printf 'mine\n' >"$HOME/.local/bin/plans-resolve"
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped"*"plans-resolve"* ]]
  [ ! -L "$HOME/.local/bin/plans-resolve" ]
  [ "$(cat "$HOME/.local/bin/plans-resolve")" = "mine" ]
  [ -L "$HOME/.local/bin/plans-open" ]
}

@test "install does not overwrite an existing directory in skills" {
  mkdir -p "$HOME/.claude/skills/obsidian-inbox"
  printf 'mine\n' >"$HOME/.claude/skills/obsidian-inbox/SKILL.md"
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped"*"obsidian-inbox"* ]]
  [ ! -L "$HOME/.claude/skills/obsidian-inbox" ]
  [ "$(cat "$HOME/.claude/skills/obsidian-inbox/SKILL.md")" = "mine" ]
  [ -L "$HOME/.claude/skills/obsidian-plans" ]
}

@test "install replaces a stale symlink" {
  mkdir -p "$HOME/.local/bin"
  ln -s "$BATS_TEST_TMPDIR/gone" "$HOME/.local/bin/plans-resolve"
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [ "$(readlink "$HOME/.local/bin/plans-resolve")" = "$fake_repo/src/bin/plans-resolve" ]
}

@test "install skips empty bin and skills directories" {
  rm -r "$fake_repo/src/bin" "$fake_repo/src/skills"
  mkdir "$fake_repo/src/bin" "$fake_repo/src/skills"
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [ -f "$config_file" ]
  [ ! -e "$HOME/.local/bin" ]
  [ ! -e "$HOME/.claude/skills" ]
}

@test "install skips missing bin and skills directories" {
  rm -r "$fake_repo/src/bin" "$fake_repo/src/skills"
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [ -f "$config_file" ]
}

@test "install leaves the vault untouched" {
  local before after
  before=$(list_vault)
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  after=$(list_vault)
  [ "$before" = "$after" ]
}

@test "install leaves the vault untouched when it fails" {
  local before after
  before=$(list_vault)
  run "$install_script" --vault "$vault" --subfolder "a/b"
  [ "$status" -ne 0 ]
  after=$(list_vault)
  [ "$before" = "$after" ]
}

@test "install never runs a git command" {
  local fake_bin="$BATS_TEST_TMPDIR/fake-bin"
  mkdir -p "$fake_bin"
  printf '#!/usr/bin/env bash\necho called >>"%s/git-calls"\nexit 1\n' "$BATS_TEST_TMPDIR" >"$fake_bin/git"
  chmod +x "$fake_bin/git"
  PATH="$fake_bin:$PATH" run "$install_script" --vault "$vault"
  [ "$status" -eq 0 ]
  [ ! -e "$BATS_TEST_TMPDIR/git-calls" ]
  [ ! -e "$vault/.git" ]
}
