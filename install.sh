#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DRY_RUN=0
ASSUME_YES=0
SKIP_IMPECCABLE=0
SKIP_ASTRAL=0
SKIP_GRILL=0
TEMP_DIR=''
BACKUP_DIR=''
TX_ACTIVE=0

# shellcheck source=scripts/lib/common.sh
source "$ROOT_DIR/scripts/lib/common.sh"
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: bash install.sh [options]

Install only pinned RepackMyskill components into:
  ${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}

Options:
  --dry-run          Validate and print actions without changing PI_HOME
  --yes              Skip confirmation prompt
  --skip-impeccable  Do not install Impeccable
  --skip-astral      Do not install AstralForge skills
  --skip-grill       Do not install Grill Me skills
  --help             Show this help
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
    --skip-impeccable) SKIP_IMPECCABLE=1 ;;
    --skip-astral) SKIP_ASTRAL=1 ;;
    --skip-grill) SKIP_GRILL=1 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; die "Opsi tidak dikenal: $1" ;;
  esac
  shift
done

for required in bash git node npm npx pi python3 sha256sum; do
  require_command "$required"
done
node_major=$(node -p 'Number(process.versions.node.split(".")[0])')
[[ "$node_major" =~ ^[0-9]+$ ]] || die "Versi Node.js tidak dapat dibaca"
(( node_major >= 20 )) || die "Node.js minimal versi 20; ditemukan $(node --version)"
resolve_pi_home

verify_payload() {
  local manifest="$ROOT_DIR/manifest/payload.sha256"
  [[ -f "$manifest" && ! -L "$manifest" ]] || die "Manifest payload hilang atau tidak aman"
  if find "$ROOT_DIR/payload" "$ROOT_DIR/scripts/lib" -type l -print -quit | grep -q .; then
    die "Payload mengandung symlink"
  fi
  (cd "$ROOT_DIR" && sha256sum --check manifest/payload.sha256 >/dev/null)
  sha256_check dcf0f4defb744d4b0d619d54b982463810d8926a89e40741d9a75cf2572750d4 \
    "$ROOT_DIR/payload/todotools/package-lock.json"
  sha256_check c6f29463dddf3388321f5f51463deb80e434511b889ab0cbffcf2e58bf735b6f \
    "$ROOT_DIR/payload/todotools/todotools-security.patch"
  python3 -m json.tool "$ROOT_DIR/manifest/source-lock.json" >/dev/null
  python3 -m json.tool "$ROOT_DIR/manifest/astral-selection.json" >/dev/null
  python3 - "$ROOT_DIR/manifest/astral-selection.json" <<'PY'
import json, sys
skills=json.load(open(sys.argv[1]))['skills']
if len(skills) != 16 or len({s['destination_name'] for s in skills}) != 16:
    raise SystemExit('Manifest AstralForge harus memuat tepat 16 skill unik')
PY
}

verify_payload
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/repackmyskill.XXXXXXXX")
BACKUP_DIR="$PI_HOME/backups/repackmyskill-$(date +%Y%m%d-%H%M%S)-$$"

log_info "ROOT_DIR: $ROOT_DIR"
log_info "PI_HOME: $PI_HOME"
log_info "Backup: $BACKUP_DIR"
if [[ "$DRY_RUN" == 1 ]]; then
  log_info "Mode dry-run; PI_HOME tidak akan diubah atau dibaca melalui pi"
elif [[ "$ASSUME_YES" != 1 ]]; then
  printf 'Lanjutkan instalasi ke %s? [y/N] ' "$PI_HOME"
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]] || die "Instalasi dibatalkan"
fi

if [[ "$DRY_RUN" != 1 ]]; then
  # Read local Pi command contract before package mutation; official removal uses
  # `pi remove`, recorded packages are restored only through that command.
  pi --help >/dev/null
  mkdir -p -- "$PI_HOME" "$BACKUP_DIR"
  transaction_begin install
fi

record_pi_package_metadata() {
  local path
  # Pi records installed package references in metadata. New packages are
  # removed by official `pi remove` during failed transactions; avoid backing
  # up broad package roots that may be user-managed.
  for path in "$PI_HOME/settings.json" "$PI_HOME/package.json" "$PI_HOME/package-lock.json"; do
    transaction_record_path "$path"
  done
}

