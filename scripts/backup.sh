#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/backup.sh
# Purpose: Create an idempotent timestamped backup archive for Phase 1 state.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

main() {
  log_info "Creating HES backup archive."
  require_command tar
  require_command cp
  require_command mktemp
  ensure_env_file
  load_env
  ensure_directories
  setup_logging
  validate_env

  local timestamp
  local backup_dir
  local archive
  local staging_dir
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_dir="$(runtime_path HES_BACKUP_DIR ./backup)"
  archive="${backup_dir}/${HES_BACKUP_PREFIX:-hes-backup}-${timestamp}.tar.gz"
  staging_dir="$(mktemp -d)"
  trap 'rm -rf "${staging_dir}"' RETURN

  require_positive_int HES_BACKUP_RETENTION_DAYS "${HES_BACKUP_RETENTION_DAYS:-14}"

  cp "${HES_ENV_FILE}" "${staging_dir}/.env"
  cp -a "${HES_PROJECT_ROOT}/compose" "${staging_dir}/compose"
  cp -a "$(runtime_path HES_CONFIG_DIR ./config)" "${staging_dir}/config"
  cp -a "$(runtime_path HES_SSL_DIR ./ssl)" "${staging_dir}/ssl"
  cp -a "$(runtime_path HES_STORAGE_DIR ./storage)" "${staging_dir}/storage"
  cp -a "$(runtime_path HES_DATA_DIR ./data)" "${staging_dir}/data"

  tar -czf "${archive}" -C "${staging_dir}" \
    .env \
    compose \
    config \
    ssl \
    storage \
    data

  chmod 600 "${archive}"
  find "${backup_dir}" -type f -name "${HES_BACKUP_PREFIX:-hes-backup}-*.tar.gz" -mtime "+${HES_BACKUP_RETENTION_DAYS:-14}" -delete
  log_success "Backup created: ${archive}"
}

main "$@"
