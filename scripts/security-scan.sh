#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/security-scan.sh
# Purpose: Unified security scanner orchestrating Docker Bench, Trivy, Hadolint, ShellCheck, yamllint, and markdownlint.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

# Globals populated by run_capture().
declare CAP_OUT=""
declare CAP_RC=0

# Result registry.
declare -a RES_TOOL=()
declare -a RES_STATUS=()
declare -a RES_DETAIL=()
CRITICAL_COUNT=0

record() {
  local tool="$1"
  local status="$2"
  local detail="${3:-}"
  RES_TOOL+=("${tool}")
  RES_STATUS+=("${status}")
  RES_DETAIL+=("${detail}")
  if [[ "${status}" == "CRITICAL" ]]; then
    CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
  fi
  case "${status}" in
    CRITICAL) log_error "${tool}: CRITICAL - ${detail}" ;;
    WARN)     log_warn  "${tool}: ${detail}" ;;
    PASS)     log_success "${tool}: ${detail}" ;;
    SKIP)     log_warn  "${tool}: skipped - ${detail}" ;;
  esac
}

# Append raw tool output to the scan log.
scan_log() {
  [[ -n "${HES_SCRIPT_LOG_FILE:-}" ]] || return 0
  printf '%s\n' "$*" >> "${HES_SCRIPT_LOG_FILE}"
}

# Run a command capturing combined output without aborting under set -e.
# Results are exposed via CAP_OUT and CAP_RC.
run_capture() {
  local rc
  if CAP_OUT=$("$@" 2>&1); then
    rc=0
  else
    rc=$?
  fi
  CAP_RC=${rc}
}

scan_docker_bench() {
  if ! command -v docker-bench-security >/dev/null 2>&1; then
    record "docker-bench" "SKIP" "docker-bench-security not installed"
    return
  fi
  log_info "Running Docker Bench Security..."
  run_capture docker-bench-security
  scan_log "=== docker-bench-security (rc=${CAP_RC}) ==="
  scan_log "${CAP_OUT}"
  if [[ "${CAP_RC}" -ne 0 ]]; then
    record "docker-bench" "CRITICAL" "exited with code ${CAP_RC}"
    return
  fi
  local warns
  warns=$(printf '%s\n' "${CAP_OUT}" | grep -c '\[WARN\]' || true)
  record "docker-bench" "WARN" "completed with ${warns} advisory warning(s)"
}

scan_trivy() {
  if ! command -v trivy >/dev/null 2>&1; then
    record "trivy" "SKIP" "trivy not installed"
    return
  fi
  local images="${HES_TRIVY_SCAN_IMAGES:-traefik:v3.3 tecnativa/docker-socket-proxy:0.3.0}"
  local -a image_list=()
  IFS=' ' read -ra image_list <<< "${images}"
  local any_critical=0
  local img
  for img in "${image_list[@]}"; do
    log_info "Trivy scanning image: ${img}"
    run_capture trivy image \
      --quiet \
      --exit-code 1 \
      --severity CRITICAL \
      --ignore-unfixed \
      --format table \
      "${img}"
    scan_log "=== trivy image ${img} (rc=${CAP_RC}) ==="
    scan_log "${CAP_OUT}"
    [[ "${CAP_RC}" -ne 0 ]] && any_critical=1
  done
  if [[ "${any_critical}" -eq 1 ]]; then
    record "trivy" "CRITICAL" "critical vulnerabilities found (see log)"
  else
    record "trivy" "PASS" "no critical vulnerabilities"
  fi
}

scan_hadolint() {
  local dockerfiles=("$@")
  if [[ "${#dockerfiles[@]}" -eq 0 ]]; then
    record "hadolint" "SKIP" "no Dockerfiles found"
    return
  fi
  if ! command -v hadolint >/dev/null 2>&1; then
    record "hadolint" "SKIP" "hadolint not installed"
    return
  fi
  log_info "Running Hadolint..."
  run_capture hadolint "${dockerfiles[@]}"
  scan_log "=== hadolint (rc=${CAP_RC}) ==="
  scan_log "${CAP_OUT}"
  if [[ "${CAP_RC}" -eq 0 ]]; then
    record "hadolint" "PASS" "no issues"
  elif printf '%s\n' "${CAP_OUT}" | grep -q ': error '; then
    record "hadolint" "CRITICAL" "error-level Dockerfile issues (see log)"
  else
    record "hadolint" "WARN" "lint warnings (see log)"
  fi
}

