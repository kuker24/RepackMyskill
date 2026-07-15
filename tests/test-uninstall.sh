#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/lib.sh
source "$ROOT_DIR/tests/lib.sh"
init_sandbox
trap cleanup_sandbox EXIT
sandbox_env
require_sandbox_install
printf 'keep me\n' > "$TEST_SANDBOX_PI_HOME/user-note.txt"
mkdir -p -- "$TEST_SANDBOX_PI_HOME/skills/hyperframes"
printf 'user HyperFrames note\n' > "$TEST_SANDBOX_PI_HOME/skills/hyperframes/notes.md"
# User-edited managed path must be preserved with warning and backed up.
printf '\nuser edit\n' >> "$TEST_SANDBOX_PI_HOME/prompts/f5.md"
bash "$ROOT_DIR/uninstall.sh" --yes >/tmp/repack-uninstall.out 2>&1
grep -F 'File berubah oleh pengguna' /tmp/repack-uninstall.out
[[ -f "$TEST_SANDBOX_PI_HOME/user-note.txt" ]]
[[ -f "$TEST_SANDBOX_PI_HOME/prompts/f5.md" ]]
[[ ! -f "$TEST_SANDBOX_PI_HOME/prompts/fl.md" ]]
[[ ! -f "$TEST_SANDBOX_PI_HOME/skills/hyperframes/SKILL.md" ]]
[[ "$(cat "$TEST_SANDBOX_PI_HOME/skills/hyperframes/notes.md")" == 'user HyperFrames note' ]]
[[ ! -f "$TEST_SANDBOX_PI_HOME/bin/hyperframes" ]]
[[ ! -f "$TEST_SANDBOX_PI_HOME/.repackmyskill/state.json" ]]
[[ "$(grep -Fxc '<!-- REPACKMYSKILL:START -->' "$TEST_SANDBOX_PI_HOME/AGENTS.md" || true)" == 0 ]]
grep -Fx 'sandbox user rule' "$TEST_SANDBOX_PI_HOME/AGENTS.md"
if pi list | grep -Fq 'npm:pi-9router-ext@0.2.2'; then
  echo 'Pinned package still present after official uninstall' >&2
  exit 1
fi
echo TEST_UNINSTALL=PASS
