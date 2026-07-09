#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/uninstall.sh
# Purpose: Stop and remove Phase 1 containers while preserving data by default.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

remove_data() {
  local targets=(
    "$(runtime_path HES_LOG_DIR ./logs)"
    "$(runtime_path HES_BACKUP_DIR ./backup)"
    "$(runtime_path HES_STORAGE_DIR ./storage)"
    "$(runtime_path HES_SSL_DIR ./ssl)"
    "$(runtime_path HES_DATA_DIR ./data)"
    "$(runtime_path HES_WORKSPACE_DIR ./workspace)"
  )

  local target
  for target in "${targets[@]}"; do
    clear_managed_dir "${target}"
    touch "${target}/.gitkeep"
  done
}

main() {
  log_info "Uninstalling HES Phase 1 infrastructure."
  check_docker_compose
  require_env_file
  load_env
  ensure_directories
  setup_logging
  validate_env
  compose down --remove-orphans

  if [[ "${HES_REMOVE_DATA:-false}" == "true" ]]; then
    log_warn "HES_REMOVE_DATA=true; removing runtime data directories."
    remove_data
  else
    log_info "Runtime data preserved. Set HES_REMOVE_DATA=true to remove it."
  fi

  log_success "Uninstall completed."
}

main "$@"
