#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/install/validation.sh
# Purpose: Pre-install validation checks (operating system, required commands).
#
# This module is part of the HES installer. It sources the shared common
# library and exposes hes_install_validation(). It may be sourced by the
# orchestrator or executed standalone.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

hes_install_validation() {
  log_info "Running pre-install validation checks."
  require_ubuntu_2404
  require_command bash
  log_success "Pre-install validation passed."
}

main() {
  hes_install_validation "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
