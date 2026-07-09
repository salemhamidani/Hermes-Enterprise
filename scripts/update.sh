#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/update.sh
# Purpose: Idempotently update Phase 1 infrastructure images and restart services.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

main() {
  log_info "Updating HES Phase 1 infrastructure."
  require_ubuntu_2404
  check_docker_compose
  require_env_file
  load_env
  ensure_directories
  setup_logging
  validate_env
  compose config >/dev/null
  compose pull
  compose up -d --remove-orphans
  compose ps
  log_success "Update completed."
}

main "$@"
