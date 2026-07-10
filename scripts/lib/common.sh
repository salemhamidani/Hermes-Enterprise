#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/lib/common.sh
# Purpose: Shared Bash utilities for idempotent Phase 1 operations.

set -Eeuo pipefail

HES_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HES_COMMON_DIR
HES_PROJECT_ROOT="$(cd "${HES_COMMON_DIR}/../.." && pwd)"
readonly HES_PROJECT_ROOT
readonly HES_ENV_FILE="${HES_PROJECT_ROOT}/.env"
readonly HES_ENV_EXAMPLE="${HES_PROJECT_ROOT}/.env.example"
readonly HES_COMPOSE_FILE="${HES_PROJECT_ROOT}/compose/compose.yml"

if [[ -t 1 ]]; then
  readonly HES_COLOR_RED=$'\033[31m'
  readonly HES_COLOR_GREEN=$'\033[32m'
  readonly HES_COLOR_YELLOW=$'\033[33m'
  readonly HES_COLOR_BLUE=$'\033[34m'
  readonly HES_COLOR_RESET=$'\033[0m'
else
  readonly HES_COLOR_RED=''
  readonly HES_COLOR_GREEN=''
  readonly HES_COLOR_YELLOW=''
  readonly HES_COLOR_BLUE=''
  readonly HES_COLOR_RESET=''
fi

log_info() {
  printf '%s[INFO]%s %s\n' "${HES_COLOR_BLUE}" "${HES_COLOR_RESET}" "$*"
  write_log "INFO" "$*"
}

log_success() {
  printf '%s[ OK ]%s %s\n' "${HES_COLOR_GREEN}" "${HES_COLOR_RESET}" "$*"
  write_log "OK" "$*"
}

log_warn() {
  printf '%s[WARN]%s %s\n' "${HES_COLOR_YELLOW}" "${HES_COLOR_RESET}" "$*" >&2
  write_log "WARN" "$*"
}

log_error() {
  printf '%s[FAIL]%s %s\n' "${HES_COLOR_RED}" "${HES_COLOR_RESET}" "$*" >&2
  write_log "FAIL" "$*"
}

write_log() {
  local level="$1"
  shift
  [[ -n "${HES_SCRIPT_LOG_FILE:-}" ]] || return 0
  printf '%s [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${level}" "$*" >> "${HES_SCRIPT_LOG_FILE}"
}

die() {
  local code="${2:-1}"
  log_error "$1"
  exit "${code}"
}

on_error() {
  local code=$?
  log_error "Command failed at line ${BASH_LINENO[0]} with exit code ${code}."
  exit "${code}"
}

trap on_error ERR

