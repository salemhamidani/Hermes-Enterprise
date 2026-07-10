#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/validate.sh
# Purpose: Validate scripts, configuration, and Docker Compose files.
#
# Checks (existing and new):
#   - Bash availability (existing)
#   - Environment load and validation (existing)
#   - CRLF line-ending detection (existing)
#   - Shell syntax via shellcheck or bash -n (existing, now includes install/)
#   - Compose lint rules: no version/container_name/latest tags (existing)
#   - Docker & Docker Compose V2 availability (existing)
#   - Compose syntax via `compose config` (existing)
#   - Runtime directory permissions (new)
#   - Available ports for Traefik (new, non-fatal)
#   - Volume mount paths exist (new)
#   - Network configuration validity (new)
#   - YAML syntax for all .yml files (new)
#   - Directory structure completeness (new)
#   - VERSION file exists (new)
#   - .env.example has all required variables (new)

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

validate_version_file() {
  [[ -f "${HES_PROJECT_ROOT}/VERSION" ]] \
    || die "VERSION file is missing. Run: scripts/repair.sh" 66
  log_success "VERSION file exists."
}

validate_env_example() {
  local required_vars=(
    HES_PROJECT_NAME HES_ENVIRONMENT HES_DOMAIN HES_ADMIN_EMAIL
    HES_WORKSPACE_DIR HES_LOG_DIR HES_BACKUP_DIR HES_STORAGE_DIR HES_SSL_DIR
    HES_DATA_DIR HES_CONFIG_DIR
    HES_COMPOSE_PROJECT_NAME HES_RESTART_POLICY
    HES_PUBLIC_NETWORK HES_INTERNAL_NETWORK
    HERMES_PROVIDER HERMES_IMAGE HERMES_VERSION HERMES_REGISTRY
    HES_TRAEFIK_IMAGE HES_TRAEFIK_HTTP_PORT HES_TRAEFIK_HTTPS_PORT
    HES_TRAEFIK_LOG_LEVEL HES_TRAEFIK_ACCESS_LOG_ENABLED
    HES_TRAEFIK_DOCKER_ENDPOINT HES_TRAEFIK_ACME_STORAGE
    HES_SOCKET_PROXY_IMAGE HES_SOCKET_PROXY_LOG_LEVEL
    HES_DOCKER_LOG_MAX_SIZE HES_DOCKER_LOG_MAX_FILE
    HES_BACKUP_RETENTION_DAYS HES_BACKUP_PREFIX HES_RESTORE_ARCHIVE
    HES_REMOVE_DATA
  )
  local missing=()
  local v
  for v in "${required_vars[@]}"; do
    if ! grep -qE "^${v}=" "${HES_ENV_EXAMPLE}"; then
      missing+=("${v}")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    die ".env.example is missing required variable(s): ${missing[*]}" 65
  fi
  log_success ".env.example contains all required variables."
}

validate_directory_structure() {
  local dirs=(
    "$(runtime_path HES_WORKSPACE_DIR ./workspace)"
    "$(runtime_path HES_LOG_DIR ./logs)"
    "$(runtime_path HES_LOG_DIR ./logs)/traefik"
    "$(runtime_path HES_BACKUP_DIR ./backup)"
    "$(runtime_path HES_STORAGE_DIR ./storage)"
    "$(runtime_path HES_SSL_DIR ./ssl)"
    "$(runtime_path HES_SSL_DIR ./ssl)/letsencrypt"
    "$(runtime_path HES_DATA_DIR ./data)"
  )
  local d
  for d in "${dirs[@]}"; do
    [[ -d "${d}" ]] || die "Missing required directory: ${d}" 66
  done
  log_success "Directory structure is complete."
}

validate_volume_paths() {
  local paths=(
    "$(runtime_path HES_WORKSPACE_DIR ./workspace)"
    "$(runtime_path HES_LOG_DIR ./logs)"
    "$(runtime_path HES_BACKUP_DIR ./backup)"
    "$(runtime_path HES_STORAGE_DIR ./storage)"
    "$(runtime_path HES_SSL_DIR ./ssl)"
    "$(runtime_path HES_DATA_DIR ./data)"
    "$(runtime_path HES_CONFIG_DIR ./config)"
  )
  local p
  for p in "${paths[@]}"; do
    [[ -d "${p}" ]] || die "Volume mount path does not exist: ${p}" 66
  done
  log_success "Volume mount paths exist."
}

validate_permissions() {
  local ssl_dir
  ssl_dir="$(runtime_path HES_SSL_DIR ./ssl)"
  if [[ -d "${ssl_dir}" ]] && command -v stat >/dev/null 2>&1; then
    local mode
    mode="$(stat -c %a "${ssl_dir}" 2>/dev/null || true)"
    if [[ -n "${mode}" && "${mode}" != "700" ]]; then
      die "SSL directory must be chmod 700 (got ${mode}): ${ssl_dir}" 73
    fi
  fi
  log_success "Runtime directory permissions are correct."
}

