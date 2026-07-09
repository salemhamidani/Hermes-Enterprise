#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/restore.sh
# Purpose: Restore Phase 1 state from a trusted backup archive.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

validate_archive_path() {
  local archive="$1"
  [[ -n "${archive}" ]] || die "Restore archive is required. Pass a path or set HES_RESTORE_ARCHIVE." 64
  [[ -f "${archive}" ]] || die "Restore archive not found: ${archive}" 66
  [[ "${archive}" == *.tar.gz ]] || die "Restore archive must be a .tar.gz file." 65
}

validate_archive_contents() {
  local archive="$1"
  local entry
  while IFS= read -r entry; do
    case "${entry}" in
      /*|../*|*/../*|"") die "Unsafe path in restore archive: ${entry}" 65 ;;
      .env|compose|compose/*|config|config/*|ssl|ssl/*|storage|storage/*|data|data/*) ;;
      *) die "Unexpected path in restore archive: ${entry}" 65 ;;
    esac
  done < <(tar -tzf "${archive}")
}

main() {
  log_info "Restoring HES Phase 1 state."
  require_command tar
  require_command cp
  require_command mktemp
  ensure_env_file
  load_env
  ensure_directories
  setup_logging

  local archive="${1:-${HES_RESTORE_ARCHIVE:-}}"
  local staging_dir
  validate_archive_path "${archive}"
  validate_archive_contents "${archive}"

  if docker_compose_cli_available; then
    compose down --remove-orphans || true
  else
    log_warn "Docker Compose CLI is unavailable; skipped container shutdown."
  fi
  staging_dir="$(mktemp -d)"
  trap 'rm -rf "${staging_dir}"' RETURN
  tar -xzf "${archive}" -C "${staging_dir}"
  cp -a "${staging_dir}/.env" "${HES_PROJECT_ROOT}/.env"
  load_env
  ensure_directories
  setup_logging
  validate_env
  remove_project_subdir compose
  remove_project_subdir config
  cp -a "${staging_dir}/compose" "${HES_PROJECT_ROOT}/"
  cp -a "${staging_dir}/config" "${HES_PROJECT_ROOT}/"
  clear_managed_dir "$(runtime_path HES_SSL_DIR ./ssl)"
  clear_managed_dir "$(runtime_path HES_STORAGE_DIR ./storage)"
  clear_managed_dir "$(runtime_path HES_DATA_DIR ./data)"
  cp -a "${staging_dir}/ssl/." "$(runtime_path HES_SSL_DIR ./ssl)/"
  cp -a "${staging_dir}/storage/." "$(runtime_path HES_STORAGE_DIR ./storage)/"
  cp -a "${staging_dir}/data/." "$(runtime_path HES_DATA_DIR ./data)/"
  if docker_compose_cli_available; then
    compose config >/dev/null
  else
    log_warn "Docker Compose CLI is unavailable; skipped Compose validation."
  fi
  log_success "Restore completed from: ${archive}"
}

main "$@"
