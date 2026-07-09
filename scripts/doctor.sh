#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/doctor.sh
# Purpose: Diagnose host and project readiness for Phase 1 infrastructure.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

check_writable_dir() {
  local dir="$1"
  [[ -d "${dir}" ]] || die "Missing directory: ${dir}" 66
  [[ -w "${dir}" ]] || die "Directory is not writable: ${dir}" 73
  log_success "Writable directory: ${dir}"
}

main() {
  log_info "Running HES doctor checks."
  require_ubuntu_2404
  check_docker_compose
  require_env_file
  load_env
  ensure_directories
  setup_logging
  validate_env

  check_writable_dir "$(runtime_path HES_LOG_DIR ./logs)"
  check_writable_dir "$(runtime_path HES_BACKUP_DIR ./backup)"
  check_writable_dir "$(runtime_path HES_STORAGE_DIR ./storage)"
  check_writable_dir "$(runtime_path HES_SSL_DIR ./ssl)"
  check_writable_dir "$(runtime_path HES_DATA_DIR ./data)"

  compose config >/dev/null
  log_success "Compose configuration is valid."
  compose ps || true
  log_success "Doctor checks completed."
}

main "$@"