validate_network_config() {
  [[ "${HES_PUBLIC_NETWORK:-hes-public}" =~ ^[a-z0-9][a-z0-9_.-]*$ ]] \
    || die "HES_PUBLIC_NETWORK is not a valid network name." 65
  [[ "${HES_INTERNAL_NETWORK:-hes-internal}" =~ ^[a-z0-9][a-z0-9_.-]*$ ]] \
    || die "HES_INTERNAL_NETWORK is not a valid network name." 65
  log_success "Network configuration is valid."
}

validate_ports() {
  local http_port="${HES_TRAEFIK_HTTP_PORT:-80}"
  local https_port="${HES_TRAEFIK_HTTPS_PORT:-443}"
  if check_port_available "${http_port}"; then
    log_success "Port ${http_port} is available."
  else
    log_warn "Port ${http_port} is in use; the stack may be running or another service occupies it."
  fi
  if check_port_available "${https_port}"; then
    log_success "Port ${https_port} is available."
  else
    log_warn "Port ${https_port} is in use; the stack may be running or another service occupies it."
  fi
}

validate_yaml_syntax() {
  local yml_files=()
  while IFS= read -r -d '' f; do
    yml_files+=("${f}")
  done < <(find "${HES_PROJECT_ROOT}" -path "${HES_PROJECT_ROOT}/.git" -prune -o -type f \( -name '*.yml' -o -name '*.yaml' \) -print0)
  if (( ${#yml_files[@]} == 0 )); then
    return 0
  fi
  if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' 2>/dev/null; then
    local f
    for f in "${yml_files[@]}"; do
      python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "${f}" \
        || die "YAML syntax error in: ${f}" 65
    done
    log_success "YAML syntax valid for ${#yml_files[@]} file(s)."
  elif command -v yq >/dev/null 2>&1; then
    local f
    for f in "${yml_files[@]}"; do
      yq e 'true' "${f}" >/dev/null 2>&1 || die "YAML syntax error in: ${f}" 65
    done
    log_success "YAML syntax valid for ${#yml_files[@]} file(s)."
  else
    log_warn "Neither python3-yaml nor yq is available; skipping YAML syntax check."
  fi
}

validate_provider_layer() {
  [[ -d "${HES_PROJECT_ROOT}/config/providers" ]] || die "Missing provider config directory." 66
  [[ -d "${HES_PROJECT_ROOT}/compose/providers" ]] || die "Missing provider Compose reservation directory." 66
  [[ -d "${HES_PROJECT_ROOT}/runtime" ]] || die "Missing runtime directory." 66
  [[ -f "${HES_PROJECT_ROOT}/config/providers/interface.yml" ]] || die "Missing provider interface specification." 66
  [[ -f "${HES_PROJECT_ROOT}/config/providers/nous-hermes.yml" ]] || die "Missing Nous Hermes provider manifest." 66
  [[ -f "${HES_PROJECT_ROOT}/config/providers/future-hermes.yml" ]] || die "Missing Future Hermes provider manifest." 66
  [[ -f "${HES_PROJECT_ROOT}/config/providers/custom-hermes.yml" ]] || die "Missing Custom Hermes provider manifest." 66
  bash "${HES_PROJECT_ROOT}/runtime/provider-loader.sh" --validate
  log_success "Hermes provider layer is valid."
}

main() {
  log_info "Validating HES project files."
  require_command bash
  ensure_env_file
  load_env
  ensure_directories
  setup_logging
  validate_env

  validate_version_file
  validate_env_example
  validate_directory_structure
  validate_volume_paths
  validate_permissions
  validate_network_config
  validate_ports
  validate_yaml_syntax
  validate_provider_layer

  if grep -RIl $'\r' "${HES_PROJECT_ROOT}" --exclude-dir=.git >/dev/null 2>&1; then
    die "CRLF line endings detected. Use LF line endings for Linux scripts and Compose files." 65
  fi

  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${HES_PROJECT_ROOT}"/scripts/*.sh "${HES_PROJECT_ROOT}"/scripts/lib/*.sh "${HES_PROJECT_ROOT}"/scripts/install/*.sh "${HES_PROJECT_ROOT}"/runtime/*.sh
    log_success "Shell scripts passed shellcheck."
  else
    log_warn "shellcheck is not installed; syntax-only Bash validation will be used."
    bash -n "${HES_PROJECT_ROOT}"/scripts/*.sh "${HES_PROJECT_ROOT}"/scripts/lib/*.sh "${HES_PROJECT_ROOT}"/scripts/install/*.sh "${HES_PROJECT_ROOT}"/runtime/*.sh
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