install_pi_packages() {
  local listing spec
  local specs=(
    'npm:pi-9router-ext@0.2.2'
    'npm:@tintinweb/pi-subagents@0.13.0'
    'npm:pi-plan-extension@0.1.0'
    'git:github.com/code-yeongyu/pi-todotools@93ba67efa5a7358356a829569365bb017a8ad498'
  )
  if [[ "$DRY_RUN" == 1 ]]; then
    for spec in "${specs[@]}"; do log_info "Pastikan package pinned tersedia: $spec"; done
    return 0
  fi
  record_pi_package_metadata
  listing=$(pi list 2>&1) || die "Gagal membaca package dengan pi list"
  for spec in "${specs[@]}"; do
    if package_is_installed "$spec" "$listing"; then
      log_info "Package sudah terpasang: $spec"
    else
      log_info "Pasang package: $spec"
      transaction_record_package "$spec"
      retry_once pi install "$spec"
    fi
  done
}

find_todotools_checkout() {
  local listing checkout
  listing=$(pi list 2>&1) || die "Gagal membaca pi list setelah instalasi Todo Tools"
  checkout=$(awk '
    $0 ~ /^[[:space:]]*git:github.com\/code-yeongyu\/pi-todotools@93ba67/ {wanted=1; next}
    wanted && $0 ~ /^[[:space:]]*\// {sub(/^[[:space:]]*/, ""); print; exit}
  ' <<<"$listing")
  [[ -n "$checkout" ]] || checkout="$PI_HOME/git/github.com/code-yeongyu/pi-todotools"
  printf '%s\n' "$checkout"
}

package_added_this_transaction() {
  local spec=$1
  [[ -f "${TX_PACKAGES_FILE:-}" ]] && grep -Fqx -- "$spec" "$TX_PACKAGES_FILE"
}

configure_todotools() {
  local checkout todo_spec='git:github.com/code-yeongyu/pi-todotools@93ba67efa5a7358356a829569365bb017a8ad498'
  if [[ "$DRY_RUN" == 1 ]]; then
    log_info "Todo Tools: lockfile aman, npm ci --ignore-scripts --omit=dev, audit high/critical"
    return 0
  fi
  checkout=$(find_todotools_checkout)
  assert_within_pi_home "$checkout"
  [[ -d "$checkout/.git" && ! -L "$checkout" ]] || die "Checkout Todo Tools tidak ditemukan: $checkout"
  [[ "$(git -C "$checkout" rev-parse HEAD)" == '93ba67efa5a7358356a829569365bb017a8ad498' ]] || die "Commit Todo Tools tidak sesuai"
  if package_added_this_transaction "$todo_spec"; then
    # `pi remove` removes a checkout created by this transaction. Do not keep
    # a post-install upstream lockfile backup that could recreate it on fail.
    atomic_copy_file "$ROOT_DIR/payload/todotools/package-lock.json" "$checkout/package-lock.json"
  else
    transaction_record_path "$checkout/node_modules"
    copy_file_safe "$ROOT_DIR/payload/todotools/package-lock.json" "$checkout/package-lock.json"
  fi
  sha256_check dcf0f4defb744d4b0d619d54b982463810d8926a89e40741d9a75cf2572750d4 "$checkout/package-lock.json"
  (cd "$checkout" && npm ci --ignore-scripts --omit=dev)
  (cd "$checkout" && npm audit --omit=dev --audit-level=high)
}

install_astral() {
  local repo commit clone_dir
  repo=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["repository"])' "$ROOT_DIR/manifest/astral-selection.json")
  commit=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["commit"])' "$ROOT_DIR/manifest/astral-selection.json")
  clone_dir="$TEMP_DIR/astralforge"
  if [[ "$DRY_RUN" == 1 ]]; then
    log_info "AstralForge: clone $repo @ $commit; salin tepat 16 skill transformed"
    return 0
  fi
  retry_once git clone --no-checkout --filter=blob:none -- "$repo" "$clone_dir"
  git -C "$clone_dir" checkout --detach "$commit"
  [[ "$(git -C "$clone_dir" rev-parse HEAD)" == "$commit" ]] || die "Commit AstralForge tidak sesuai"
  python3 - "$ROOT_DIR/manifest/astral-selection.json" "$clone_dir" "$TEMP_DIR/astral-prepared" <<'PY'
import json, re, shutil, sys
from pathlib import Path
manifest, clone, prepared = map(Path, sys.argv[1:])
data=json.loads(manifest.read_text())
for skill in data['skills']:
    source=clone/skill['source_directory']; destination=prepared/skill['destination_directory']
    if not (source/'SKILL.md').is_file() or any(p.is_symlink() for p in source.rglob('*')):
        raise SystemExit(f'Source Astral tidak aman: {source}')
    shutil.copytree(source,destination)
    path=destination/'SKILL.md'; text=path.read_text()
    match=re.search(r'(?m)^name:\s*.*$',text)
    if not match or match.start() > text.find('---',3): raise SystemExit(f'Frontmatter name hilang: {path}')
    path.write_text(text[:match.start()] + f"name: {skill['transform']['frontmatter_name']}" + text[match.end():])
