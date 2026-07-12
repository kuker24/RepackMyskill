#!/usr/bin/env bash
# Shared RepackMyskill lifecycle helpers. Source from top-level scripts only.

REPACK_SCHEMA_VERSION='1.0.0'
REPACK_INSTALLER_VERSION='1.0.0'
REPACK_MARKER_START='<!-- REPACKMYSKILL:START -->'
REPACK_MARKER_END='<!-- REPACKMYSKILL:END -->'
REPACK_STATE_REL='.repackmyskill/state.json'

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }
die() { log_error "$*"; return 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }
require_command() { command_exists "$1" || die "Command wajib tidak tersedia: $1"; }

quote_command() {
  printf '  '
  printf '%q ' "$@"
  printf '\n'
}

run() {
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    printf '[DRY-RUN] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

retry_once() {
  "$@" || {
    local status=$?
    log_warn "Command gagal; retry satu kali"
    "$@" || return $status
  }
}

resolve_pi_home() {
  PI_HOME=$(python3 - "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).expanduser().resolve(strict=False))
PY
)
  export PI_CODING_AGENT_DIR="$PI_HOME"
  STATE_PATH="$PI_HOME/$REPACK_STATE_REL"
}

assert_within_pi_home() {
  local candidate=$1
  python3 - "$PI_HOME" "$candidate" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1]).expanduser().resolve(strict=False)
path = Path(sys.argv[2]).expanduser()
# Resolve parent to reject a symlinked parent escaping PI_HOME. Do not resolve a
# missing final path, because callers may legitimately create it.
resolved = path.parent.resolve(strict=False) / path.name
try:
    resolved.relative_to(root)
except ValueError:
    raise SystemExit(f'Path keluar dari PI_HOME: {path}')
PY
}

relative_pi_path() {
  python3 - "$PI_HOME" "$1" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1]).resolve(strict=False)
path=Path(sys.argv[2]).resolve(strict=False)
print(path.relative_to(root).as_posix())
PY
}

sha256_check() {
  local expected=$1 file=$2 actual
  [[ -f "$file" && ! -L "$file" ]] || die "File checksum tidak aman atau hilang: $file"
  actual=$(sha256sum -- "$file" | awk '{print $1}')
  [[ "$actual" == "$expected" ]] || die "Checksum berbeda: $file"
}

path_digest() {
  local path=$1
  python3 - "$path" <<'PY'
from hashlib import sha256
from pathlib import Path
import sys
p=Path(sys.argv[1])
if p.is_symlink():
    raise SystemExit('Symlink tidak aman untuk checksum')
if not p.exists():
    print('MISSING')
elif p.is_file():
    print(sha256(p.read_bytes()).hexdigest())
elif p.is_dir():
    h=sha256()
    for item in sorted(p.rglob('*')):
        rel=item.relative_to(p).as_posix().encode()
        # Nested package-manager links (for example node_modules/.bin) are
        # data, not target paths. Hash link text without dereferencing it.
        if item.is_symlink():
            h.update(rel + b'\0link\0' + item.readlink().as_posix().encode() + b'\n')
        elif item.is_file():
            h.update(rel + b'\0file\0' + sha256(item.read_bytes()).hexdigest().encode() + b'\n')
    print(h.hexdigest())
else:
    raise SystemExit(f'Path bukan file/direktori: {p}')
PY
}

atomic_copy_file() {
  local source=$1 destination=$2 mode=${3:-}
  [[ -f "$source" && ! -L "$source" ]] || die "Sumber bukan regular file aman: $source"
  assert_within_pi_home "$destination"
  [[ ! -L "$destination" ]] || die "Target symlink ditolak: $destination"
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    log_info "Copy: $source -> $destination"
    return 0
  fi
  mkdir -p -- "$(dirname -- "$destination")"
  local temp
  temp=$(mktemp "$(dirname -- "$destination")/.repackmyskill.XXXXXXXX")
  if [[ -n "$mode" ]]; then
    install -m "$mode" -- "$source" "$temp"
  else
    install -m "$(stat -c '%a' "$source")" -- "$source" "$temp"
  fi
  mv -f -- "$temp" "$destination"
}

safe_remove_path() {
  local target=$1
  assert_within_pi_home "$target"
  [[ ! -L "$target" ]] || die "Target symlink ditolak: $target"
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    log_info "Remove: $target"
    return 0
  fi
  rm -rf -- "$target"
}

transaction_begin() {
  local operation=$1
  TX_OPERATION=$operation
  TX_ACTIVE=1
  TX_FAILED=0
  TX_ENTRIES_FILE="$BACKUP_DIR/.entries.tsv"
  TX_PACKAGES_FILE="$BACKUP_DIR/.packages.tsv"
  mkdir -p -- "$BACKUP_DIR/files"
  : > "$TX_ENTRIES_FILE"
  : > "$TX_PACKAGES_FILE"
  write_backup_manifest
}

