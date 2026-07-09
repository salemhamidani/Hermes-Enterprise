<!--
Hermes Enterprise Stack (HES)
File: README.md
Purpose: Main project documentation for Phase 1 infrastructure.
-->

# Hermes Enterprise Stack

Hermes Enterprise Stack (HES) is an enterprise-grade infrastructure foundation for future Hermes services.

Phase 1 provides only the infrastructure shell: repository layout, modular Docker Compose V2 files, Traefik ingress, a Docker socket proxy security boundary, lifecycle scripts, and operational documentation.

## Phase 1 Scope

Included:

- Modular Docker Compose Specification files.
- Traefik reverse proxy infrastructure.
- Docker socket proxy for reduced Docker API exposure.
- Environment-driven configuration through `.env`.
- Idempotent Bash lifecycle scripts for Ubuntu 24.04 LTS.
- Documentation, Makefile, GitHub validation workflow, and runtime directories.

Not included:

- Hermes application services.
- Grafana, Prometheus, Loki, Redis, PostgreSQL, or other platform services.

## Requirements

- Ubuntu 24.04 LTS.
- Docker Engine.
- Docker Compose V2.
- Bash.
- `tar`, `find`, `date`, and standard GNU userland tools.

## Quick Start

```bash
cp .env.example .env
make doctor
make validate
make install
```

## Project Layout

```text
Hermes-Enterprise/
  compose/      Modular Docker Compose files.
  config/       Runtime configuration templates and Traefik dynamic config.
  scripts/      Idempotent operational scripts.
  docs/         Professional operator documentation.
  workspace/    Local operator workspace, ignored by Git.
  logs/         Runtime logs, ignored by Git.
  backup/       Backup archives, ignored by Git.
  storage/      Service storage, ignored by Git.
  ssl/          TLS and ACME state, ignored by Git.
  data/         Persistent data, ignored by Git.
  .github/      GitHub project metadata and CI workflow.
```

## Make Targets

| Target | Description |
| --- | --- |
| `make install` | Prepare directories and start Phase 1 infrastructure. |
| `make doctor` | Check host, Docker, Compose, env, and writable paths. |
| `make validate` | Validate scripts and Compose configuration. |
| `make repair` | Recreate expected local directories and missing `.env`. |
| `make update` | Pull infrastructure images and restart the stack. |
| `make backup` | Create a timestamped backup archive. |
| `make restore` | Restore from `HES_RESTORE_ARCHIVE` or the first script argument. |
| `make logs` | Follow Docker Compose logs. |
| `make status` | Show Docker Compose service status. |
| `make clean` | Stop containers and remove orphan containers. |

## Configuration

All configurable values live in `.env`. Never commit `.env` or any derived secret file.

Start from:

```bash
cp .env.example .env
```

Then update the domain, admin email, exposed ports, and storage paths for your environment.

`.env` is parsed as data, not executable shell. Use simple `HES_KEY=value` lines only.

## Operations

Read [Operations](docs/OPERATIONS.md), [Security](docs/SECURITY.md), [Backup and Restore](docs/BACKUP_RESTORE.md), [Compose Conventions](compose/README.md), and the [Audit Report](AUDIT_REPORT.md) before deploying beyond a lab environment.
