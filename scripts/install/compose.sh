#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/install/compose.sh
# Purpose: Pull and start Docker Compose services.
#
# Exposes hes_install_compose(): validates the config, pulls images, and
# starts the stack with --remove-orphans.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

hes_install_compose() {
  log_info "Validating, pulling, and starting Compose services."
  compose config >/dev/null
  compose pull
  compose up -d --remove-orphans
  log_success "Compose services are running."
}

main() {
  hes_install_compose "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
