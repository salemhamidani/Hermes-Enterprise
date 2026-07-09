#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/install.sh
# Purpose: Idempotently install and start Phase 1 infrastructure on Ubuntu 24.04 LTS.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

main() {
  log_info "Installing Hermes Enterprise Stack Phase 1 infrastructure."
  require_ubuntu_2404
  check_docker_compose
  ensure_env_file
  load_env
  ensure_directories
  setup_logging
  validate_env
  compose config >/dev/null
  compose pull
  compose up -d --remove-orphans
  log_success "HES Phase 1 infrastructure is installed and running."
}

main "$@"
