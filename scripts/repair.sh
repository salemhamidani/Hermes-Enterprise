#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/repair.sh
# Purpose: Repair local runtime directories and safe defaults without deleting data.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

main() {
  log_info "Repairing HES local infrastructure state."
  ensure_env_file
  load_env
  ensure_directories
  setup_logging
  validate_env
  if docker_compose_cli_available; then
    compose config >/dev/null
  else
    log_warn "Docker Compose CLI is unavailable; skipped Compose validation."
  fi
  log_success "Repair completed."
}

main "$@"
