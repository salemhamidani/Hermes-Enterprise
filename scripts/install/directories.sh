#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/install/directories.sh
# Purpose: Create all HES runtime directories with management markers.
#
# Exposes hes_install_directories(). Delegates to the shared
# ensure_directories() helper so behaviour stays consistent with every
# other script.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

hes_install_directories() {
  log_info "Creating runtime directories."
  ensure_directories
  log_success "Runtime directories are ready."
}

main() {
  hes_install_directories "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