PY
  while IFS= read -r destination; do
    copy_tree_safe "$TEMP_DIR/astral-prepared/$destination" "$PI_HOME/$destination"
  done < <(python3 - "$ROOT_DIR/manifest/astral-selection.json" <<'PY'
import json,sys
for item in json.load(open(sys.argv[1]))['skills']: print(item['destination_directory'])
PY
)
  python3 - "$ROOT_DIR/manifest/astral-selection.json" "$PI_HOME" <<'PY'
import json,pathlib,re,sys
items=json.load(open(sys.argv[1]))['skills']; root=pathlib.Path(sys.argv[2])
for item in items:
 p=root/item['destination_directory']/'SKILL.md'
 if not p.is_file() or not re.search(rf'(?m)^name:\s*["\']?{re.escape(item["destination_name"])}["\']?\s*$',p.read_text()): raise SystemExit(f'Astral validation failed: {p}')
print('Astral verification: 16/16')
PY
}

install_grill() {
  local repo='https://github.com/mattpocock/skills.git' commit='391a2701dd948f94f56a39f7533f8eea9a859c87'
  local clone_dir="$TEMP_DIR/mattpocock-skills"
  if [[ "$DRY_RUN" == 1 ]]; then
    log_info "Grill Me: clone $repo @ $commit; salin grill-me dan grilling"
    return 0
  fi
  retry_once git clone --no-checkout --filter=blob:none -- "$repo" "$clone_dir"
  git -C "$clone_dir" checkout --detach "$commit"
  [[ "$(git -C "$clone_dir" rev-parse HEAD)" == "$commit" ]] || die "Commit Grill Me tidak sesuai"
  copy_tree_safe "$clone_dir/skills/productivity/grill-me" "$PI_HOME/skills/grill-me"
  copy_tree_safe "$clone_dir/skills/productivity/grilling" "$PI_HOME/skills/grilling"
  [[ -f "$PI_HOME/skills/grill-me/SKILL.md" && -f "$PI_HOME/skills/grilling/SKILL.md" ]] || die "Verifikasi Grill Me gagal"
}

install_impeccable() {
  if [[ "$DRY_RUN" == 1 ]]; then
    log_info "Impeccable: CLI 3.2.1; provider Pi; global scope; tanpa hooks"
    return 0
  fi
  transaction_record_path "$PI_HOME/skills/impeccable"
  retry_once npx --yes impeccable@3.2.1 skills install -y --providers=pi --scope=global --no-hooks
  local skill="$PI_HOME/skills/impeccable/SKILL.md" version
  [[ -f "$skill" && ! -L "$skill" ]] || die "SKILL.md Impeccable tidak ditemukan"
  version=$(awk -F: '/^version:[[:space:]]*/ {sub(/^[[:space:]]*/, "", $2); print $2; exit}' "$skill")
  [[ -n "$version" ]] || die "Versi skill Impeccable tidak ditemukan"
  python3 - "$skill" <<'PY'
from pathlib import Path
import re,sys
if not re.search(r'(?m)^name:\s*["\x27]?impeccable["\x27]?\s*$',Path(sys.argv[1]).read_text()): raise SystemExit('Frontmatter Impeccable tidak sesuai')
PY
  log_info "Impeccable CLI 3.2.1; skill $version; snapshot audit 3.9.1"
}

