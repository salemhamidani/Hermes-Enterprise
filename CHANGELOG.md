<!--
Hermes Enterprise Stack (HES)
File: CHANGELOG.md
Purpose: Track user-visible project changes.
-->

# Changelog

All notable changes to Hermes Enterprise Stack are documented here.

## [1.1.0] - 2026-07-10

### Added

- Sprint 2 security foundation for production-oriented infrastructure hardening.
- Frontend, backend, management, internal, and compatibility Docker network definitions with configurable names.
- Production Traefik dynamic middleware for security headers, rate limiting, compression, and TLS policy.
- Traefik reference configuration files for entrypoints, providers, metrics, access logs, TLS, certificates, middlewares, and headers.
- Docker Secrets preparation directory without committing secret values.
- Sprint 2 design package, guides, HTML documentation, and review artifact.

### Changed

- Traefik now uses separated access and application log paths and metrics/ping endpoint preparation.
- Validation and repair scripts now check Traefik configuration, certificate state, network names, and log/secrets directories.
- GitHub lint workflows now use shared yamllint and markdownlint configuration.

### Not Included

- Hermes Agent, Dashboard, WebUI, databases, Prometheus, Grafana, Loki, Redis, Watchtower, and Homepage remain out of scope.

## [0.1.0] - 2026-07-09

### Added

- Phase 1 infrastructure repository structure.
- Modular Docker Compose V2 configuration.
- Traefik edge proxy infrastructure.
- Docker socket proxy security boundary.
- Idempotent lifecycle scripts for install, validation, repair, update, backup, restore, and uninstall.
- Production-oriented documentation and Makefile targets.
- Phase 1 senior DevOps architecture review report.

### Not Included

- Hermes application services.
- Grafana, Prometheus, Loki, Redis, PostgreSQL, or other data-plane services.

### Changed

- Hardened `.env` parsing so configuration is treated as data instead of shell code.
- Removed fixed container names from Compose services.
- Standardized Docker Compose project directory handling.
- Made runtime path variables effective across scripts and Compose mounts.
- Hardened backup, restore, and cleanup behavior.
- Kept Traefik dashboard routing closed in Phase 1.
- Added environment validation, script log files, Docker log rotation, reduced socket-proxy permissions, and Compose conventions for future scale.
