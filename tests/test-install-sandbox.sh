#!/usr/bin/env bash
set -Eeuo pipefail

# Full integration test. Requires network and executes only in temporary HOME.
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/lib.sh
source "$ROOT_DIR/tests/lib.sh"
active_snapshot_begin
init_sandbox
trap 'status=$?; active_snapshot_assert; cleanup_sandbox; exit "$status"' EXIT
sandbox_env

bash "$ROOT_DIR/install.sh" --yes
pi list | grep -F 'npm:pi-9router-ext@0.2.2'
pi list | grep -F 'npm:@tintinweb/pi-subagents@0.13.0'
pi list | grep -F 'npm:pi-plan-extension@0.1.0'
pi list | grep -F 'git:github.com/code-yeongyu/pi-todotools@93ba67efa5a7358356a829569365bb017a8ad498'

todo="$TEST_SANDBOX_PI_HOME/git/github.com/code-yeongyu/pi-todotools"
[[ -d "$todo/.git" ]]
[[ "$(git -C "$todo" rev-parse HEAD)" == '93ba67efa5a7358356a829569365bb017a8ad498' ]]
(cd "$todo" && npm audit --omit=dev --audit-level=high)
assert_custom_payload
[[ "$(find "$TEST_SANDBOX_PI_HOME/skills" -maxdepth 2 -path '*/astral-*/SKILL.md' -type f | wc -l | tr -d ' ')" == 16 ]]
[[ -f "$TEST_SANDBOX_PI_HOME/skills/grill-me/SKILL.md" ]]
[[ -f "$TEST_SANDBOX_PI_HOME/skills/grilling/SKILL.md" ]]
[[ -f "$TEST_SANDBOX_PI_HOME/skills/impeccable/SKILL.md" ]]
[[ "$(grep -Fxc '<!-- REPACKMYSKILL:START -->' "$TEST_SANDBOX_PI_HOME/AGENTS.md")" == 1 ]]
python3 -m json.tool "$TEST_SANDBOX_PI_HOME/.repackmyskill/state.json" >/dev/null
bash "$ROOT_DIR/doctor.sh"
echo TEST_INSTALL_SANDBOX=PASS
