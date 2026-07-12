#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/lib.sh
source "$ROOT_DIR/tests/lib.sh"
init_sandbox
trap cleanup_sandbox EXIT
sandbox_env
printf 'previous user rule\n' > "$TEST_SANDBOX_PI_HOME/AGENTS.md"
printf 'previous f5\n' > "$TEST_SANDBOX_PI_HOME/prompts/f5.md"
bash "$ROOT_DIR/install.sh" --yes
backup=$(python3 - "$TEST_SANDBOX_PI_HOME/.repackmyskill/state.json" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))['backup_directory'])
PY
)
bash "$ROOT_DIR/rollback.sh" --backup "$backup" --yes
[[ "$(cat "$TEST_SANDBOX_PI_HOME/AGENTS.md")" == 'previous user rule' ]]
[[ "$(cat "$TEST_SANDBOX_PI_HOME/prompts/f5.md")" == 'previous f5' ]]
[[ ! -f "$TEST_SANDBOX_PI_HOME/prompts/fl.md" ]]
echo TEST_ROLLBACK=PASS
