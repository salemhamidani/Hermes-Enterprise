#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/install.sh
# Purpose: Idempotently install and start Phase 1 infrastructure.
#
# This is a thin orchestrator. All real work lives in the self-contained
# modules under scripts/install/, each of which may also be run standalone.
# The ordering below preserves the original install.sh behaviour.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/install/validation.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/install/docker.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/install/environment.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/install/directories.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/install/permissions.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/install/logging.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/install/network.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/install/compose.sh"

main() {
  log_info "Installing Hermes Enterprise Stack Phase 1 infrastructure."
  hes_install_validation
  hes_install_docker
  hes_install_environment_load
  hes_install_directories
  hes_install_permissions
  hes_install_logging
  hes_install_environment_validate
  hes_install_network
  hes_install_compose
  log_success "HES Phase 1 infrastructure is installed and running."
}

main "$@"
