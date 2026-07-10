#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/install/network.sh
# Purpose: Verify network configuration and port availability.
#
# Exposes hes_install_network(). Port conflicts are reported as warnings
# (non-fatal) so re-installation over a running stack is not blocked.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

hes_install_network() {
  log_info "Verifying network configuration."
  local http_port="${HES_TRAEFIK_HTTP_PORT:-80}"
  local https_port="${HES_TRAEFIK_HTTPS_PORT:-443}"
  [[ "${HES_PUBLIC_NETWORK:-hes-public}" =~ ^[a-z0-9][a-z0-9_.-]*$ ]] \
    || die "HES_PUBLIC_NETWORK is not a valid network name." 65
  [[ "${HES_INTERNAL_NETWORK:-hes-internal}" =~ ^[a-z0-9][a-z0-9_.-]*$ ]] \
    || die "HES_INTERNAL_NETWORK is not a valid network name." 65
  if check_port_available "${http_port}"; then
    log_success "Port ${http_port} is available."
  else
    log_warn "Port ${http_port} is already in use; Traefik may fail to bind."
  fi
  if check_port_available "${https_port}"; then
    log_success "Port ${https_port} is available."
  else
    log_warn "Port ${https_port} is already in use; Traefik may fail to bind."
  fi
  log_success "Network configuration verified."
}

main() {
  hes_install_network "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
