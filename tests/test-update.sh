#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/lib.sh
source "$ROOT_DIR/tests/lib.sh"
init_sandbox
trap cleanup_sandbox EXIT
sandbox_env
require_sandbox_install
printf 'user outside managed scope\n' > "$TEST_SANDBOX_PI_HOME/user-note.txt"
bash "$ROOT_DIR/update.sh" --yes
[[ "$(grep -Fxc '<!-- REPACKMYSKILL:START -->' "$TEST_SANDBOX_PI_HOME/AGENTS.md")" == 1 ]]
[[ "$(cat "$TEST_SANDBOX_PI_HOME/user-note.txt")" == 'user outside managed scope' ]]
bash "$ROOT_DIR/doctor.sh" >/dev/null
echo TEST_UPDATE=PASS