declare -A TX_RECORDED=()
transaction_record_path() {
  local source=$1 relative existed kind old_digest backup
  assert_within_pi_home "$source"
  relative=$(relative_pi_path "$source")
  [[ -z "${TX_RECORDED[$relative]:-}" ]] || return 0
  TX_RECORDED[$relative]=1
  if [[ -L "$source" ]]; then
    die "Menolak target symlink: $source"
  fi
  if [[ -e "$source" ]]; then
    existed=true
    [[ -f "$source" ]] && kind=file || kind=directory
    old_digest=$(path_digest "$source")
    backup="$BACKUP_DIR/files/$relative"
    if [[ "${DRY_RUN:-0}" == 1 ]]; then
      log_info "Backup: $source -> $backup"
    else
      mkdir -p -- "$(dirname -- "$backup")"
      cp -a --no-dereference -- "$source" "$backup"
    fi
  else
    existed=false
    kind=missing
    old_digest=''
  fi
  if [[ "${DRY_RUN:-0}" != 1 ]]; then
    printf '%s\t%s\t%s\t%s\n' "$relative" "$existed" "$kind" "$old_digest" >> "$TX_ENTRIES_FILE"
    write_backup_manifest
  fi
}

transaction_record_package() {
  local spec=$1
  [[ "${DRY_RUN:-0}" == 1 ]] && return 0
  grep -Fqx -- "$spec" "$TX_PACKAGES_FILE" 2>/dev/null || printf '%s\n' "$spec" >> "$TX_PACKAGES_FILE"
  write_backup_manifest
}

write_backup_manifest() {
  [[ "${DRY_RUN:-0}" == 1 ]] && return 0
  python3 - "$BACKUP_DIR" "$PI_HOME" "${TX_OPERATION:-unknown}" "${TX_ENTRIES_FILE:-}" "${TX_PACKAGES_FILE:-}" <<'PY'
import datetime, json, os, tempfile
from hashlib import sha256
from pathlib import Path
import sys
backup=Path(sys.argv[1]); root=Path(sys.argv[2]); operation=sys.argv[3]
entries_file=Path(sys.argv[4]); packages_file=Path(sys.argv[5])
def digest(path):
    if not path.exists(): return None
    if path.is_symlink(): raise SystemExit(f'Symlink in manifest target: {path}')
    if path.is_file(): return sha256(path.read_bytes()).hexdigest()
    h=sha256()
    for child in sorted(path.rglob('*')):
        rel=child.relative_to(path).as_posix().encode()
        if child.is_symlink(): h.update(rel+b'\0link\0'+child.readlink().as_posix().encode()+b'\n')
        elif child.is_file(): h.update(rel+b'\0file\0'+sha256(child.read_bytes()).hexdigest().encode()+b'\n')
    return h.hexdigest()
entries=[]
if entries_file.exists():
    for line in entries_file.read_text().splitlines():
        rel, existed, kind, old = line.split('\t')
        target=root/rel
        entries.append({'path':rel,'existed':existed=='true','kind':kind,'original_sha256':old or None,'installed_sha256':digest(target)})
packages=packages_file.read_text().splitlines() if packages_file.exists() else []
data={
 'schema_version':'1.0.0','operation':operation,
 'created_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'pi_home':str(root),'entries':entries,
 'created_files':[e['path'] for e in entries if not e['existed']],
 'overwritten_files':[e['path'] for e in entries if e['existed']],
 'packages_installed_by_operation':packages,
}
path=backup/'manifest.json'; fd,tmp=tempfile.mkstemp(prefix='.manifest.',dir=backup); os.close(fd)
Path(tmp).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n'); os.replace(tmp,path)
PY
}

transaction_finalize() {
  [[ "${DRY_RUN:-0}" == 1 ]] && return 0
  write_backup_manifest
  rm -f -- "$TX_ENTRIES_FILE" "$TX_PACKAGES_FILE"
  TX_ACTIVE=0
}

restore_path_from_backup() {
  local relative=$1 existed=$2
  local target="$PI_HOME/$relative" backup="$BACKUP_DIR/files/$relative"
  assert_within_pi_home "$target"
  [[ ! -L "$target" ]] || die "Target symlink ditolak saat restore: $target"
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    log_info "Restore: $target"
    return 0
  fi
  rm -rf -- "$target"
  if [[ "$existed" == true ]]; then
    [[ -e "$backup" && ! -L "$backup" ]] || die "Backup hilang atau symlink: $backup"
    mkdir -p -- "$(dirname -- "$target")"
    if [[ -f "$backup" ]]; then
      local temp
      temp=$(mktemp "$(dirname -- "$target")/.repackmyskill.restore.XXXXXXXX")
      cp -a --no-dereference -- "$backup" "$temp"
      mv -f -- "$temp" "$target"
    else
      cp -a --no-dereference -- "$backup" "$target"
    fi
  fi
}

