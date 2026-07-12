#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
JSON_OUTPUT=0
TEMP_DIR=''
BACKUP_DIR=''
TX_ACTIVE=0
DRY_RUN=0
# shellcheck source=scripts/lib/common.sh
source "$ROOT_DIR/scripts/lib/common.sh"
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: bash doctor.sh [--json] [--help]

Read-only health check for RepackMyskill target PI_HOME.
EOF
}

while (($#)); do
  case "$1" in
    --json) JSON_OUTPUT=1 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; die "Opsi tidak dikenal: $1" ;;
  esac
  shift
done

resolve_pi_home
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/repackmyskill-doctor.XXXXXXXX")
RESULTS="$TEMP_DIR/results.tsv"
: > "$RESULTS"
FAIL_COUNT=0

record() {
  local status=$1 check=$2 detail=$3
  printf '%s\t%s\t%s\n' "$status" "$check" "$detail" >> "$RESULTS"
  [[ "$status" == FAIL ]] && ((FAIL_COUNT+=1)) || true
}

check_command() {
  local command=$1
  if command_exists "$command"; then record PASS "command:$command" 'available'; else record FAIL "command:$command" 'missing'; fi
}

for command in bash git node npm npx pi python3 sha256sum; do check_command "$command"; done
if command_exists node; then
  node_major=$(node -p 'Number(process.versions.node.split(".")[0])' 2>/dev/null || printf 0)
  if [[ "$node_major" =~ ^[0-9]+$ ]] && ((node_major >= 20)); then record PASS node_version "$(node --version)"; else record FAIL node_version 'Node.js >=20 required'; fi
fi

if [[ -f "$ROOT_DIR/manifest/payload.sha256" ]] && (cd "$ROOT_DIR" && sha256sum --check manifest/payload.sha256 >/dev/null 2>&1); then
  record PASS payload_checksum 'manifest/payload.sha256 valid'
else
  record FAIL payload_checksum 'payload checksum mismatch or missing'
fi

if state_is_valid; then
  record PASS state 'valid state.json'
else
  record FAIL state "invalid or missing: $STATE_PATH"
fi

if [[ -f "$PI_HOME/AGENTS.md" ]]; then
  starts=$(grep -Fxc "$REPACK_MARKER_START" "$PI_HOME/AGENTS.md" || true)
  ends=$(grep -Fxc "$REPACK_MARKER_END" "$PI_HOME/AGENTS.md" || true)
  if [[ "$starts" == 1 && "$ends" == 1 ]]; then record PASS agents_marker 'exactly one managed block'; else record FAIL agents_marker "start=$starts end=$ends"; fi
else
  record FAIL agents_marker 'AGENTS.md missing'
fi

if [[ -f "$ROOT_DIR/manifest/custom-files.sha256" ]]; then
  while IFS='  ' read -r expected rel; do
    [[ -n "$rel" ]] || continue
    [[ "$rel" == AGENTS.md ]] && continue
    if [[ -f "$PI_HOME/$rel" && "$(sha256sum -- "$PI_HOME/$rel" | awk '{print $1}')" == "$expected" ]]; then
      record PASS "custom:$rel" 'checksum matches'
    else
      record FAIL "custom:$rel" 'missing or checksum mismatch'
    fi
  done < "$ROOT_DIR/manifest/custom-files.sha256"
fi

for path in \
  'agents/fable-luna.md' 'agents/fable-sol.md' 'agents/fable-terra.md' \
  'skills/fable-auto/SKILL.md' 'skills/peta-auto/SKILL.md' 'skills/senior-engineer-auto/SKILL.md' \
  'extensions/fable-plan-guard/index.ts' 'pi-plan-extension.json' \
  'skills/grill-me/SKILL.md' 'skills/grilling/SKILL.md' \
  'prompts/f5.md' 'prompts/fl.md' 'prompts/fs.md' 'prompts/ft.md' 'prompts/peta-auto.md' 'prompts/senior-auto.md' 'prompts/impeccable.md' 'prompts/grill-me.md'; do
  if [[ -f "$PI_HOME/$path" ]]; then record PASS "file:$path" 'present'; else record FAIL "file:$path" 'missing'; fi
done

astral_count=$(find "$PI_HOME/skills" -maxdepth 2 -path '*/astral-*/SKILL.md' -type f 2>/dev/null | wc -l | tr -d ' ')
if [[ "$astral_count" == 16 ]]; then record PASS astral_skills '16 present'; else record FAIL astral_skills "expected=16 actual=$astral_count"; fi

if state_is_valid; then
  skip_impeccable=$(python3 - "$STATE_PATH" <<'PY'
import json,sys
print('true' if json.load(open(sys.argv[1]))['skipped_components'].get('impeccable') else 'false')
PY
)
  if [[ "$skip_impeccable" == true ]]; then record SKIP impeccable 'skipped by installation state';
  elif [[ -f "$PI_HOME/skills/impeccable/SKILL.md" ]]; then record PASS impeccable 'present';
  else record FAIL impeccable 'missing'; fi
fi

if command_exists pi; then
  if listing=$(pi list 2>&1); then
    for spec in 'npm:pi-9router-ext@0.2.2' 'npm:@tintinweb/pi-subagents@0.13.0' 'npm:pi-plan-extension@0.1.0' 'git:github.com/code-yeongyu/pi-todotools@93ba67efa5a7358356a829569365bb017a8ad498'; do
      if package_is_installed "$spec" "$listing"; then record PASS "package:$spec" 'pinned spec available'; else record FAIL "package:$spec" 'missing'; fi
    done
  else
    record FAIL packages 'pi list failed'
  fi
else
  record SKIP packages 'pi unavailable'
fi

todo="$PI_HOME/git/github.com/code-yeongyu/pi-todotools"
if [[ -d "$todo" && -f "$todo/package-lock.json" ]]; then
  if (cd "$todo" && npm audit --omit=dev --audit-level=high >/dev/null 2>&1); then record PASS todotools_audit 'no high/critical vulnerabilities'; else record FAIL todotools_audit 'npm audit failed'; fi
else
  record FAIL todotools_audit 'checkout or lockfile missing'
fi

if python3 - "$ROOT_DIR" <<'PY'
from pathlib import Path
import re,sys
root=Path(sys.argv[1]); patterns=[r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',r'Authorization:\s*(?:Bearer|Basic)\s+[A-Za-z0-9._~+/=-]{8,}',r'AKIA[0-9A-Z]{16}',r'gh[pousr]_[A-Za-z0-9]{20,}',r'(?:api[_-]?key|access[_-]?token|client[_-]?secret|password)\s*[=:]\s*["\x27]?[^$<{\s][^\s"\x27]{7,}']
for p in root.rglob('*'):
 if not p.is_file() or '.git' in p.parts or '.pi' in p.parts: continue
 try: text=p.read_text()
 except UnicodeDecodeError: continue
 if any(re.search(pattern,text,re.I) for pattern in patterns): raise SystemExit(1)
PY
then record PASS bundled_secrets 'no secret patterns'; else record FAIL bundled_secrets 'secret-like content found'; fi

if [[ "$JSON_OUTPUT" == 1 ]]; then
  python3 - "$RESULTS" "$FAIL_COUNT" <<'PY'
import json,sys
rows=[]
for line in open(sys.argv[1]):
 status,check,detail=line.rstrip('\n').split('\t',2); rows.append({'status':status,'check':check,'detail':detail})
print(json.dumps({'pi_home':__import__('os').environ.get('PI_CODING_AGENT_DIR'),'results':rows,'failures':int(sys.argv[2])},indent=2))
PY
else
  while IFS=$'\t' read -r status check detail; do printf '%-4s %-42s %s\n' "$status" "$check" "$detail"; done < "$RESULTS"
  printf 'Summary: FAIL=%s\n' "$FAIL_COUNT"
fi
((FAIL_COUNT == 0))
