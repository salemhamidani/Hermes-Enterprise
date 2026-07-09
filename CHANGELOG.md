<!--
Hermes Enterprise Stack (HES)
File: CHANGELOG.md
Purpose: Track user-visible project changes.
-->

# Changelog

All notable changes to Hermes Enterprise Stack are documented here.

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
