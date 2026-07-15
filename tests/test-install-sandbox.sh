#!/usr/bin/env bash
set -Eeuo pipefail

# Full integration test. Requires network and executes only in temporary HOME.
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/lib.sh
source "$ROOT_DIR/tests/lib.sh"
active_snapshot_begin
init_sandbox
cleanup_install_test() {
  local status=$?
  active_snapshot_assert
  cleanup_sandbox
  return "$status"
}
trap cleanup_install_test EXIT
sandbox_env
mkdir -p -- "$TEST_SANDBOX_PI_HOME/skills/hyperframes"
printf 'user HyperFrames note\n' > "$TEST_SANDBOX_PI_HOME/skills/hyperframes/notes.md"

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
compat_extension="$TEST_SANDBOX_PI_HOME/extensions/fable-agent-compat/index.ts"
[[ -f "$compat_extension" && ! -L "$compat_extension" ]]
grep -Fq 'delete input.isolation' "$compat_extension"
[[ "$(find "$TEST_SANDBOX_PI_HOME/skills" -maxdepth 2 -path '*/astral-*/SKILL.md' -type f | wc -l | tr -d ' ')" == 16 ]]
[[ -f "$TEST_SANDBOX_PI_HOME/skills/grill-me/SKILL.md" ]]
[[ -f "$TEST_SANDBOX_PI_HOME/skills/grilling/SKILL.md" ]]
[[ -f "$TEST_SANDBOX_PI_HOME/skills/impeccable/SKILL.md" ]]
[[ -x "$TEST_SANDBOX_PI_HOME/bin/hyperframes" ]]
hyperframes_count=0
while IFS= read -r skill; do
  [[ -f "$TEST_SANDBOX_PI_HOME/skills/$skill/SKILL.md" ]]
  ((hyperframes_count+=1))
done < <(python3 - "$ROOT_DIR/manifest/hyperframes-selection.json" <<'PY'
import json,sys
for item in json.load(open(sys.argv[1]))['skills']: print(item)
PY
)
[[ "$hyperframes_count" == 20 ]]
[[ "$(cat "$TEST_SANDBOX_PI_HOME/skills/hyperframes/notes.md")" == 'user HyperFrames note' ]]
python3 - "$TEST_SANDBOX_PI_HOME/.repackmyskill/state.json" <<'PY'
import json,sys
state=json.load(open(sys.argv[1]))
assert not any(item['path']=='skills/hyperframes/notes.md' for item in state['managed_files'])
assert not any(item['path']=='skills/hyperframes/notes.md' for item in state['hyperframes_managed_files'])
PY
[[ "$(grep -Fxc '<!-- REPACKMYSKILL:START -->' "$TEST_SANDBOX_PI_HOME/AGENTS.md")" == 1 ]]
python3 -m json.tool "$TEST_SANDBOX_PI_HOME/.repackmyskill/state.json" >/dev/null
bash "$ROOT_DIR/doctor.sh"
echo TEST_INSTALL_SANDBOX=PASS
