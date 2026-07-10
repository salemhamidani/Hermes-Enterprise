#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/lib/common.sh
# Purpose: Shared Bash utilities for idempotent Phase 1 operations.
#
# This library provides logging, environment and provider loading, path resolution,
# directory management, and Docker Compose helpers shared by every HES
# script. The Phase 1 technical-debt cleanup added: log-level filtering,
# a central error handler, structured exit-code constants, a spinner, a
# retry helper, a timeout wrapper, a progress bar, and shared utilities
# for port checks, health polling, and duration formatting.

set -Eeuo pipefail

# Source guard: common.sh may be sourced many times (e.g. by install
# modules); only the first source performs initialisation.
if [[ -n "${HES_COMMON_LOADED:-}" ]]; then
  return 0
fi
HES_COMMON_LOADED=1

HES_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HES_COMMON_DIR
HES_PROJECT_ROOT="$(cd "${HES_COMMON_DIR}/../.." && pwd)"
readonly HES_PROJECT_ROOT
readonly HES_ENV_FILE="${HES_PROJECT_ROOT}/.env"
readonly HES_ENV_EXAMPLE="${HES_PROJECT_ROOT}/.env.example"
readonly HES_COMPOSE_FILE="${HES_PROJECT_ROOT}/compose/compose.yml"

# --- Structured exit codes ---------------------------------------------------
# Centralised constants so every script shares the same meaning for a code.
# Numbers follow the sysexits.h convention where one exists.
readonly HES_EXIT_OK=0
readonly HES_EXIT_USAGE=64
readonly HES_EXIT_DATA=65
readonly HES_EXIT_NOINPUT=66
readonly HES_EXIT_UNAVAILABLE=69
readonly HES_EXIT_PERM=70
readonly HES_EXIT_CONFIG=73
readonly HES_EXIT_OS=78
readonly HES_EXIT_NOTFOUND=127

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

# --- Log level filtering -----------------------------------------------------
# HES_LOG_LEVEL may be DEBUG, INFO, WARN, or ERROR. The default (DEBUG)
# shows every message, preserving the original behaviour.
HES_LOG_LEVEL="${HES_LOG_LEVEL:-DEBUG}"

_hes_log_level_num() {
  case "$1" in
    DEBUG|debug) printf 10 ;;
    INFO|info|OK) printf 20 ;;
    WARN|warn) printf 30 ;;
    ERROR|error|FAIL) printf 40 ;;
    *) printf 0 ;;
  esac
}

_hes_log_visible() {
  local current target
  current="$(_hes_log_level_num "${HES_LOG_LEVEL}")"
  target="$(_hes_log_level_num "$1")"
  [[ "${target}" -ge "${current}" ]]
}

set_log_level() {
  HES_LOG_LEVEL="$1"
}

log_info() {
  _hes_log_visible INFO || return 0
  printf '%s[INFO]%s %s\n' "${HES_COLOR_BLUE}" "${HES_COLOR_RESET}" "$*"
  write_log "INFO" "$*"
}

log_success() {
  _hes_log_visible OK || return 0
  printf '%s[ OK ]%s %s\n' "${HES_COLOR_GREEN}" "${HES_COLOR_RESET}" "$*"
  write_log "OK" "$*"
}

log_warn() {
  _hes_log_visible WARN || return 0
  printf '%s[WARN]%s %s\n' "${HES_COLOR_YELLOW}" "${HES_COLOR_RESET}" "$*" >&2
  write_log "WARN" "$*"
}

log_error() {
  _hes_log_visible FAIL || return 0
  printf '%s[FAIL]%s %s\n' "${HES_COLOR_RED}" "${HES_COLOR_RESET}" "$*" >&2
  write_log "FAIL" "$*"
}

log_debug() {
  _hes_log_visible DEBUG || return 0
  printf '%s[DBG ]%s %s\n' "${HES_COLOR_BLUE}" "${HES_COLOR_RESET}" "$*"
  write_log "DEBUG" "$*"
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

# --- Central error handler ---------------------------------------------------
# Richer than the original trap: reports the failing command, the calling
# function, the source line, and a human exit-code name.
hes_exit_code_name() {
  case "$1" in
    0) printf 'OK' ;;
    64) printf 'USAGE' ;;
    65) printf 'DATAERR' ;;
    66) printf 'NOINPUT' ;;
    69) printf 'UNAVAILABLE' ;;
    70) printf 'PERM' ;;
    73) printf 'CONFIG' ;;
    78) printf 'OSERR' ;;
    127) printf 'NOTFOUND' ;;
    *) printf 'UNKNOWN' ;;
  esac
}

central_error_handler() {
  local code="${1:-$?}"
  local line="${2:-${BASH_LINENO[0]:-unknown}}"
  local func="${3:-${FUNCNAME[1]:-main}}"
  local cmd="${4:-${BASH_COMMAND:-unknown}}"
  local name
  name="$(hes_exit_code_name "${code}")"
  log_error "Command failed: ${cmd}"
  log_error "  -> function: ${func} | line: ${line} | exit code: ${code} (${name})"
}

