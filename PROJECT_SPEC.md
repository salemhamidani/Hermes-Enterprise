# Hermes Enterprise Stack (HES)
# File: PROJECT_SPEC.md
# Purpose: Define the Phase 1 project specification, standards, and extension contract.

# Project Specification

## Project Identity

- Full name: Hermes Enterprise Stack
- Short name: HES
- Phase: Phase 1
- Scope: Infrastructure foundation only
- Target platform: Ubuntu 24.04 LTS
- Runtime model: Docker Engine with Docker Compose V2

## Phase 1 Objective

Phase 1 establishes the production-grade infrastructure foundation for future Hermes services. It provides repository structure, modular Docker Compose architecture, secure ingress, lifecycle scripts, environment-driven configuration, documentation, validation, and operational guardrails.

Phase 1 must remain infrastructure-only.

## Explicitly Out of Scope

Do not add these in Phase 1:

- Hermes application services
- Grafana
- Prometheus
- Loki
- Redis
- PostgreSQL
- Any data-plane service
- Any observability service beyond current infrastructure logging

## Architecture Principles

- Follow Clean Architecture boundaries.
- Keep infrastructure, configuration, operations, and documentation separated.
- Keep Docker Compose files modular.
- Keep every runtime value configurable through `.env`.
- Never hardcode secrets.
- Keep scripts idempotent.
- Prefer boring, auditable operations over clever automation.
- Design now for a future stack with more than 50 Docker services.

## Repository Structure

```text
Hermes-Enterprise/
  compose/      Docker Compose modules and Compose conventions.
  config/       Safe-to-commit runtime configuration.
  scripts/      Idempotent operational Bash scripts.
  docs/         Operator, architecture, security, and audit documentation.
  workspace/    Local operator workspace.
  logs/         Runtime and script logs.
  backup/       Backup archives.
  storage/      Service storage.
  ssl/          TLS and ACME state.
  data/         Persistent data.
  .github/      GitHub workflow and repository metadata.
```

## Docker Compose Specification

Compose files must:

- Use Docker Compose V2.
- Follow the Compose Specification.
- Avoid deprecated `version` keys.
- Avoid fixed `container_name` values.
- Avoid floating `latest` image tags.
- Use service DNS names for service-to-service communication.
- Define health checks for long-running services.
- Define Docker log rotation for long-running services.
- Apply `com.hermes.stack`, `com.hermes.environment`, and `com.hermes.phase` labels.
- Use only required networks.
- Keep internal-only services off published ports.

Current Phase 1 modules:

- `compose/compose.yml`
- `compose/network.yml`
- `compose/security.yml`
- `compose/traefik.yml`

## Network Specification

- `hes-public`: public ingress network.
- `hes-internal`: internal-only infrastructure network.

Default concrete network names include environment context:

- `hes-production-public`
- `hes-production-internal`

Future services must join only the networks required for their function.

## Security Specification

Phase 1 security requirements:

- Traefik must not mount `/var/run/docker.sock` directly.
- Docker API discovery must go through Docker socket proxy.
- Docker socket proxy permissions must be minimal.
- Containers should use:
  - `no-new-privileges`
  - dropped capabilities
  - read-only filesystems where supported
  - explicit writable `tmpfs` paths
  - process limits
- Traefik dashboard must remain disabled in Phase 1.
- `.env` must be ignored by Git.
- Backup archives include `.env` and must use owner-only permissions.
- Runtime cleanup must refuse unmanaged directories.

## Environment Specification

All runtime configuration belongs in `.env`.

Rules:

- `.env` is parsed as data, not shell code.
- Only `HES_*` variables are allowed.
- Use simple `HES_KEY=value` assignments.
- Production mode must not use placeholder values.

Required production values:

```bash
HES_ENVIRONMENT=production
HES_DOMAIN=your-domain.example
HES_ADMIN_EMAIL=ops@your-domain.example
```

## Script Specification

All shell scripts must:

- Use Bash only.
- Start with `set -Eeuo pipefail`.
- Support Ubuntu 24.04 LTS.
- Include comments.
- Use shared helpers from `scripts/lib/common.sh`.
- Provide colored terminal output.
- Write persistent lifecycle logs.
- Use clear exit codes.
- Be idempotent.
- Avoid hardcoded secrets.
- Validate environment before risky operations.

Required lifecycle scripts:

- `install.sh`
- `doctor.sh`
- `repair.sh`
- `validate.sh`
- `update.sh`
- `uninstall.sh`
- `backup.sh`
- `restore.sh`

## Makefile Specification

The Makefile must provide:

```text
make install
make doctor
make validate
make repair
make update
make backup
make restore
make logs
make status
make clean
make uninstall
```

## Documentation Specification

Documentation must be:

- Markdown, except the interactive HTML documentation.
- English.
- Professional and operator-focused.
- Kept in sync with actual scripts and Compose behavior.

Required documentation:

- `README.md`
- `CHANGELOG.md`
- `PROJECT_SPEC.md`
- `AUDIT_REPORT.md`
- `docs/ARCHITECTURE.md`
- `docs/OPERATIONS.md`
- `docs/SECURITY.md`
- `docs/BACKUP_RESTORE.md`
- `docs/DEVELOPMENT.md`
- `docs/PHASE1_REVIEW_REPORT.md`
- `docs/Phase1.html`
- `compose/README.md`

## Validation Specification

Validation must check:

- Bash syntax.
- ShellCheck when available.
- LF line endings.
- Docker availability.
- Docker Compose V2 availability.
- Compose semantic configuration.
- No deprecated Compose `version` keys.
- No fixed `container_name` values.
- No floating `latest` image tags.

Primary command:

```bash
make validate
```

## Backup and Restore Specification

Backups must include:

- `.env`
- `compose/`
- `config/`
- `ssl/`
- `storage/`
- `data/`

Restore must:

- Validate archive path and contents before extraction.
- Reject unsafe paths.
- Stage extraction before applying files.
- Restore Compose and config files.
- Restore runtime data through resolved environment paths.
- Validate Compose configuration when Docker Compose is available.

## Scalability Contract

Because HES is expected to grow beyond 50 services, every future service must define:

- A clear Compose module ownership boundary.
- Explicit networks.
- Health check.
- Log rotation.
- Restart policy.
- Security posture.
- Environment variables in `.env.example`.
- Documentation.
- Backup implications.
- Operational commands or runbooks when needed.

No future service should be added as an undocumented one-off.

## Acceptance Criteria

Phase 1 is acceptable when:

- All required files exist.
- `make repair` is idempotent.
- `make backup` creates a restricted archive.
- `make restore` restores a trusted archive.
- `make validate` passes on Ubuntu 24.04 LTS with Docker Compose V2.
- No secrets are committed.
- Documentation matches implementation.
- The stack remains infrastructure-only.
