#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/lib.sh
source "$ROOT_DIR/tests/lib.sh"
init_sandbox
trap cleanup_sandbox EXIT
sandbox_env
printf 'previous user rule\n' > "$TEST_SANDBOX_PI_HOME/AGENTS.md"
mkdir -p -- "$TEST_SANDBOX_PI_HOME/prompts"
printf 'previous f5\n' > "$TEST_SANDBOX_PI_HOME/prompts/f5.md"
bash "$ROOT_DIR/install.sh" --yes
backup=$(python3 - "$TEST_SANDBOX_PI_HOME/.repackmyskill/state.json" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))['backup_directory'])
PY
)
outside="$TEST_SANDBOX_ROOT/rollback-outside"
saved_prompts="$TEST_SANDBOX_ROOT/saved-prompts"
mkdir -p -- "$outside"
printf 'outside sentinel\n' > "$outside/f5.md"
mv -- "$TEST_SANDBOX_PI_HOME/prompts" "$saved_prompts"
ln -s -- "$outside" "$TEST_SANDBOX_PI_HOME/prompts"
if bash "$ROOT_DIR/rollback.sh" --backup "$backup" --yes; then
  echo 'FAIL rollback accepted symlink parent' >&2
  exit 1
fi
[[ "$(cat "$outside/f5.md")" == 'outside sentinel' ]]
[[ ! -e "$outside/fl.md" ]]
rm -- "$TEST_SANDBOX_PI_HOME/prompts"
mv -- "$saved_prompts" "$TEST_SANDBOX_PI_HOME/prompts"
bash "$ROOT_DIR/rollback.sh" --backup "$backup" --yes
[[ "$(cat "$TEST_SANDBOX_PI_HOME/AGENTS.md")" == 'previous user rule' ]]
[[ "$(cat "$TEST_SANDBOX_PI_HOME/prompts/f5.md")" == 'previous f5' ]]
[[ ! -f "$TEST_SANDBOX_PI_HOME/prompts/fl.md" ]]
[[ ! -f "$TEST_SANDBOX_PI_HOME/skills/hyperframes/SKILL.md" ]]
[[ ! -f "$TEST_SANDBOX_PI_HOME/bin/hyperframes" ]]
echo TEST_ROLLBACK=PASS