scan_shellcheck() {
  local scripts=("$@")
  if [[ "${#scripts[@]}" -eq 0 ]]; then
    record "shellcheck" "SKIP" "no shell scripts found"
    return
  fi
  if ! command -v shellcheck >/dev/null 2>&1; then
    record "shellcheck" "SKIP" "shellcheck not installed"
    return
  fi
  log_info "Running ShellCheck..."
  run_capture shellcheck "${scripts[@]}"
  scan_log "=== shellcheck (rc=${CAP_RC}) ==="
  scan_log "${CAP_OUT}"
  if [[ "${CAP_RC}" -eq 0 ]]; then
    record "shellcheck" "PASS" "no issues"
    return
  fi
  run_capture shellcheck --severity=error "${scripts[@]}"
  if [[ "${CAP_RC}" -ne 0 ]]; then
    record "shellcheck" "CRITICAL" "error-level script issues (see log)"
  else
    record "shellcheck" "WARN" "style/info warnings only (see log)"
  fi
}

scan_yamllint() {
  local files=("$@")
  if [[ "${#files[@]}" -eq 0 ]]; then
    record "yamllint" "SKIP" "no YAML files found"
    return
  fi
  if ! command -v yamllint >/dev/null 2>&1; then
    record "yamllint" "SKIP" "yamllint not installed"
    return
  fi
  log_info "Running yamllint..."
  run_capture yamllint \
    -d '{extends: default, rules: {line-length: disable, document-start: disable}}' \
    "${files[@]}"
  scan_log "=== yamllint (rc=${CAP_RC}) ==="
  scan_log "${CAP_OUT}"
  if [[ "${CAP_RC}" -eq 0 ]]; then
    record "yamllint" "PASS" "no issues"
  else
    record "yamllint" "WARN" "yaml lint findings (see log)"
  fi
}

scan_markdownlint() {
  local files=("$@")
  if [[ "${#files[@]}" -eq 0 ]]; then
    record "markdownlint" "SKIP" "no Markdown files found"
    return
  fi
  if ! command -v markdownlint >/dev/null 2>&1; then
    record "markdownlint" "SKIP" "markdownlint not installed"
    return
  fi
  log_info "Running markdownlint..."
  run_capture markdownlint "${files[@]}"
  scan_log "=== markdownlint (rc=${CAP_RC}) ==="
  scan_log "${CAP_OUT}"
  if [[ "${CAP_RC}" -eq 0 ]]; then
    record "markdownlint" "PASS" "no issues"
  else
    record "markdownlint" "WARN" "markdown lint findings (see log)"
  fi
}

print_summary() {
  printf '\n%-16s %-10s %s\n' "TOOL" "STATUS" "DETAIL"
  printf '%-16s %-10s %s\n' "----" "------" "------"
  local i
  for i in "${!RES_TOOL[@]}"; do
    printf '%-16s %-10s %s\n' "${RES_TOOL[$i]}" "${RES_STATUS[$i]}" "${RES_DETAIL[$i]}"
  done
  printf '\n'
}

main() {
  log_info "HES security scan starting."
  ensure_env_file
  load_env

  local log_dir
  log_dir="$(runtime_path HES_LOG_DIR ./logs)"
  mkdir -p "${log_dir}"
  HES_SCRIPT_LOG_FILE="${log_dir}/security-scan.log"
  export HES_SCRIPT_LOG_FILE
  : > "${HES_SCRIPT_LOG_FILE}"
  log_info "Scan log: ${HES_SCRIPT_LOG_FILE}"

  local root="${HES_PROJECT_ROOT}"
  mapfile -t SH_FILES < <(find "${root}/scripts" -type f -name '*.sh' 2>/dev/null)
  mapfile -t YML_FILES < <(find "${root}" -type f \( -name '*.yml' -o -name '*.yaml' \) -not -path '*/.git/*' 2>/dev/null)
  mapfile -t MD_FILES < <(find "${root}" -type f -name '*.md' -not -path '*/.git/*' 2>/dev/null)
  mapfile -t DOCKERFILES < <(find "${root}" -type f -name 'Dockerfile*' -not -path '*/.git/*' 2>/dev/null)

  scan_docker_bench
  scan_trivy
  scan_hadolint "${DOCKERFILES[@]}"
  scan_shellcheck "${SH_FILES[@]}"
  scan_yamllint "${YML_FILES[@]}"
  scan_markdownlint "${MD_FILES[@]}"

  print_summary

  if [[ "${CRITICAL_COUNT}" -gt 0 ]]; then
    log_error "Security scan FAILED: ${CRITICAL_COUNT} critical finding(s)."
    exit 1
  fi
  log_success "Security scan completed with no critical findings."
  exit 0
}

main "$@"
