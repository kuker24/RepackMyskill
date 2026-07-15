#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/lib.sh
source "$ROOT_DIR/tests/lib.sh"
init_sandbox
trap cleanup_sandbox EXIT
sandbox_env
require_sandbox_install
mkdir -p -- "$TEST_SANDBOX_PI_HOME/skills/hyperframes/.stale"
printf 'unchanged stale\n' > "$TEST_SANDBOX_PI_HOME/skills/hyperframes/.stale/unchanged.md"
printf 'modified stale\n' > "$TEST_SANDBOX_PI_HOME/skills/hyperframes/.stale/modified.md"
python3 - "$TEST_SANDBOX_PI_HOME/.repackmyskill/state.json" <<'PY'
import hashlib,json,sys
from pathlib import Path
path=Path(sys.argv[1]); state=json.loads(path.read_text())
for name in ('unchanged.md','modified.md'):
 target=path.parent.parent/'skills'/'hyperframes'/'.stale'/name
 entry={'path':f'skills/hyperframes/.stale/{name}','sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
 state.setdefault('hyperframes_managed_files',[]).append(entry)
path.write_text(json.dumps(state,indent=2,sort_keys=True)+'\n')
PY
printf 'user changed stale\n' > "$TEST_SANDBOX_PI_HOME/skills/hyperframes/.stale/modified.md"
before=$(mktemp)
(cd "$TEST_SANDBOX_PI_HOME" && find agents extensions prompts skills \( -path 'skills/hyperframes/.stale' -o -path 'skills/hyperframes/.stale/*' \) -prune -o -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$before"
bash "$ROOT_DIR/install.sh" --yes >/tmp/repack-idempotency.out 2>&1
[[ ! -e "$TEST_SANDBOX_PI_HOME/skills/hyperframes/.stale/unchanged.md" ]]
[[ "$(cat "$TEST_SANDBOX_PI_HOME/skills/hyperframes/.stale/modified.md")" == 'user changed stale' ]]
grep -F 'File stale terkelola berubah oleh pengguna; dipertahankan: skills/hyperframes/.stale/modified.md' /tmp/repack-idempotency.out
[[ "$(grep -Fxc '<!-- REPACKMYSKILL:START -->' "$TEST_SANDBOX_PI_HOME/AGENTS.md")" == 1 ]]
after=$(mktemp)
(cd "$TEST_SANDBOX_PI_HOME" && find agents extensions prompts skills \( -path 'skills/hyperframes/.stale' -o -path 'skills/hyperframes/.stale/*' \) -prune -o -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) > "$after"
diff -u "$before" "$after"
python3 -m json.tool "$TEST_SANDBOX_PI_HOME/.repackmyskill/state.json" >/dev/null
rm -f -- "$before" "$after"
echo TEST_IDEMPOTENCY=PASS
