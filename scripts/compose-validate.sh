#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: scripts/compose-validate.sh
# Purpose: Launcher entrypoint that discovers and loads every compose/*.yml
#          module (in dependency order) and validates the merged configuration.
#
# Usage:
#   scripts/compose-validate.sh              # validate merged config
#   scripts/compose-validate.sh -f extra.yml # validate with an extra compose file
#   scripts/compose-validate.sh -- config    # print the merged config
#
# Module load order:
#   1. compose/network.yml
#   2. compose/security.yml
#   3. compose/traefik.yml
#   4. any future modules, alphabetically

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

EXTRA_COMPOSE_FILES=()
PASSTHROUGH_ARGS=()
COMPOSE_FILES=()
COMPOSE_ARGS=()

usage() {
  cat <<'USAGE'
Usage: compose-validate.sh [-f FILE]... [-- COMPOSE_ARGS...]

  -f, --file FILE   Merge an additional Compose file after the discovered modules.
  --                Pass all remaining arguments to `docker compose`.
  (no args)         Validate the merged Compose configuration.

Examples:
  compose-validate.sh
  compose-validate.sh -f compose/observability.yml
  compose-validate.sh -- config
USAGE
}

parse_args() {
  local in_passthrough=false
  while [[ $# -gt 0 ]]; do
    if [[ "${in_passthrough}" == "true" ]]; then
      PASSTHROUGH_ARGS+=("$1")
      shift
      continue
    fi
    case "$1" in
      -f|--file)
        [[ $# -ge 2 ]] || die "Option $1 requires a file argument." 64
        EXTRA_COMPOSE_FILES+=("$2")
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        in_passthrough=true
        shift
        ;;
      *)
        in_passthrough=true
        PASSTHROUGH_ARGS+=("$1")
        shift
        ;;
    esac
  done
}

discover_compose_files() {
  COMPOSE_FILES=()
  local compose_dir
  compose_dir="${HES_PROJECT_ROOT}/compose"
  [[ -d "${compose_dir}" ]] || die "Compose directory not found: ${compose_dir}" 66

  local priority=(network.yml security.yml traefik.yml)
  local priority_seen=" "
  local name file
  for name in "${priority[@]}"; do
    file="${compose_dir}/${name}"
    if [[ -f "${file}" ]]; then
      COMPOSE_FILES+=("${file}")
      priority_seen+="${name} "
    fi
  done

  local entry base
  while IFS= read -r entry; do
    [[ -n "${entry}" ]] || continue
    base="$(basename "${entry}")"
    if [[ "${priority_seen}" != *" ${base} "* ]]; then
      COMPOSE_FILES+=("${entry}")
    fi
  done < <(find "${compose_dir}" -maxdepth 1 -type f -name '*.yml' ! -name 'compose.yml' ! -name 'security-scan.yml' | sort)

  [[ ${#COMPOSE_FILES[@]} -gt 0 ]] || die "No compose module files found in ${compose_dir}." 66
}

build_compose_args() {
  COMPOSE_ARGS=(--project-directory "${HES_PROJECT_ROOT}" --env-file "${HES_ENV_FILE}")
  local file
  for file in "${COMPOSE_FILES[@]}"; do
    COMPOSE_ARGS+=(-f "${file}")
  done
  if [[ ${#EXTRA_COMPOSE_FILES[@]} -gt 0 ]]; then
    for file in "${EXTRA_COMPOSE_FILES[@]}"; do
      [[ -f "${file}" ]] || die "Extra compose file not found: ${file}" 66
      COMPOSE_ARGS+=(-f "${file}")
    done
  fi
}

run_compose() {
  docker compose "${COMPOSE_ARGS[@]}" "$@"
}

main() {
  parse_args "$@"
  log_info "Validating HES compose configuration."
  check_docker_compose
  ensure_env_file
  load_env
  setup_logging
  validate_env
  discover_compose_files
  build_compose_args

  log_info "Compose files: ${COMPOSE_FILES[*]}"

  if [[ ${#PASSTHROUGH_ARGS[@]} -gt 0 ]]; then
    run_compose "${PASSTHROUGH_ARGS[@]}"
    log_success "Compose command completed: ${PASSTHROUGH_ARGS[*]}"
  else
    run_compose config >/dev/null
    log_success "HES compose configuration is valid."
  fi
}

main "$@"
