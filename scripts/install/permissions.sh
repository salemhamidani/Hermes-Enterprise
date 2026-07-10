#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/install/permissions.sh
# Purpose: Apply secure permissions to runtime directories (chmod 700 ssl).
#
# Exposes hes_install_permissions(). Idempotent: safe to run repeatedly.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

hes_install_permissions() {
  log_info "Applying directory permissions."
  local ssl_dir le_dir
  ssl_dir="$(runtime_path HES_SSL_DIR ./ssl)"
  le_dir="${ssl_dir}/letsencrypt"
  [[ -d "${ssl_dir}" ]] && chmod 700 "${ssl_dir}"
  [[ -d "${le_dir}" ]] && chmod 700 "${le_dir}"
  log_success "Permissions applied."
}

main() {
  hes_install_permissions "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
