#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
TEST_SANDBOX_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/repackmyskill-suite.XXXXXXXX")
TEST_SANDBOX_HOME="$TEST_SANDBOX_ROOT/home"
TEST_SANDBOX_PI_HOME="$TEST_SANDBOX_HOME/.pi/agent"
export REPACK_TEST_SANDBOX_ROOT="$TEST_SANDBOX_ROOT"
export REPACK_TEST_SANDBOX_HOME="$TEST_SANDBOX_HOME"
export REPACK_TEST_SANDBOX_PI_HOME="$TEST_SANDBOX_PI_HOME"
mkdir -p -- "$TEST_SANDBOX_PI_HOME"
printf 'sandbox user rule\n' > "$TEST_SANDBOX_PI_HOME/AGENTS.md"

cleanup() { rm -rf -- "$TEST_SANDBOX_ROOT"; }
trap cleanup EXIT

for test in \
  test-static.sh \
  test-install-sandbox.sh \
  test-idempotency.sh \
  test-doctor.sh \
  test-update.sh \
  test-uninstall.sh \
  test-rollback.sh; do
  printf '\n== %s ==\n' "$test"
  bash "$ROOT_DIR/tests/$test"
done

echo 'TEST_RUN_ALL=PASS'
