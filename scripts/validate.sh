#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/validate.sh
# Purpose: Validate scripts, configuration, and Docker Compose files.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

main() {
  log_info "Validating HES project files."
  require_command bash
  ensure_env_file
  load_env
  ensure_directories
  setup_logging
  validate_env

  if grep -RIl $'\r' "${HES_PROJECT_ROOT}" --exclude-dir=.git >/dev/null 2>&1; then
    die "CRLF line endings detected. Use LF line endings for Linux scripts and Compose files." 65
  fi

  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${HES_PROJECT_ROOT}"/scripts/*.sh "${HES_PROJECT_ROOT}"/scripts/lib/*.sh
    log_success "Shell scripts passed shellcheck."
  else
    log_warn "shellcheck is not installed; syntax-only Bash validation will be used."
    bash -n "${HES_PROJECT_ROOT}"/scripts/*.sh "${HES_PROJECT_ROOT}"/scripts/lib/*.sh
  fi

  if find "${HES_PROJECT_ROOT}/compose" -type f -name '*.yml' -exec grep -H "^version:" {} + >/dev/null 2>&1; then
    die "Deprecated Compose version keys are not allowed." 65
  fi

  if find "${HES_PROJECT_ROOT}/compose" -type f -name '*.yml' -exec grep -H "container_name:" {} + >/dev/null 2>&1; then
    die "Fixed container_name values are not allowed." 65
  fi

  if find "${HES_PROJECT_ROOT}/compose" -type f -name '*.yml' -exec grep -H "image: .*:latest" {} + >/dev/null 2>&1; then
    die "Floating latest image tags are not allowed." 65
  fi

  check_docker_compose
  compose config >/dev/null
  log_success "Docker Compose configuration is valid."
  log_success "Validation completed."
}

main "$@"