transaction_rollback() {
  [[ "${TX_ACTIVE:-0}" == 1 && "${DRY_RUN:-0}" != 1 ]] || return 0
  log_warn "Mengembalikan perubahan filesystem dari transaksi gagal"
  # Remove only packages installed in this transaction first. Restoring Pi
  # metadata afterwards prevents package removal from overwriting backup state.
  if [[ -f "$TX_PACKAGES_FILE" ]] && command_exists pi; then
    local spec
    while IFS= read -r spec; do
      [[ -n "$spec" ]] || continue
      if ! pi remove "$spec"; then
        log_warn "Package perlu ditangani manual: $spec"
      fi
    done < "$TX_PACKAGES_FILE"
  fi
  if [[ -f "$TX_ENTRIES_FILE" ]]; then
    local -a lines=()
    mapfile -t lines < "$TX_ENTRIES_FILE"
    local idx line relative existed _kind _old
    for ((idx=${#lines[@]}-1; idx>=0; idx--)); do
      line=${lines[$idx]}
      IFS=$'\t' read -r relative existed _kind _old <<< "$line"
      restore_path_from_backup "$relative" "$existed" || log_error "Restore gagal: $relative"
    done
  fi
  write_backup_manifest || true
  TX_ACTIVE=0
}

copy_file_safe() {
  local source=$1 destination=$2
  [[ -f "$source" && ! -L "$source" ]] || die "Sumber bukan regular file aman: $source"
  transaction_record_path "$destination"
  atomic_copy_file "$source" "$destination"
}

copy_tree_safe() {
  local source=$1 destination=$2
  [[ -d "$source" && ! -L "$source" ]] || die "Sumber bukan direktori aman: $source"
  if find "$source" -type l -print -quit | grep -q .; then
    die "Symlink dalam source tree ditolak: $source"
  fi
  transaction_record_path "$destination"
  assert_within_pi_home "$destination"
  [[ ! -L "$destination" ]] || die "Target symlink ditolak: $destination"
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    log_info "Copy tree: $source -> $destination"
    return 0
  fi
  mkdir -p -- "$destination"
  cp -a --no-dereference -- "$source"/. "$destination"/
}

upsert_marked_block() {
  local target=$1 fragment=$2
  [[ -f "$fragment" && ! -L "$fragment" ]] || die "Fragment marker tidak aman: $fragment"
  transaction_record_path "$target"
  assert_within_pi_home "$target"
  [[ ! -L "$target" ]] || die "Target marker symlink ditolak: $target"
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    log_info "Upsert marker REPACKMYSKILL: $target"
    return 0
  fi
  mkdir -p -- "$(dirname -- "$target")"
  python3 - "$target" "$fragment" <<'PY'
from pathlib import Path
import os, tempfile, sys
start = '<!-- REPACKMYSKILL:START -->'; end = '<!-- REPACKMYSKILL:END -->'
target, fragment = map(Path, sys.argv[1:])
block = fragment.read_text()
if block.count(start) != 1 or block.count(end) != 1 or block.index(start) > block.index(end):
    raise SystemExit('Fragment marker tidak valid')
text = target.read_text() if target.exists() else ''
starts, ends = text.count(start), text.count(end)
if starts != ends or starts > 1:
    raise SystemExit('Marker target rusak atau ganda; hentikan untuk melindungi file pengguna')
if starts == 1:
    before, rest = text.split(start, 1); _, after = rest.split(end, 1)
    output = before + block.rstrip() + after
else:
    separator = '' if not text else ('\n' if text.endswith('\n') else '\n\n')
    output = text + separator + block.rstrip() + '\n'
fd, tmp = tempfile.mkstemp(prefix='.repackmyskill.', dir=target.parent); os.close(fd)
Path(tmp).write_text(output); os.replace(tmp, target)
PY
}

remove_marked_block() {
  local target=$1
  assert_within_pi_home "$target"
  [[ -f "$target" && ! -L "$target" ]] || return 0
  transaction_record_path "$target"
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    log_info "Remove marker REPACKMYSKILL: $target"
    return 0
  fi
  python3 - "$target" <<'PY'
from pathlib import Path
import os, tempfile, sys
p=Path(sys.argv[1]); start='<!-- REPACKMYSKILL:START -->'; end='<!-- REPACKMYSKILL:END -->'
text=p.read_text(); starts, ends=text.count(start), text.count(end)
if starts != ends or starts > 1: raise SystemExit('Marker target rusak atau ganda')
if starts == 0: raise SystemExit('Marker RepackMyskill tidak ditemukan')
before, rest=text.split(start,1); _, after=rest.split(end,1)
output=(before.rstrip()+after).strip()
if output: output+='\n'
fd,tmp=tempfile.mkstemp(prefix='.repackmyskill.',dir=p.parent); os.close(fd)
Path(tmp).write_text(output); os.replace(tmp,p)
PY
}

package_is_installed() {
  local spec=$1 listing=${2:-}
  grep -F -- "$spec" <<< "$listing" >/dev/null 2>&1
}

state_is_valid() {
  [[ -f "$STATE_PATH" && ! -L "$STATE_PATH" ]] || return 1
  python3 - "$STATE_PATH" <<'PY'
import json, sys
x=json.load(open(sys.argv[1]))
required={'schema_version','installer_version','installed_at','repository','package_specs','third_party_commits','managed_files','agents_marker','backup_directory','skipped_components','verification'}
missing=required-x.keys()
if missing or x['schema_version']!='1.0.0' or not isinstance(x['managed_files'],list):
 raise SystemExit('State tidak memenuhi schema')
PY
}

write_state_atomic() {
  local state_input=$1
  transaction_record_path "$STATE_PATH"
  [[ "${DRY_RUN:-0}" == 1 ]] && { log_info "Write state: $STATE_PATH"; return 0; }
  python3 - "$state_input" "$STATE_PATH" <<'PY'
import json, os, tempfile, sys
source, target = map(__import__('pathlib').Path, sys.argv[1:])
data=json.loads(source.read_text())
target.parent.mkdir(parents=True,exist_ok=True)
fd,tmp=tempfile.mkstemp(prefix='.state.',dir=target.parent); os.close(fd)
__import__('pathlib').Path(tmp).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
os.replace(tmp,target)
PY
}

backup_manifest_is_valid() {
  local backup=$1
  [[ -f "$backup/manifest.json" && ! -L "$backup/manifest.json" ]] || return 1
  python3 - "$backup/manifest.json" <<'PY'
import json, pathlib, sys
x=json.load(open(sys.argv[1]))
if x.get('schema_version')!='1.0.0' or not isinstance(x.get('entries'),list): raise SystemExit('Manifest backup tidak valid')
for e in x['entries']:
 p=pathlib.PurePosixPath(e['path'])
 if p.is_absolute() or '..' in p.parts or not e['path']: raise SystemExit('Path manifest backup tidak aman')
PY
}

rollback_backup() {
  local backup=$1
  backup_manifest_is_valid "$backup" || die "Manifest backup tidak valid: $backup"
  python3 - "$backup/manifest.json" "$PI_HOME" "${STATE_PATH:-$PI_HOME/$REPACK_STATE_REL}" "$DRY_RUN" <<'PY'
import json, shutil, sys
from hashlib import sha256
from pathlib import Path
manifest,root,state,dry=Path(sys.argv[1]),Path(sys.argv[2]),Path(sys.argv[3]),sys.argv[4]=='1'
x=json.loads(manifest.read_text())
def digest(path):
 if not path.exists(): return None
 if path.is_symlink(): raise RuntimeError(f'Symlink target: {path}')
 if path.is_file(): return sha256(path.read_bytes()).hexdigest()
 h=sha256()
 for q in sorted(path.rglob('*')):
  rel=q.relative_to(path).as_posix().encode()
  if q.is_symlink(): h.update(rel+b'\0link\0'+q.readlink().as_posix().encode()+b'\n')
  elif q.is_file(): h.update(rel+b'\0file\0'+sha256(q.read_bytes()).hexdigest().encode()+b'\n')
 return h.hexdigest()
for e in reversed(x['entries']):
 rel=Path(e['path']); target=root/rel; expected=e.get('installed_sha256'); current=digest(target)
 if current != expected:
  print(f'WARN\t{rel}\tmodified; preserved', file=sys.stderr); continue
 print(f'RESTORE\t{rel}')
 if dry: continue
 if target.exists():
  if target.is_dir(): shutil.rmtree(target)
  else: target.unlink()
 if e['existed']:
  source=Path(manifest.parent)/'files'/rel
  target.parent.mkdir(parents=True,exist_ok=True)
  if source.is_file():
   temp=target.with_name('.repackmyskill.restore.tmp')
   shutil.copy2(source,temp); temp.replace(target)
  else: shutil.copytree(source,target,symlinks=True)
PY
}

cleanup() {
  local status=$?
  if (( status != 0 )) && [[ "${TX_ACTIVE:-0}" == 1 ]]; then
    transaction_rollback || true
  fi
  if [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR:-}" ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
  if (( status != 0 )) && [[ -n "${BACKUP_DIR:-}" ]]; then
    log_error "Operasi gagal. Backup: $BACKUP_DIR"
  fi
  return "$status"
}
