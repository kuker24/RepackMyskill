#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DRY_RUN=0
ASSUME_YES=0
REQUESTED_BACKUP=''
TEMP_DIR=''
BACKUP_DIR=''
TX_ACTIVE=0
# shellcheck source=scripts/lib/common.sh
source "$ROOT_DIR/scripts/lib/common.sh"
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: bash rollback.sh [options]

Restore one validated RepackMyskill backup. Modified user files are preserved.

Options:
  --backup <path>  Backup directory; defaults to backup_directory from state
  --dry-run        Print restore actions without changing PI_HOME
  --yes            Skip confirmation
  --help           Show this help
EOF
}

while (($#)); do
  case "$1" in
    --backup)
      (($# >= 2)) || die '--backup membutuhkan path'
      REQUESTED_BACKUP=$2; shift ;;
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; die "Opsi tidak dikenal: $1" ;;
  esac
  shift
done

for required in bash python3 sha256sum; do require_command "$required"; done
resolve_pi_home
if [[ -n "$REQUESTED_BACKUP" ]]; then
  BACKUP_DIR=$(python3 - "$REQUESTED_BACKUP" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).expanduser().resolve(strict=False))
PY
)
elif state_is_valid; then
  BACKUP_DIR=$(python3 - "$STATE_PATH" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))['backup_directory'])
PY
)
else
  die 'State hilang; gunakan --backup <path>'
fi

[[ -d "$BACKUP_DIR" && ! -L "$BACKUP_DIR" ]] || die "Backup tidak aman atau hilang: $BACKUP_DIR"
backup_manifest_is_valid "$BACKUP_DIR" || die "Manifest backup tidak valid: $BACKUP_DIR"

if [[ "$DRY_RUN" == 1 ]]; then
  log_info "Mode dry-run. Backup: $BACKUP_DIR"
elif [[ "$ASSUME_YES" != 1 ]]; then
  printf 'Rollback dari %s ke %s? [y/N] ' "$BACKUP_DIR" "$PI_HOME"
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]] || die 'Rollback dibatalkan'
fi

rollback_backup "$BACKUP_DIR"
if [[ "$DRY_RUN" != 1 ]]; then
  # State is a managed file in backup manifest. If it was restored, retain it
  # atomically only when valid; otherwise remove invalid state conservatively.
  if [[ -f "$STATE_PATH" ]] && ! state_is_valid; then
    log_warn 'State hasil rollback tidak valid; dipindahkan ke backup rollback untuk inspeksi'
    rollback_note="$PI_HOME/.repackmyskill/state.invalid-$(date +%s).json"
    mv -- "$STATE_PATH" "$rollback_note"
  fi
fi
log_info "Rollback selesai. Backup: $BACKUP_DIR"
