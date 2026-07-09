<!--
Hermes Enterprise Stack (HES)
File: docs/PHASE1_REVIEW_REPORT.md
Purpose: Record the senior DevOps architecture review findings and remediations for Phase 1.
-->

# Phase 1 Review Report

## Executive Summary

This review covered the complete Phase 1 repository: Compose modules, Bash lifecycle scripts, configuration, documentation, GitHub workflow, runtime directory handling, and backup/restore behavior.

All identified actionable Phase 1 issues were remediated. The project remains limited to infrastructure only and does not introduce Hermes services or observability/data services.

## Security Issues

| Finding | Risk | Fix |
| --- | --- | --- |
| `.env` was sourced as Bash. | A malformed or malicious `.env` could execute shell code. | Replaced shell sourcing with a strict parser that accepts only `HES_*` key/value entries. |
| Restore extracted archives directly into the project root. | Path traversal or unexpected archive entries could overwrite unrelated files. | Added archive entry validation and staged extraction before copying allowlisted paths. |
| Runtime cleanup trusted paths too broadly. | Misconfigured absolute paths could lead to destructive cleanup outside intended storage. | Added `.hes-managed` markers and cleanup refusal for unmanaged directories. |
| Traefik dashboard labels existed even when dashboard was disabled. | A future env toggle could expose the dashboard without authentication. | Removed dashboard routing labels from Phase 1; dashboard is not published. |
| Backup archives included `.env` without restricted permissions. | Backups could expose local secret material. | Backup archives are now created with mode `600`. |

## Docker Issues

| Finding | Risk | Fix |
| --- | --- | --- |
| Fixed `container_name` values were used. | Reduced Compose portability and prevented project-name isolation or scaling. | Removed fixed container names and used service DNS names. |
| Traefik default Docker endpoint referenced the old fixed container name. | Service discovery would break after removing `container_name`. | Updated endpoint default to `tcp://docker-socket-proxy:2375`. |
| Bind mounts ignored `.env` path variables. | Storage configuration was not actually environment-driven. | Compose mounts now use `HES_CONFIG_DIR`, `HES_SSL_DIR`, and `HES_LOG_DIR`. |
| Makefile Compose calls lacked a project directory. | Relative bind mounts could resolve inconsistently. | Added `--project-directory .` to direct Makefile Compose calls. |
| Containers lacked process limits. | A runaway process could consume excessive host process table resources. | Added `init: true` and `pids_limit` to Phase 1 containers. |

## Shell Script Issues

| Finding | Risk | Fix |
| --- | --- | --- |
| Path variables existed but scripts used hardcoded project paths. | Custom `.env` paths were ignored. | Added `runtime_path` resolution and applied it across doctor, backup, restore, uninstall, and directory repair. |
| `repair.sh` required Docker Compose to repair local files. | Bootstrap repair failed before Docker installation. | `repair.sh` now repairs local state and warns if Compose validation cannot run. |
| `restore.sh` required Docker Compose for file restoration. | Restore could not run on a partially rebuilt host. | Restore now skips container shutdown and Compose validation when the CLI is unavailable. |
| Backup retention was not validated. | Bad retention values could make `find` fail or behave unexpectedly. | Added positive integer validation. |
| CRLF files were not rejected. | Linux script execution could fail after Windows edits. | `validate.sh` now rejects CRLF line endings. |

## Architecture Issues

| Finding | Risk | Fix |
| --- | --- | --- |
| Runtime ownership was implicit. | Operators could not tell which directories were safe for scripts to manage. | Scripts now mark managed runtime directories with `.hes-managed`. |
| Dashboard exposure was mixed into the base ingress module. | Optional administrative exposure was coupled to default ingress. | Dashboard routing is excluded from Phase 1. |
| Backup/restore behavior did not preserve logical runtime layout when custom paths were used. | Externalized storage paths could be missed or restored incorrectly. | Backup stages logical directories from resolved paths; restore places them back through resolved paths. |

## Naming Issues

| Finding | Risk | Fix |
| --- | --- | --- |
| Container-name env vars exposed implementation details. | Names were not needed and made Compose less modular. | Removed `HES_TRAEFIK_CONTAINER_NAME` and `HES_SOCKET_PROXY_CONTAINER_NAME`. |
| Docker endpoint used container naming instead of service naming. | Service discovery depended on a fixed container name. | Switched to the Compose service name `docker-socket-proxy`. |

## Portability Issues

| Finding | Risk | Fix |
| --- | --- | --- |
| Direct Compose invocations did not define the project directory. | Relative paths could vary by invocation location. | Standardized Compose calls with an explicit project directory. |
| Docker-free bootstrap scripts failed too early. | Fresh hosts could not repair or restore files before Docker installation. | Repair and restore now degrade gracefully when Docker Compose is absent. |
| Line endings were unchecked. | Windows-edited scripts could fail on Ubuntu. | Added LF enforcement in validation. |

## Maintainability Issues

| Finding | Risk | Fix |
| --- | --- | --- |
| Directory path logic was duplicated across scripts. | Future changes would drift. | Centralized path resolution and managed-directory helpers in `scripts/lib/common.sh`. |
| Restore safety logic was embedded inline. | Future changes could accidentally broaden destructive operations. | Added allowlisted helper functions for managed and project directory operations. |
| Documentation did not describe the stricter env and managed directory model. | Operators could misconfigure paths or cleanup behavior. | Updated README, architecture, development, security, and backup/restore documentation. |

## Validation Performed

- Bash syntax validation passed for all shell scripts.
- YAML parsing passed for Compose files, Traefik dynamic configuration, and GitHub workflow.
- Header and UTF-8 checks passed.
- `repair.sh` completed successfully without Docker.
- `backup.sh` completed successfully and created a restricted archive.
- `restore.sh` completed successfully from the generated backup archive using a POSIX-style path.

## Deferred Validation

Docker Compose semantic validation with `docker compose config` was not run in this local session because Docker is not available in the host PATH. The repository keeps `make validate` and the GitHub Actions workflow to run this check on Ubuntu 24.04 with Docker Compose V2.