load_env() {
  if [[ -f "${HES_ENV_FILE}" ]]; then
    local name
    local value
    local line
    declare -A env_overrides=()

    while IFS='=' read -r name value; do
      if [[ "${name}" == HES_* ]]; then
        env_overrides["${name}"]="${value}"
      fi
    done < <(env)

    while IFS= read -r line || [[ -n "${line}" ]]; do
      line="${line%$'\r'}"
      [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue
      [[ "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || die "Invalid .env line: ${line}" 65
      name="${line%%=*}"
      value="${line#*=}"
      [[ "${name}" == HES_* ]] || die "Only HES_* variables are allowed in .env: ${name}" 65
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"
      export "${name}=${value}"
    done < "${HES_ENV_FILE}"

    for name in "${!env_overrides[@]}"; do
      export "${name}=${env_overrides[${name}]}"
    done
  fi
}

setup_logging() {
  local log_dir
  log_dir="$(runtime_path HES_LOG_DIR ./logs)/scripts"
  mkdir -p "${log_dir}"
  mark_managed_dir "${log_dir}"
  HES_SCRIPT_LOG_FILE="${log_dir}/$(basename "$0" .sh).log"
  export HES_SCRIPT_LOG_FILE
}

validate_bool() {
  local name="$1"
  local value="$2"
  case "${value}" in
    true|false) ;;
    *) die "${name} must be true or false." 65 ;;
  esac
}

validate_port() {
  local name="$1"
  local value="$2"
  [[ "${value}" =~ ^[0-9]+$ ]] || die "${name} must be numeric." 65
  (( value >= 1 && value <= 65535 )) || die "${name} must be between 1 and 65535." 65
}

validate_env() {
  [[ "${HES_COMPOSE_PROJECT_NAME:-hes}" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || die "HES_COMPOSE_PROJECT_NAME must be lowercase letters, numbers, dashes, or underscores." 65
  [[ "${HES_ENVIRONMENT:-production}" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || die "HES_ENVIRONMENT must be lowercase letters, numbers, dashes, or underscores." 65
  validate_port HES_TRAEFIK_HTTP_PORT "${HES_TRAEFIK_HTTP_PORT:-80}"
  validate_port HES_TRAEFIK_HTTPS_PORT "${HES_TRAEFIK_HTTPS_PORT:-443}"
  validate_bool HES_TRAEFIK_ACCESS_LOG_ENABLED "${HES_TRAEFIK_ACCESS_LOG_ENABLED:-true}"
  validate_bool HES_REMOVE_DATA "${HES_REMOVE_DATA:-false}"
  require_positive_int HES_BACKUP_RETENTION_DAYS "${HES_BACKUP_RETENTION_DAYS:-14}"
  require_positive_int HES_DOCKER_LOG_MAX_FILE "${HES_DOCKER_LOG_MAX_FILE:-5}"
  [[ "${HES_DOCKER_LOG_MAX_SIZE:-10m}" =~ ^[0-9]+[kKmMgG]?$ ]] || die "HES_DOCKER_LOG_MAX_SIZE must look like 10m, 100k, or 1g." 65

  if [[ "${HES_ENVIRONMENT:-production}" == "production" ]]; then
    [[ "${HES_DOMAIN:-example.com}" != "example.com" ]] || die "Set HES_DOMAIN before production deployment." 65
    [[ "${HES_ADMIN_EMAIL:-admin@example.com}" != "admin@example.com" ]] || die "Set HES_ADMIN_EMAIL before production deployment." 65
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1" 127
}

require_env_file() {
  [[ -f "${HES_ENV_FILE}" ]] || die "Missing .env. Run: cp .env.example .env" 64
}

ensure_env_file() {
  if [[ ! -f "${HES_ENV_FILE}" ]]; then
    cp "${HES_ENV_EXAMPLE}" "${HES_ENV_FILE}"
    log_warn "Created .env from .env.example. Review it before production use."
  fi
}

compose() {
  docker compose --project-directory "${HES_PROJECT_ROOT}" --env-file "${HES_ENV_FILE}" -f "${HES_COMPOSE_FILE}" "$@"
}

docker_compose_cli_available() {
  command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1
}

resolve_project_path() {
  local path="$1"
  if [[ "${path}" = /* ]]; then
    printf '%s\n' "${path}"
  else
    printf '%s/%s\n' "${HES_PROJECT_ROOT}" "${path#./}"
  fi
}

runtime_path() {
  local variable="$1"
  local default_path="$2"
  resolve_project_path "${!variable:-${default_path}}"
}

mark_managed_dir() {
  local dir="$1"
  cat > "${dir}/.hes-managed" <<'MARKER'
# Hermes Enterprise Stack (HES)
# File: .hes-managed
# Purpose: Mark this runtime directory as managed by HES lifecycle scripts.
MARKER
}

require_managed_dir() {
  local dir="$1"
  [[ -d "${dir}" ]] || die "Managed directory does not exist: ${dir}" 66
  [[ -f "${dir}/.hes-managed" ]] || die "Refusing to modify unmanaged directory: ${dir}" 70
}

clear_managed_dir() {
  local dir="$1"
  require_managed_dir "${dir}"
  find "${dir}" -mindepth 1 -maxdepth 1 ! -name .gitkeep ! -name .hes-managed -exec rm -rf -- {} +
}

remove_project_subdir() {
  local name="$1"
  local target="${HES_PROJECT_ROOT}/${name}"
  case "${name}" in
    compose|config) ;;
    *) die "Refusing to replace unsupported project directory: ${name}" 70 ;;
  esac
  [[ "${target}" == "${HES_PROJECT_ROOT}"/* ]] || die "Refusing to remove unsafe path: ${target}" 70
  rm -rf -- "${target}"
}

require_positive_int() {
  local name="$1"
  local value="$2"
  [[ "${value}" =~ ^[0-9]+$ ]] || die "${name} must be a positive integer." 65
}

ensure_directories() {
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

  local dir
  for dir in "${dirs[@]}"; do
    mkdir -p "${dir}"
    mark_managed_dir "${dir}"
  done

  touch \
    "$(runtime_path HES_WORKSPACE_DIR ./workspace)/.gitkeep" \
    "$(runtime_path HES_LOG_DIR ./logs)/.gitkeep" \
    "$(runtime_path HES_BACKUP_DIR ./backup)/.gitkeep" \
    "$(runtime_path HES_STORAGE_DIR ./storage)/.gitkeep" \
    "$(runtime_path HES_SSL_DIR ./ssl)/.gitkeep" \
    "$(runtime_path HES_DATA_DIR ./data)/.gitkeep"

  chmod 700 "$(runtime_path HES_SSL_DIR ./ssl)" "$(runtime_path HES_SSL_DIR ./ssl)/letsencrypt"
}

require_ubuntu_2404() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
      die "Unsupported OS: ${PRETTY_NAME:-unknown}. Ubuntu 24.04 LTS is required." 78
    fi
  else
    die "Cannot detect operating system. Ubuntu 24.04 LTS is required." 78
  fi
}

check_docker_compose() {
  require_command docker
  docker info >/dev/null 2>&1 || die "Docker daemon is not reachable." 69
  docker compose version >/dev/null 2>&1 || die "Docker Compose V2 is required." 69
}
