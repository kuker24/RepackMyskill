#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=tests/lib.sh
source "$ROOT_DIR/tests/lib.sh"
init_sandbox
trap cleanup_sandbox EXIT
sandbox_env
require_sandbox_install
bash "$ROOT_DIR/doctor.sh" >/tmp/repack-doctor.out
bash "$ROOT_DIR/doctor.sh" --json >/tmp/repack-doctor.json
python3 -m json.tool /tmp/repack-doctor.json >/dev/null
python3 - /tmp/repack-doctor.json <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['failures']==0
assert any(r['check']=='state' and r['status']=='PASS' for r in x['results'])
PY
echo TEST_DOCTOR=PASS
