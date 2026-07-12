#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DRY_RUN=0
ASSUME_YES=0
KEEP_PACKAGES=0
TEMP_DIR=''
BACKUP_DIR=''
TX_ACTIVE=0
# shellcheck source=scripts/lib/common.sh
source "$ROOT_DIR/scripts/lib/common.sh"
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: bash uninstall.sh [options]

Remove only paths recorded in RepackMyskill state. User changes are preserved.

Options:
  --dry-run        Print actions without changing PI_HOME
  --yes            Skip confirmation
  --keep-packages  Do not remove packages installed by RepackMyskill
  --help           Show this help
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
    --keep-packages) KEEP_PACKAGES=1 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; die "Opsi tidak dikenal: $1" ;;
  esac
  shift
done

for required in bash pi python3 sha256sum; do require_command "$required"; done
resolve_pi_home
state_is_valid || die "State instalasi tidak valid atau hilang: $STATE_PATH"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/repackmyskill-uninstall.XXXXXXXX")
BACKUP_DIR="$PI_HOME/backups/repackmyskill-uninstall-$(date +%Y%m%d-%H%M%S)-$$"

if [[ "$DRY_RUN" == 1 ]]; then
  log_info "Mode dry-run; PI_HOME tidak diubah"
elif [[ "$ASSUME_YES" != 1 ]]; then
  printf 'Hapus file RepackMyskill dari %s? [y/N] ' "$PI_HOME"
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]] || die 'Uninstall dibatalkan'
fi

if [[ "$DRY_RUN" != 1 ]]; then
  pi --help >/dev/null
  mkdir -p -- "$BACKUP_DIR"
  transaction_begin uninstall
fi

mapfile -t managed_rows < <(python3 - "$STATE_PATH" <<'PY'
import json,sys
for item in json.load(open(sys.argv[1]))['managed_files']:
 print(item['path']+'\t'+item['sha256'])
PY
)

for row in "${managed_rows[@]}"; do
  IFS=$'\t' read -r relative expected <<< "$row"
  [[ "$relative" == AGENTS.md ]] && continue
  target="$PI_HOME/$relative"
  [[ -e "$target" ]] || continue
  current=$(path_digest "$target")
  if [[ "$current" != "$expected" ]]; then
    transaction_record_path "$target"
    log_warn "File berubah oleh pengguna; dipertahankan dan disalin ke backup: $relative"
  else
    transaction_record_path "$target"
    safe_remove_path "$target"
  fi
done

agents="$PI_HOME/AGENTS.md"
if [[ -f "$agents" ]]; then
  transaction_record_path "$agents"
  if [[ "$DRY_RUN" == 1 ]]; then
    log_info "Hapus hanya marker block: $agents"
  else
    remove_marked_block "$agents"
  fi
fi

if [[ "$KEEP_PACKAGES" == 1 ]]; then
  log_info 'Package dipertahankan oleh --keep-packages'
elif [[ "$DRY_RUN" == 1 ]]; then
  log_info 'Package yang dipasang RepackMyskill akan dihapus memakai pi remove'
else
  # `pi remove` changes Pi package metadata. Record only metadata files before
  # official package removal; package source is removed by Pi itself.
  for metadata in "$PI_HOME/settings.json" "$PI_HOME/package.json" "$PI_HOME/package-lock.json"; do
    transaction_record_path "$metadata"
  done
  mapfile -t added_packages < <(python3 - "$STATE_PATH" <<'PY'
import json,sys
for item in json.load(open(sys.argv[1])).get('packages_installed_by_repack',[]): print(item)
PY
)
  for spec in "${added_packages[@]}"; do
    [[ -n "$spec" ]] || continue
    if pi remove "$spec"; then
      log_info "Package dihapus: $spec"
    else
      log_warn "Package tersisa; tangani manual dengan: pi remove $spec"
    fi
  done
fi

transaction_record_path "$STATE_PATH"
safe_remove_path "$STATE_PATH"
if [[ "$DRY_RUN" != 1 ]]; then transaction_finalize; fi
log_info "Uninstall selesai. Backup: $BACKUP_DIR"
