#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/lib.sh
source "$ROOT_DIR/tests/lib.sh"
init_sandbox
trap cleanup_sandbox EXIT
sandbox_env
require_sandbox_install
before=$(mktemp)
(cd "$TEST_SANDBOX_PI_HOME" && find agents extensions prompts skills -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$before"
bash "$ROOT_DIR/install.sh" --yes
[[ "$(grep -Fxc '<!-- REPACKMYSKILL:START -->' "$TEST_SANDBOX_PI_HOME/AGENTS.md")" == 1 ]]
after=$(mktemp)
(cd "$TEST_SANDBOX_PI_HOME" && find agents extensions prompts skills -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$after"
diff -u "$before" "$after"
python3 -m json.tool "$TEST_SANDBOX_PI_HOME/.repackmyskill/state.json" >/dev/null
rm -f -- "$before" "$after"
echo TEST_IDEMPOTENCY=PASS
