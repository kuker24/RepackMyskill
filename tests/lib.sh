#!/usr/bin/env bash
# Shared test helpers. Tests must source this file after set -Eeuo pipefail.

TEST_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)

snapshot_tree() {
  local root=$1 output=$2
  if [[ -d "$root" ]]; then
    # Runtime session/log/cache/tmp writes are volatile. Every other regular
    # file, including AGENTS, settings, package metadata and Git sources,
    # remains checksum-protected.
    (
      cd "$root"
      find . -xdev \
        \( -path './sessions' -o -path './sessions/*' -o \
           -path './logs' -o -path './logs/*' -o \
           -path './cache' -o -path './cache/*' -o \
           -path './tmp' -o -path './tmp/*' \) -prune -o \
        -type f -print0 | LC_ALL=C sort -z | xargs -0r sha256sum --
    ) > "$output"
  else
    : > "$output"
  fi
}

init_sandbox() {
  if [[ -n "${REPACK_TEST_SANDBOX_ROOT:-}" ]]; then
    TEST_SANDBOX_ROOT=$REPACK_TEST_SANDBOX_ROOT
    TEST_SANDBOX_HOME=$REPACK_TEST_SANDBOX_HOME
    TEST_SANDBOX_PI_HOME=$REPACK_TEST_SANDBOX_PI_HOME
    return 0
  fi
  TEST_OWN_SANDBOX=1
  TEST_SANDBOX_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/repackmyskill-test.XXXXXXXX")
  TEST_SANDBOX_HOME="$TEST_SANDBOX_ROOT/home"
  TEST_SANDBOX_PI_HOME="$TEST_SANDBOX_HOME/.pi/agent"
  export REPACK_TEST_SANDBOX_ROOT=$TEST_SANDBOX_ROOT
  export REPACK_TEST_SANDBOX_HOME=$TEST_SANDBOX_HOME
  export REPACK_TEST_SANDBOX_PI_HOME=$TEST_SANDBOX_PI_HOME
  mkdir -p -- "$TEST_SANDBOX_PI_HOME"
  printf 'sandbox user rule\n' > "$TEST_SANDBOX_PI_HOME/AGENTS.md"
}

sandbox_env() {
  export HOME="$TEST_SANDBOX_HOME"
  export PI_CODING_AGENT_DIR="$TEST_SANDBOX_PI_HOME"
}

active_snapshot_begin() {
  ACTIVE_PI_HOME=${PI_CODING_AGENT_DIR:-"$HOME/.pi/agent"}
  ACTIVE_SNAPSHOT=$(mktemp "${TMPDIR:-/tmp}/repack-active-before.XXXXXXXX")
  snapshot_tree "$ACTIVE_PI_HOME" "$ACTIVE_SNAPSHOT"
}

active_snapshot_assert() {
  local after
  after=$(mktemp "${TMPDIR:-/tmp}/repack-active-after.XXXXXXXX")
  snapshot_tree "$ACTIVE_PI_HOME" "$after"
  if ! diff -u "$ACTIVE_SNAPSHOT" "$after"; then
    rm -f -- "$after" "$ACTIVE_SNAPSHOT"
    return 1
  fi
  rm -f -- "$after" "$ACTIVE_SNAPSHOT"
  echo ACTIVE_PI_HOME_STATIC_UNCHANGED=PASS
}

assert_snapshot_detection_rules() {
  local root before after
  root=$(mktemp -d "${TMPDIR:-/tmp}/repack-snapshot-rules.XXXXXXXX")
  before=$(mktemp "${TMPDIR:-/tmp}/repack-snapshot-before.XXXXXXXX")
  after=$(mktemp "${TMPDIR:-/tmp}/repack-snapshot-after.XXXXXXXX")
  mkdir -p -- "$root"/{sessions,logs,cache,tmp,prompts}
  printf 'stable\n' > "$root/AGENTS.md"
  printf 'prompt\n' > "$root/prompts/f5.md"
  snapshot_tree "$root" "$before"
  printf 'session changed\n' > "$root/sessions/active.jsonl"
  printf 'log changed\n' > "$root/logs/pi.log"
  printf 'cache changed\n' > "$root/cache/index"
  printf 'tmp changed\n' > "$root/tmp/job"
  snapshot_tree "$root" "$after"
  diff -u "$before" "$after" >/dev/null
  printf 'static changed\n' >> "$root/AGENTS.md"
  snapshot_tree "$root" "$after"
  if diff -u "$before" "$after" >/dev/null; then
    rm -rf -- "$root"; rm -f -- "$before" "$after"
    return 1
  fi
  rm -rf -- "$root"; rm -f -- "$before" "$after"
  echo ACTIVE_SNAPSHOT_FILTER_RULES=PASS
}

cleanup_sandbox() {
  local status=$?
  if [[ "${TEST_OWN_SANDBOX:-0}" == 1 && -n "${TEST_SANDBOX_ROOT:-}" ]]; then
    rm -rf -- "$TEST_SANDBOX_ROOT"
  fi
  return "$status"
}

require_sandbox_install() {
  if [[ ! -f "$TEST_SANDBOX_PI_HOME/.repackmyskill/state.json" ]]; then
    sandbox_env
    bash "$TEST_ROOT/install.sh" --yes
  fi
}

assert_custom_payload() {
  local expected rel actual
  while IFS='  ' read -r expected rel; do
    [[ "$rel" == AGENTS.md ]] && continue
    actual="$TEST_SANDBOX_PI_HOME/$rel"
    [[ -f "$actual" ]]
    [[ "$(sha256sum -- "$actual" | awk '{print $1}')" == "$expected" ]]
  done < "$TEST_ROOT/manifest/custom-files.sha256"
}
