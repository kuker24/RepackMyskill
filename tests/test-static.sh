#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT_DIR"

for script in install.sh doctor.sh update.sh uninstall.sh rollback.sh scripts/lib/*.sh tests/*.sh; do
  bash -n "$script"
done
for json in manifest/*.json; do python3 -m json.tool "$json" >/dev/null; done
sha256sum --check manifest/payload.sha256 >/dev/null

if find payload scripts/lib -type l -print -quit | grep -q .; then echo 'FAIL symlink payload'; exit 1; fi
if find payload -type d \( -name node_modules -o -name .git -o -name backups -o -name sessions -o -name cache -o -name dist -o -name build -o -name coverage \) -print -quit | grep -q .; then echo 'FAIL excluded payload directory'; exit 1; fi

python3 - "$ROOT_DIR" <<'PY'
from pathlib import Path
import json,re,sys
root=Path(sys.argv[1]); patterns=[
 r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
 r'Authorization:\s*(?:Bearer|Basic)\s+[A-Za-z0-9._~+/=-]{8,}',
 r'AKIA[0-9A-Z]{16}',r'gh[pousr]_[A-Za-z0-9]{20,}',
 r'(?:api[_-]?key|access[_-]?token|client[_-]?secret|password)\s*[=:]\s*["\x27]?[^$<{\s][^\s"\x27]{7,}' ]
for p in root.rglob('*'):
 if not p.is_file() or '.git' in p.parts or '.pi' in p.parts: continue
 try: text=p.read_text()
 except UnicodeDecodeError: continue
 if any(re.search(rx,text,re.I) for rx in patterns): raise SystemExit(f'secret-like content: {p}')
x=json.loads((root/'manifest/astral-selection.json').read_text())
assert len(x['skills'])==16 and len({s['destination_name'] for s in x['skills']})==16
h=json.loads((root/'manifest/hyperframes-selection.json').read_text())
assert len(h['skills'])==20 and len(set(h['skills']))==20
assert h['cli']['package']=='hyperframes' and h['cli']['version']=='0.7.54' and h['commit']=='ccf5f20b3beea2b245c398a89cb686077b546de2'
assert re.fullmatch(r'sha512-[A-Za-z0-9+/]+={0,2}', h['cli']['integrity'])
extension=(root/'payload/custom/extensions/fable-agent-compat/index.ts').read_text()
for needle in ('pi.on("tool_call"', 'String(event.toolName).toLowerCase() !== "agent"', '"fable-luna"', '"fable-sol"', '"fable-terra"', 'delete input.isolation'):
 assert needle in extension, f'missing Fable Agent Compatibility behavior: {needle}'
lock=json.loads((root/'manifest/source-lock.json').read_text())
assert 'extensions/fable-agent-compat/index.ts' in lock['custom_files']
assert any(item['path']=='extensions/fable-agent-compat' for item in lock['custom_directories'])
block=(root/'payload/managed/AGENTS.repack.md').read_text()
assert block.count('<!-- REPACKMYSKILL:START -->')==1
assert block.count('<!-- REPACKMYSKILL:END -->')==1
PY

if grep -nE 'npm[[:space:]]+audit[[:space:]]+fix[[:space:]]+--force|git[[:space:]]+(push|commit)' install.sh doctor.sh update.sh uninstall.sh rollback.sh scripts/lib/*.sh; then
  echo 'FAIL forbidden runtime command'; exit 1
fi
if git ls-files --error-unmatch .pi/subagents.json >/dev/null 2>&1; then echo 'FAIL .pi/subagents.json tracked'; exit 1; fi
if git ls-files | grep -E '(^|/)(node_modules|vendor|backups|sessions|cache)(/|$)' >/dev/null; then echo 'FAIL excluded tracked path'; exit 1; fi

# Verify active-PI protection excludes exactly volatile runtime directories.
# This fixture never touches active PI_HOME.
# shellcheck source=tests/lib.sh
source "$ROOT_DIR/tests/lib.sh"
assert_snapshot_detection_rules

echo TEST_STATIC=PASS