on_error() {
  local code=$?
  central_error_handler "${code}" "${BASH_LINENO[0]:-unknown}" "${FUNCNAME[1]:-main}" "${BASH_COMMAND:-unknown}"
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
      if [[ "${name}" == HES_* || "${name}" == HERMES_* ]]; then
        env_overrides["${name}"]="${value}"
      fi
    done < <(env)

    while IFS= read -r line || [[ -n "${line}" ]]; do
      line="${line%$'\r'}"
      [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue
      [[ "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || die "Invalid .env line: ${line}" 65
      name="${line%%=*}"
      value="${line#*=}"
      [[ "${name}" == HES_* || "${name}" == HERMES_* ]] || die "Only HES_* and HERMES_* variables are allowed in .env: ${name}" 65
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

# --- Spinner -----------------------------------------------------------------
# Run a long-running command with an animated spinner on stderr.
# Usage: spinner <command> [args...]
spinner() {
  local spinstr="|/-\\"
  local delay="${HES_SPINNER_DELAY:-0.1}"
  local spin_pid
  (
    local i
    while :; do
      for ((i = 0; i < ${#spinstr}; i++)); do
        printf '\r[%s]' "${spinstr:i:1}" >&2
        sleep "${delay}"
      done
    done
  ) & spin_pid=$!
  local rc=0
  "$@" || rc=$?
  kill "${spin_pid}" 2>/dev/null || true
  wait "${spin_pid}" 2>/dev/null || true
  printf '\r    \r' >&2
  return "${rc}"
}

# --- Retry -------------------------------------------------------------------
# Run a command up to <attempts> times, waiting <delay> seconds between tries.
# Usage: retry <attempts> <delay_seconds> <command> [args...]
retry() {
  local attempts="$1"
  local delay="$2"
  shift 2
  local attempt=1
  local rc=0
  while (( attempt <= attempts )); do
    if "$@"; then
      return 0
    fi
    rc=$?
    if (( attempt < attempts )); then
      log_warn "Attempt ${attempt}/${attempts} failed (exit ${rc}); retrying in ${delay}s..."
      sleep "${delay}"
    fi
    attempt=$((attempt + 1))
  done
  return "${rc}"
}

# --- Timeout wrapper ---------------------------------------------------------
# Run a command with a timeout. Falls back to running without a timeout when
# neither timeout nor gtimeout is available.
# Usage: timeout_wrapper <seconds> <command> [args...]
timeout_wrapper() {
  local seconds="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "${seconds}" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "${seconds}" "$@"
  else
    log_warn "No 'timeout' command available; running without timeout."
    "$@"
  fi
}

# --- Progress bar ------------------------------------------------------------
# Render a single-line progress bar to stderr for multi-step operations.
# Usage: progress_bar <current> <total> [label]
progress_bar() {
  local current="$1"
  local total="$2"
  local label="${3:-}"
  local width="${HES_PROGRESS_WIDTH:-30}"
  local percent=0
  local filled=0
  if (( total > 0 )); then
    (( current > total )) && current="${total}"
    percent=$(( current * 100 / total ))
    filled=$(( width * current / total ))
  fi
  local bar=""
  local i
  for ((i = 0; i < width; i++)); do
    if (( i < filled )); then
      bar+="#"
    else
      bar+="-"
    fi
  done
  if [[ -n "${label}" ]]; then
    printf '\r%s [%s] %3d%%' "${label}" "${bar}" "${percent}" >&2
  else
    printf '\r[%s] %3d%%' "${bar}" "${percent}" >&2
  fi
  (( current >= total && total > 0 )) && printf '\n' >&2
  return 0
}

# --- Port availability -------------------------------------------------------
# Return 0 if <port> appears free, 1 if it is in use. When no inspection tool
# is available, assume free and warn.
# Usage: check_port_available <port>
check_port_available() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    if ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${port}$"; then
      return 1
    fi
  elif command -v netstat >/dev/null 2>&1; then
    if netstat -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${port}$"; then
      return 1
    fi
  else
    log_warn "Cannot verify port ${port}: neither ss nor netstat is available."
    return 0
  fi
  return 0
}

# --- Wait for health ---------------------------------------------------------
# Poll a URL until it responds successfully or <max_attempts> is reached.
# Usage: wait_for_health <url> [max_attempts] [delay_seconds]
wait_for_health() {
  local url="$1"
  local max_attempts="${2:-30}"
  local delay="${3:-2}"
  local attempt=1
  while (( attempt <= max_attempts )); do
    if command -v curl >/dev/null 2>&1; then
      if curl -fsS -o /dev/null --max-time 5 "${url}" 2>/dev/null; then
        return 0
      fi
    elif command -v wget >/dev/null 2>&1; then
      if wget -q --spider --timeout=5 "${url}" 2>/dev/null; then
        return 0
      fi
    else
      log_warn "Neither curl nor wget is available; cannot perform health check."
      return 1
    fi
    attempt=$((attempt + 1))
    (( attempt <= max_attempts )) && sleep "${delay}"
  done
  return 1
}

# --- Format duration ---------------------------------------------------------
# Render a number of seconds as a compact human-readable duration.
# Usage: format_duration <seconds>
format_duration() {
  local seconds="$1"
  local d h m s
  d=$(( seconds / 86400 ))
  h=$(( (seconds % 86400) / 3600 ))
  m=$(( (seconds % 3600) / 60 ))
  s=$(( seconds % 60 ))
  local parts=()
  (( d > 0 )) && parts+=("${d}d")
  (( h > 0 )) && parts+=("${h}h")
  (( m > 0 )) && parts+=("${m}m")
  (( s > 0 )) && parts+=("${s}s")
  if (( ${#parts[@]} == 0 )); then
    printf '0s'
  else
    printf '%s' "${parts[*]}"
  fi
}
