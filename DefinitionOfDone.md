<!--
Hermes Enterprise Stack (HES)
File: DefinitionOfDone.md
Purpose: Define when a task, feature, or sprint is Done.
-->

# Definition of Done

A task, feature, or sprint in Hermes Enterprise Stack is **Done** when **all** of the checklists below are satisfied. No checklist item is optional. When an item does not apply, mark it N/A with a one-line reason; it still must be reviewed.

This definition is the operational complement to `QUALITY_GATE.md`. The quality gates enforce automated and review checks on every PR; this document defines what Done means for a unit of work end to end.

## Code Checklist

- [ ] Code follows all standards in `PROJECT_SPEC.md`.
- [ ] Code passes `make validate` on Ubuntu 24.04 LTS with Docker Compose V2.
- [ ] Code passes ShellCheck with zero errors.
- [ ] Code passes yamllint and markdownlint.
- [ ] Code passes hadolint on any Dockerfile touched.
- [ ] No CRLF line endings (LF only).
- [ ] No hardcoded secrets.
- [ ] No `container_name`, `version` key, or `latest` tag in Compose files.
- [ ] Health checks and log rotation present for long-running services.
- [ ] Labels applied to all services and networks (`com.hermes.*`).
- [ ] Scripts start with `set -Eeuo pipefail` and use shared helpers from `common.sh`.
- [ ] Scripts are idempotent (safe to run multiple times without side effects).
- [ ] No debug or placeholder code left behind.
- [ ] No unrelated changes in the PR.

## Configuration Checklist

- [ ] All runtime values are in `.env`.
- [ ] `.env.example` is updated with any new variables and a description.
- [ ] No secrets in Compose files or `.env.example`.
- [ ] Configuration is environment-driven (no hardcoded environment-specific values in source).
- [ ] `docker compose config` succeeds with `.env.example`.

## Documentation Checklist

- [ ] Documentation is updated to reflect the change.
- [ ] Documentation matches implementation (no aspirational docs).
- [ ] `CHANGELOG.md` is updated for user-visible changes.
- [ ] `DECISIONS.md` is updated for architectural decisions.
- [ ] A new or updated ADR exists in `docs/adr/` for any architectural change.
- [ ] Diagrams in `docs/assets/` are updated if architecture changed.
- [ ] `VERSION.md` Version History table is updated if a release is in progress.

## Git Checklist

- [ ] Work is on a feature, release, or hotfix branch (never directly on `main` or `develop`).
- [ ] Branch name follows naming conventions (`feature/*`, `release/*`, `hotfix/*`).
- [ ] Commit messages follow the project standard.
- [ ] Branch is up-to-date with its target branch.
- [ ] PR is opened against the correct target (`develop` for features, `main` for releases and hotfixes).
- [ ] All CI checks pass.
- [ ] PR is reviewed and approved.
- [ ] PR is merged.
- [ ] Feature branch is deleted after merge.

## Security Checklist

- [ ] No secrets committed.
- [ ] No `.env` committed (only `.env.example`).
- [ ] No new attack surface introduced.
- [ ] Container hardening maintained (non-root user where possible, read-only root filesystem where practical).
- [ ] Docker socket proxy permissions remain minimal (read-only metadata only).
- [ ] No raw Docker socket mount in any service.
- [ ] Destructive operations remain guarded (managed-directory markers respected).
- [ ] Trivy scan of referenced images shows no critical vulnerabilities.

## Operations Checklist

- [ ] `make doctor` passes.
- [ ] `make validate` passes.
- [ ] `make backup` creates a valid restricted archive (`chmod 600`).
- [ ] `make restore` restores from a valid archive through staged extraction.
- [ ] Script lifecycle logs are written to `logs/scripts/`.
- [ ] No regressions in existing behavior.
- [ ] Operator runbook or operations doc updated if behavior changed.
