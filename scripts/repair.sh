#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/repair.sh
# Purpose: Repair local runtime directories and safe defaults without deleting data.
#
# Automatic repairs (existing behaviour preserved, new repairs added):
#   - Missing .env        -> copy from .env.example (existing via ensure_env_file)
#   - Missing folders     -> recreate with management markers (existing)
#   - Permissions         -> chmod 700 ssl / letsencrypt (new)
#   - Missing VERSION     -> create with 1.0.0 (new)
#   - Missing .shellcheckrc -> recreate (new)
#   - Broken Compose      -> attempt to fix include paths (new)
#   - Compose validation  -> existing

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

repair_permissions() {
  local ssl_dir le_dir
  ssl_dir="$(runtime_path HES_SSL_DIR ./ssl)"
  le_dir="${ssl_dir}/letsencrypt"
  [[ -d "${ssl_dir}" ]] && chmod 700 "${ssl_dir}"
  [[ -d "${le_dir}" ]] && chmod 700 "${le_dir}"
  if [[ -d "${le_dir}" && ! -f "${le_dir}/acme.json" ]]; then
    : > "${le_dir}/acme.json"
  fi
  [[ -f "${le_dir}/acme.json" ]] && chmod 600 "${le_dir}/acme.json"
  log_success "Directory permissions repaired."
}

repair_traefik_directories() {
  mkdir -p \
    "$(runtime_path HES_LOG_DIR ./logs)/traefik/access" \
    "$(runtime_path HES_LOG_DIR ./logs)/traefik/application" \
    "$(runtime_path HES_LOG_DIR ./logs)/traefik/security" \
    "${HES_PROJECT_ROOT}/secrets"
  touch "${HES_PROJECT_ROOT}/secrets/.gitkeep"
  log_success "Traefik log and secrets directories repaired."
}

repair_version_file() {
  local version_file="${HES_PROJECT_ROOT}/VERSION"
  if [[ ! -f "${version_file}" ]]; then
    printf '1.0.0\n' > "${version_file}"
    log_warn "Created missing VERSION file (1.0.0)."
  fi
}

repair_shellcheckrc() {
  local rc="${HES_PROJECT_ROOT}/.shellcheckrc"
  if [[ ! -f "${rc}" ]]; then
    cat > "${rc}" <<'EOF'
# Hermes Enterprise Stack (HES)
# File: .shellcheckrc
# Purpose: Configure ShellCheck for HES scripts.

disable=SC2155
EOF
    log_warn "Created missing .shellcheckrc."
  fi
}

repair_compose() {
  local compose_file="${HES_COMPOSE_FILE}"
  [[ -f "${compose_file}" ]] || return 0
  local includes changed=0
  includes="$(grep -E '^\s*-\s*path:\s+' "${compose_file}" 2>/dev/null | sed -E 's/^\s*-\s*path:\s+//' | tr -d '\"' || true)"
  [[ -z "${includes}" ]] && return 0
  local inc
  while IFS= read -r inc; do
    [[ -z "${inc}" ]] && continue
    if [[ ! -f "${HES_PROJECT_ROOT}/${inc}" ]]; then
      local base fixed
      base="$(basename "${inc}")"
      fixed="compose/${base}"
      if [[ -f "${HES_PROJECT_ROOT}/${fixed}" ]]; then
        sed -i -E "s|path:[[:space:]]+${inc}|path: ${fixed}|" "${compose_file}"
        changed=1
        log_warn "Fixed Compose include path: ${inc} -> ${fixed}"
      else
        log_warn "Compose include path not found and could not be repaired: ${inc}"
      fi
    fi
  done <<< "${includes}"
  (( changed == 1 )) && log_success "Repaired Compose include paths."
  return 0
}

main() {
  log_info "Repairing HES local infrastructure state."
  ensure_env_file
  load_env
  ensure_directories
  repair_traefik_directories
  repair_permissions
  repair_version_file
  repair_shellcheckrc
  setup_logging
  validate_env
  repair_compose
  if docker_compose_cli_available; then
    compose config >/dev/null
  else
    log_warn "Docker Compose CLI is unavailable; skipped Compose validation."
  fi
  log_success "Repair completed."
}

main "$@"
