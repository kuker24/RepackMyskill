#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DRY_RUN=0
ASSUME_YES=0
ARGS=()
TEMP_DIR=''
BACKUP_DIR=''
TX_ACTIVE=0
# shellcheck source=scripts/lib/common.sh
source "$ROOT_DIR/scripts/lib/common.sh"
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: bash update.sh [options]

Reapply repository pins. This never updates components to unpinned latest versions.

Options:
  --dry-run          Validate and print actions without PI_HOME mutation
  --yes              Skip confirmation
  --skip-impeccable  Preserve no Impeccable install during this update
  --skip-astral      Preserve no AstralForge install during this update
  --skip-grill       Preserve no Grill Me install during this update
  --help             Show this help
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1; ARGS+=(--dry-run) ;;
    --yes) ASSUME_YES=1; ARGS+=(--yes) ;;
    --skip-impeccable|--skip-astral|--skip-grill) ARGS+=("$1") ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; die "Opsi tidak dikenal: $1" ;;
  esac
  shift
done

resolve_pi_home
[[ -f "$ROOT_DIR/manifest/payload.sha256" ]] || die 'Manifest payload hilang'
(cd "$ROOT_DIR" && sha256sum --check manifest/payload.sha256 >/dev/null)
if ! state_is_valid; then die "State instalasi tidak valid atau hilang: $STATE_PATH"; fi
if [[ "$DRY_RUN" == 1 ]]; then
  log_info 'Update menggunakan installer dengan pin manifest saat ini; doctor tidak dijalankan pada dry-run'
else
  log_info "Update pinned. Backup dibuat oleh install.sh. Target: $PI_HOME"
fi
bash "$ROOT_DIR/install.sh" "${ARGS[@]}"
if [[ "$DRY_RUN" != 1 ]]; then
  bash "$ROOT_DIR/doctor.sh"
fi
