#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/install/logging.sh
# Purpose: Set up the HES logging infrastructure.
#
# Exposes hes_install_logging(). Delegates to setup_logging() which creates
# the scripts log directory and exports HES_SCRIPT_LOG_FILE.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

hes_install_logging() {
  log_info "Setting up logging infrastructure."
  setup_logging
  log_success "Logging is configured."
}

main() {
  hes_install_logging "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
