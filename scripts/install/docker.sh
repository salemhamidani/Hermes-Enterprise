#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/install/docker.sh
# Purpose: Verify Docker and Docker Compose V2; install if missing on Ubuntu.
#
# Exposes hes_install_docker(). When Docker is already available this is a
# no-op. On Ubuntu it attempts a best-effort apt-based install before falling
# back to the standard check (which fails loudly if still absent).

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

_hes_install_docker_ubuntu() {
  require_command apt-get
  require_command curl
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi
  # shellcheck disable=SC1091
  source /etc/os-release
  arch="$(dpkg --print-architecture)"
  echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
}

hes_install_docker() {
  log_info "Verifying Docker and Docker Compose V2."
  if docker_compose_cli_available; then
    log_success "Docker and Docker Compose V2 are available."
    return 0
  fi
  log_warn "Docker or Docker Compose V2 not found; attempting installation."
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" == "ubuntu" ]]; then
      retry 3 10 _hes_install_docker_ubuntu \
        || die "Failed to install Docker after retries." 69
    fi
  fi
  check_docker_compose
  log_success "Docker and Docker Compose V2 are ready."
}

main() {
  hes_install_docker "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