install_custom_payload() {
  local source relative
  while IFS= read -r -d '' source; do
    relative=${source#"$ROOT_DIR/payload/custom/"}
    [[ "$relative" == 'AGENTS.md' ]] && continue
    copy_file_safe "$source" "$PI_HOME/$relative"
  done < <(find "$ROOT_DIR/payload/custom" -type f -print0 | LC_ALL=C sort -z)
  upsert_marked_block "$PI_HOME/AGENTS.md" "$ROOT_DIR/payload/managed/AGENTS.repack.md"
}

build_state() {
  local state_input="$TEMP_DIR/state.json"
  python3 - "$ROOT_DIR" "$PI_HOME" "$state_input" "$BACKUP_DIR" "$SKIP_ASTRAL" "$SKIP_GRILL" "$SKIP_IMPECCABLE" "$TX_PACKAGES_FILE" <<'PY'
import datetime, hashlib, json, os, sys
from pathlib import Path
root, pi, out, backup = map(Path, sys.argv[1:5])
skip_astral,skip_grill,skip_impeccable=(x=='1' for x in sys.argv[5:8])
packages_added=Path(sys.argv[8]).read_text().splitlines() if Path(sys.argv[8]).exists() else []
def digest(p):
 if p.is_symlink(): raise SystemExit(f'Symlink managed path: {p}')
 return hashlib.sha256(p.read_bytes()).hexdigest()
def add_path(paths,p):
 if p.is_file(): paths.append({'path':p.relative_to(pi).as_posix(),'sha256':digest(p)})
def add_tree(paths,p):
 if not p.exists(): return
 if p.is_symlink(): raise SystemExit(f'Symlink managed tree: {p}')
 for q in sorted(p.rglob('*')):
  if q.is_file(): add_path(paths,q)
managed=[]
for source in sorted((root/'payload/custom').rglob('*')):
 if source.is_file() and source.relative_to(root/'payload/custom').as_posix() != 'AGENTS.md': add_path(managed,pi/source.relative_to(root/'payload/custom'))
add_path(managed,pi/'AGENTS.md')
add_path(managed,pi/'git/github.com/code-yeongyu/pi-todotools/package-lock.json')
if not skip_astral:
 for item in json.loads((root/'manifest/astral-selection.json').read_text())['skills']: add_tree(managed,pi/item['destination_directory'])
if not skip_grill:
 add_tree(managed,pi/'skills/grill-me'); add_tree(managed,pi/'skills/grilling')
if not skip_impeccable: add_tree(managed,pi/'skills/impeccable')
packages=[x['specifier'] for x in json.loads((root/'manifest/source-lock.json').read_text())['packages']]
packages.append('git:github.com/code-yeongyu/pi-todotools@93ba67efa5a7358356a829569365bb017a8ad498')
previous=[]
old_state=pi/'.repackmyskill'/'state.json'
if old_state.is_file():
 try: previous=json.loads(old_state.read_text()).get('packages_installed_by_repack',[])
 except (OSError,json.JSONDecodeError): previous=[]
packages_added=sorted(set(previous+packages_added))
state={
 'schema_version':'1.0.0','installer_version':'1.0.0',
 'installed_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'repository':'https://github.com/kuker24/RepackMyskill.git',
 'package_specs':packages,
 'packages_installed_by_repack':packages_added,
 'third_party_commits':{'pi-todotools':'93ba67efa5a7358356a829569365bb017a8ad498','astralforge':'3f59d793a2691a95e63355f91adaeb72a7120fac','mattpocock-skills':'391a2701dd948f94f56a39f7533f8eea9a859c87','impeccable_cli':'3.2.1'},
 'managed_files':managed,
 'agents_marker':{'start':'<!-- REPACKMYSKILL:START -->','end':'<!-- REPACKMYSKILL:END -->','count':1},
 'backup_directory':str(backup),
 'skipped_components':{'astral':skip_astral,'grill':skip_grill,'impeccable':skip_impeccable},
 'verification':{'payload_sha256':'PASS','custom_files':'PASS','todotools_audit':'PASS','astral':'SKIP' if skip_astral else 'PASS','grill':'SKIP' if skip_grill else 'PASS','impeccable':'SKIP' if skip_impeccable else 'PASS'}
}
out.write_text(json.dumps(state,indent=2,sort_keys=True)+'\n')
PY
  write_state_atomic "$state_input"
}

install_pi_packages
configure_todotools
if [[ "$SKIP_ASTRAL" == 1 ]]; then log_warn "AstralForge dilewati"; else install_astral; fi
if [[ "$SKIP_GRILL" == 1 ]]; then log_warn "Grill Me dilewati"; else install_grill; fi
if [[ "$SKIP_IMPECCABLE" == 1 ]]; then log_warn "Impeccable dilewati"; else install_impeccable; fi
install_custom_payload
if [[ "$DRY_RUN" != 1 ]]; then
  build_state
  state_is_valid || die "State instalasi tidak valid setelah ditulis"
  transaction_finalize
fi

log_info "Instalasi selesai. Backup: $BACKUP_DIR"
cat <<'EOF'
Langkah berikut:
1. Jalankan Pi Coding Agent.
2. Gunakan /reload untuk memuat extension, skill, agent, dan prompt.
3. Jalankan /9router-config; credential tidak dibundel oleh RepackMyskill.
EOF
