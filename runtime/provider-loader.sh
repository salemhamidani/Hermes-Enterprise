#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: runtime/provider-loader.sh
# Purpose: Validate and resolve Hermes provider metadata without running Hermes.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROVIDER_DIR="${PROJECT_ROOT}/config/providers"
ENV_FILE="${PROJECT_ROOT}/.env"
ENV_EXAMPLE="${PROJECT_ROOT}/.env.example"

load_provider_env() {
  local env_file="${1}"
  local line name value
  [[ -f "${env_file}" ]] || return 0
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%$'\r'}"
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue
    [[ "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || continue
    name="${line%%=*}"
    value="${line#*=}"
    case "${name}" in
      HERMES_PROVIDER|HERMES_IMAGE|HERMES_VERSION|HERMES_REGISTRY)
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
        export "${name}=${!name:-${value}}"
        ;;
    esac
  done < "${env_file}"
}

read_yaml_value() {
  local key="${1}"
  local file="${2}"
  awk -F ': *' -v key="${key}" '
    $1 ~ "^[[:space:]]*" key "$" {
      value=$2
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  ' "${file}"
}

validate_slug() {
  local name="${1}"
  local value="${2}"
  [[ "${value}" =~ ^[a-z0-9][a-z0-9_.-]*$ ]] || {
    printf 'Invalid %s: %s\n' "${name}" "${value}" >&2
    return 65
  }
}

validate_not_floating() {
  local name="${1}"
  local value="${2}"
  case "${value}" in
    ""|latest|main)
      printf '%s must not be empty, latest, or main for an active provider override.\n' "${name}" >&2
      return 65
      ;;
  esac
}

resolve_provider() {
  load_provider_env "${ENV_EXAMPLE}"
  load_provider_env "${ENV_FILE}"

  local provider="${HERMES_PROVIDER:-nous-hermes}"
  validate_slug HERMES_PROVIDER "${provider}"

  local provider_file="${PROVIDER_DIR}/${provider}.yml"
  [[ -f "${provider_file}" ]] || {
    printf 'Unknown Hermes provider: %s\n' "${provider}" >&2
    return 66
  }

  local default_registry default_image default_version registry image version
  default_registry="$(read_yaml_value default_registry "${provider_file}")"
  default_image="$(read_yaml_value default_image "${provider_file}")"
  default_version="$(read_yaml_value default_version "${provider_file}")"

  registry="${HERMES_REGISTRY:-${default_registry}}"
  image="${HERMES_IMAGE:-${default_image}}"
  version="${HERMES_VERSION:-${default_version}}"

  if [[ "${provider}" == "custom-hermes" ]]; then
    [[ -n "${registry}" && -n "${image}" && -n "${version}" ]] || {
      printf 'custom-hermes requires HERMES_REGISTRY, HERMES_IMAGE, and HERMES_VERSION.\n' >&2
      return 65
    }
  fi

  if [[ -n "${image}" ]]; then
    validate_slug HERMES_IMAGE "${image//\//.}"
  fi
  if [[ -n "${version}" ]]; then
    validate_not_floating HERMES_VERSION "${version}"
  fi

  if [[ "${1:-}" == "--print" ]]; then
    printf 'HERMES_PROVIDER=%s\n' "${provider}"
    printf 'HERMES_REGISTRY=%s\n' "${registry}"
    printf 'HERMES_IMAGE=%s\n' "${image}"
    printf 'HERMES_VERSION=%s\n' "${version}"
  fi
}

main() {
  case "${1:---validate}" in
    --validate|--print)
      resolve_provider "${1:---validate}"
      ;;
    *)
      printf 'Usage: %s [--validate|--print]\n' "$0" >&2
      return 64
      ;;
  esac
}

main "$@"
