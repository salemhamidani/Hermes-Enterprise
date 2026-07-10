<!--
Hermes Enterprise Stack (HES)
File: AcceptanceCriteria.md
Purpose: Define acceptance criteria for Phase 1, sprints, and releases.
-->

# Acceptance Criteria

This document defines the explicit acceptance criteria for Hermes Enterprise Stack at three levels: the Phase 1 milestone, individual sprints, and releases. A unit of work is accepted only when every applicable criterion is satisfied.

These criteria are the acceptance complement to `DefinitionOfDone.md` (per-task done) and `QUALITY_GATE.md` (per-PR gates).

## Phase 1 Acceptance

Phase 1 is acceptable when **all** of the following are true.

### Structure

- [ ] All required files exist (see the Required Documentation table in `PROJECT_SPEC.md`).
- [ ] Modular Compose files exist in `compose/` (`compose.yml`, `network.yml`, `security.yml`, `traefik.yml`).
- [ ] Lifecycle scripts exist in `scripts/` (install, validate, doctor, repair, update, backup, restore, uninstall).
- [ ] Managed runtime directories exist with `.hes-managed` markers (`logs/`, `backup/`, `ssl/`, `storage/`, `data/`).
- [ ] `.env.example` exists and documents every variable.

### Idempotency

- [ ] `make repair` is idempotent (running it multiple times produces the same result).

### Backup and Restore

- [ ] `make backup` creates a restricted archive (`chmod 600`) containing `.env`, `compose/`, `config/`, `ssl/`, `storage/`, `data/`.
- [ ] `make restore` restores a trusted archive through staged extraction with path validation.

### Validation

- [ ] `make validate` passes on Ubuntu 24.04 LTS with Docker Compose V2.
- [ ] No `container_name`, `version` key, or `latest` tag in any Compose file.
- [ ] Every long-running service has a health check and log rotation.
- [ ] Every service and network has `com.hermes.*` labels.

### Security

- [ ] No secrets are committed.
- [ ] Traefik does not mount the raw Docker socket (discovery goes through the socket proxy).
- [ ] Docker socket proxy permissions are minimal (read-only metadata only).

### Documentation

- [ ] Documentation matches implementation.
- [ ] Architecture diagrams exist in `docs/assets/`.
- [ ] ADRs exist in `docs/adr/` for all Phase 1 decisions.
- [ ] Versioning, release strategy, quality gates, definition of done, and acceptance criteria documents exist.

### Scope

- [ ] The stack remains infrastructure-only (no application, data-plane, or observability services).
- [ ] No Hermes application services are present.
- [ ] No Grafana, Prometheus, Loki, Redis, or PostgreSQL is present.

### CI

- [ ] All GitHub Actions CI checks pass (Validate, Lint, ShellCheck, Docker).

## Sprint Acceptance

A sprint is acceptable when **all** of the following are true.

- [ ] All sprint tasks are completed per `DefinitionOfDone.md`.
- [ ] `make validate` passes.
- [ ] All CI checks are green on the sprint integration branch.
- [ ] PR is reviewed and approved.
- [ ] PR is merged into `develop`.
- [ ] Sprint branch is deleted after merge.
- [ ] Documentation is updated if behavior changed.
- [ ] `CHANGELOG.md` is updated for user-visible changes.
- [ ] No regressions in existing behavior are introduced.
- [ ] Sprint goal stated in the sprint plan is achieved.

## Release Acceptance

A release is acceptable when **all** of the following are true.

### Readiness

- [ ] `develop` is fully tested and all CI checks pass.
- [ ] The full quality gate (`QUALITY_GATE.md`) passes on the release branch.
- [ ] `make validate`, `make doctor`, `make backup`, and `make restore` all succeed.

### Version Artifacts

- [ ] `VERSION` is updated to the target version with a single trailing newline.
- [ ] `VERSION.md` Version History table has the new release row.
- [ ] `CHANGELOG.md` is updated with the new version section and appropriate subsections (Added, Changed, Fixed, Removed).

### Merge and Tag

- [ ] Release PR is reviewed and merged into `main`.
- [ ] An annotated git tag `vX.Y.Z` is created and pushed (pre-releases use `vX.Y.Z-alpha.N` / `beta.N` / `rc.N`).
- [ ] GitHub Release is created (marked pre-release for pre-release tags, latest for final releases).
- [ ] `main` is merged back into `develop`.
- [ ] Release branch is deleted after merge.

### Release Records

- [ ] Release notes are generated from `CHANGELOG.md`.
- [ ] Any architectural decisions made during the release are recorded in `DECISIONS.md` and an ADR.
- [ ] Diagrams in `docs/assets/` are current if architecture changed during the release.
