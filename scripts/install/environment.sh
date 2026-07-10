#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/install/environment.sh
# Purpose: Load and validate the HES .env configuration.
#
# Exposes hes_install_environment_load() and hes_install_environment_validate()
# so the orchestrator can interleave other setup (e.g. logging) between the
# two phases. hes_install_environment() runs both for standalone use.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

hes_install_environment_load() {
  log_info "Loading environment configuration."
  ensure_env_file
  load_env
  log_success "Environment loaded."
}

hes_install_environment_validate() {
  log_info "Validating environment configuration."
  validate_env
  log_success "Environment configuration is valid."
}

hes_install_environment() {
  hes_install_environment_load
  hes_install_environment_validate
}

main() {
  hes_install_environment "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
