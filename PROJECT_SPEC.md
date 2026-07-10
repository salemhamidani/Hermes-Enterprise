<!--
Hermes Enterprise Stack (HES)
File: PROJECT_SPEC.md
Purpose: Project Constitution — every decision, file, script, and contribution must follow this document.
-->

# Hermes Enterprise Stack — Project Constitution

> **This document is the Constitution of the Hermes Enterprise Stack (HES) project.**
> Every architecture decision, line of code, script, configuration file, branch, commit, pull request, and release must conform to the standards defined here.
> When this document and any other document conflict, **this document wins**.
> Changes to this document require maintainer review and an explicit architectural decision record in `DECISIONS.md`.

---

## Table of Contents

1. [Project Identity](#1-project-identity)
2. [Architecture Principles](#2-architecture-principles)
3. [Coding Standards](#3-coding-standards)
4. [Compose Standards](#4-compose-standards)
5. [Shell Standards](#5-shell-standards)
6. [Documentation Standards](#6-documentation-standards)
7. [Naming Standards](#7-naming-standards)
8. [Security Standards](#8-security-standards)
9. [Versioning](#9-versioning)
10. [Release Strategy](#10-release-strategy)
11. [Git Strategy](#11-git-strategy)
12. [Branch Strategy](#12-branch-strategy)
13. [Review Process](#13-review-process)
14. [Acceptance Criteria](#14-acceptance-criteria)
15. [Definition of Done](#15-definition-of-done)

---

## 1. Project Identity

| Field | Value |
| --- | --- |
| Full name | Hermes Enterprise Stack |
| Short name | HES |
| Current phase | Phase 1 — Infrastructure Foundation |
| Target platform | Ubuntu 24.04 LTS |
| Runtime model | Docker Engine with Docker Compose V2 |
| Ingress | Traefik v3 |
| Security boundary | Docker socket proxy (tecnativa/docker-socket-proxy) |
| License | MIT |
| Repository | `https://github.com/salemhamidani/Hermes-Enterprise` |
| Owner | salemhamidani |
| Expected scale | 50+ Docker services |

### Phase 1 Scope

Phase 1 is **infrastructure-only**. No application services, data-plane services, or observability stacks are included.

### Explicitly Out of Scope (Phase 1)

- Hermes application services
- Grafana, Prometheus, Loki
- Redis, PostgreSQL, or any datastore
- Any data-plane service
- Any observability service beyond infrastructure logging
- Multi-node high availability
- Cluster orchestration (Swarm, Kubernetes)

---

## 2. Architecture Principles

### Foundational Principles

1. **Infrastructure-first**: Establish a solid platform before adding business services.
2. **Clean Architecture boundaries**: Keep infrastructure, configuration, operations, and documentation separated.
3. **Modular by design**: One concern per Compose file. One responsibility per script. One topic per document.
4. **Configuration externalization**: Every runtime value lives in `.env`. Never hardcode secrets.
5. **Idempotency**: Every script must be safe to run multiple times without side effects.
6. **Boring and auditable**: Prefer simple, reviewable operations over clever automation.
7. **Security by default**: Reduce attack surface at every layer. Deny by default, allow by exception.
8. **Design for scale now**: Structure for 50+ services even when only 2 exist.
9. **Honest documentation**: Documentation must match implementation. No aspirational docs.
10. **Recovery is a feature**: Backup and restore are first-class infrastructure features, not afterthoughts.

### Layered Model

```text
Operator → Makefile → Bash Lifecycle Scripts → Docker Compose V2 → Infrastructure Modules
```

| Layer | Components | Responsibility |
| --- | --- | --- |
| Orchestration | `compose/compose.yml` | Includes active infrastructure modules. |
| Network | `compose/network.yml` | Defines public and internal Docker networks. |
| Security | `compose/security.yml` | Docker socket proxy with reduced API access. |
| Ingress | `compose/traefik.yml` | HTTP/HTTPS entrypoints and service discovery. |
| Configuration | `config/` | Safe-to-commit runtime configuration. |
| Operations | `scripts/` | Install, validate, doctor, repair, update, backup, restore, uninstall. |
| State | `logs/`, `backup/`, `storage/`, `ssl/`, `data/` | Runtime state outside tracked source. |
| CI/CD | `.github/workflows/` | Automated validation, linting, and releases. |
| Documentation | `docs/`, `*.md` | Operator, architecture, security, audit, and development docs. |

### Network Architecture

```text
Internet → Traefik (hes-public) → Future Services
                    ↓
           Docker Socket Proxy (hes-internal) → Docker API (read-only)
```

- `hes-public`: Public ingress network. Bridge driver. Attachable.
- `hes-internal`: Internal-only network. Bridge driver. `internal: true`. Not attachable.
- Default concrete network names include environment context: `hes-production-public`, `hes-production-internal`.
- Future services join only the networks required for their function.

### Scalability Contract

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

No future service is added as an undocumented one-off.

---

## 3. Coding Standards

### General Rules

- Use LF line endings everywhere. CRLF is rejected by validation.
- Use UTF-8 encoding for all files.
- Do not add inline comments within code unless explicitly requested.
- Do not use one-letter variable names unless explicitly requested.
- Never add copyright or license headers unless specifically requested.
- Keep changes minimal and focused on the task.
- Fix root causes, not symptoms.
- Do not fix unrelated bugs unless asked.

### YAML Standards

- Use 2-space indentation.
- Do not quote keys unless required by the linter (e.g., `on:` in GitHub Actions).
- End every file with a single trailing newline.
- Do not use tabs.
- Keep line length under 200 characters.

### Environment File Standards

- `.env` is parsed as data, not shell code.
- Only `HES_*` variables are allowed.
- Use simple `HES_KEY=value` assignments.
- No shell expansions, command substitutions, or source statements.
- `.env` must never be committed to Git.
- `.env.example` must contain every variable with a safe placeholder default.
- Production mode must not use placeholder values (`example.com`, `admin@example.com`).
- Values may be unquoted or quoted with single or double quotes; quotes are stripped during parsing.

### Makefile Standards

The Makefile must provide stable operator entrypoints:

```text
make install     make doctor      make validate
make repair      make update      make backup
make restore     make logs        make status
make clean       make uninstall
```

Rules:
- `SHELL := /bin/bash`
- All targets are `.PHONY`.
- Compose calls must use `--project-directory .` and `--env-file .env`.
- Targets delegate to lifecycle scripts, not inline logic.

---

## 4. Compose Standards

### Specification Rules

- Use Docker Compose V2 and the current Compose Specification.
- Do not add a top-level `version` key.
- Do not use `container_name`.
- Do not use floating `latest` image tags.
- Use pinned image tags with explicit versions (e.g., `traefik:v3.3`, `tecnativa/docker-socket-proxy:0.3.0`).
- Use service DNS names for service-to-service communication.
- Define health checks for all long-running services.
- Define Docker log rotation for all long-running services.
- Apply `com.hermes.stack`, `com.hermes.environment`, and `com.hermes.phase` labels to every service.
- Use only required networks.
- Keep internal-only services off published ports.
- Keep one infrastructure concern per Compose file.
- Use modular Compose files in `compose/`, with `compose/compose.yml` orchestrating included modules.

### Include Rules

- `compose/compose.yml` includes modules via the `include` directive.
- Include paths are relative to `--project-directory` (project root), not the Compose file location.
- Example: `path: compose/network.yml` (not `./network.yml`).
- Networks are defined once in `network.yml`. Other modules reference them by name only.
- Do not redefine the same network in multiple included files — this causes `conflicts with imported resource` errors.

### Container Hardening Rules

Every container must use:

- `no-new-privileges: true`
- `cap_drop: [ALL]` (add only specific capabilities when required)
- `read_only: true` where supported
- Explicit `tmpfs` paths for writable runtime needs
- `init: true` for process signal handling
- `pids_limit` to constrain process table usage
- `stop_grace_period` for graceful shutdown
- `restart` policy from environment (`HES_RESTART_POLICY`)

### Log Rotation Rules

Every long-running service must define:

```yaml
logging:
  driver: json-file
  options:
    max-size: "${HES_DOCKER_LOG_MAX_SIZE:-10m}"
    max-file: "${HES_DOCKER_LOG_MAX_FILE:-5}"
```

### Health Check Rules

Every long-running service must define a `healthcheck` with:

- `test`: A command that validates service readiness.
- `interval`: 30s default.
- `timeout`: 5s default.
- `retries`: 3 default.
- `start_period`: 10–15s depending on service.

### Module Naming

Use clear domain-based names:

```text
compose/<domain>.yml
```

Examples:

```text
compose/network.yml       compose/security.yml
compose/traefik.yml       compose/observability.yml
compose/datastore.yml     compose/messaging.yml
compose/hermes-api.yml    compose/hermes-worker.yml
```

Do not generate future service modules during Phase 1.

---

## 5. Shell Standards

### Script Requirements

All shell scripts must:

- Use Bash only. No sh, zsh, or fish.
- Start with `set -Eeuo pipefail`.
- Use `#!/usr/bin/env bash` shebang.
- Support Ubuntu 24.04 LTS.
- Include a header comment block: file name and purpose.
- Use shared helpers from `scripts/lib/common.sh`.
- Provide colored terminal output (disabled when not a TTY).
- Write persistent lifecycle logs to `HES_LOG_DIR/scripts/<script>.log`.
- Use clear exit codes (see Exit Codes table).
- Be idempotent — safe to run multiple times.
- Avoid hardcoded secrets.
- Validate environment before risky operations.
- Use LF line endings.

### Exit Codes

| Code | Meaning |
| --- | --- |
| 0 | Success |
| 1 | General failure |
| 64 | Usage error (missing .env, missing archive) |
| 65 | Data error (invalid .env line, invalid value) |
| 66 | Not found (missing directory, missing file) |
| 69 | Service unavailable (Docker not reachable) |
| 70 | Internal error (refusing unsafe path, unmanaged directory) |
| 78 | Configuration error (unsupported OS) |
| 127 | Command not found |

### Shared Library

`scripts/lib/common.sh` provides:

- `load_env` — Parse `.env` as data, export `HES_*` variables.
- `validate_env` — Validate all environment values.
- `setup_logging` — Initialize per-script log file.
- `ensure_directories` — Create and mark runtime directories.
- `mark_managed_dir` / `require_managed_dir` / `clear_managed_dir` — Managed directory safety.
- `compose` — Docker Compose wrapper with project directory and env file.
- `docker_compose_cli_available` — Check if Docker Compose is usable.
- `runtime_path` / `resolve_project_path` — Resolve paths relative to project root.
- Logging: `log_info`, `log_success`, `log_warn`, `log_error`, `die`.
- Validation: `validate_bool`, `validate_port`, `require_positive_int`.

### ShellCheck Compliance

- All scripts must pass `shellcheck` with zero errors.
- Warnings must be fixed or explicitly suppressed via `.shellcheckrc` or inline directives.
- `readonly` declarations must be separated from command substitution assignments to avoid SC2155.

### Required Lifecycle Scripts

```text
scripts/install.sh       scripts/doctor.sh
scripts/validate.sh     scripts/repair.sh
scripts/update.sh       scripts/uninstall.sh
scripts/backup.sh        scripts/restore.sh
```

### Managed Directory Safety

- Runtime directories are marked with `.hes-managed` marker files.
- `clear_managed_dir` refuses to operate on directories without the marker.
- `remove_project_subdir` only allows `compose` and `config` directories.
- Destructive commands use `rm -rf --` with explicit `--` terminator.
- Cleanup uses `find -mindepth 1 -maxdepth 1` to limit scope.

---

## 6. Documentation Standards

### Format Rules

- Documentation is Markdown, except the interactive HTML documentation (`docs/Phase1.html`).
- Language is English.
- Professional and operator-focused tone.
- Present tense, active voice.
- Keep documentation in sync with actual scripts and Compose behavior.
- Use LF line endings.
- End every file with a single trailing newline.

### Required Documentation

| File | Purpose |
| --- | --- |
| `README.md` | Main project documentation, quick start, layout, Make targets. |
| `PROJECT_SPEC.md` | This document — the project Constitution. |
| `ROADMAP.md` | Milestone roadmap from Phase 1 through future expansion. |
| `DECISIONS.md` | Architectural decision register. |
| `AUDIT_REPORT.md` | Senior DevOps audit report. |
| `CHANGELOG.md` | User-visible project changes. |
| `CONTRIBUTING.md` | Contribution guidelines and workflow. |
| `CODE_OF_CONDUCT.md` | Community standards. |
| `SUPPORT.md` | Support channels and troubleshooting. |
| `SECURITY.md` | Security decisions and practices. |
| `ARCHITECTURE.md` | Infrastructure architecture and extension model. |
| `LICENSE` | MIT License. |
| `docs/OPERATIONS.md` | Operator procedures. |
| `docs/BACKUP_RESTORE.md` | Backup and restore procedures. |
| `docs/DEVELOPMENT.md` | Contribution and development standards. |
| `docs/PHASE1_REVIEW_REPORT.md` | Phase 1 review findings and remediations. |
| `docs/Phase1.html` | Interactive HTML documentation. |
| `compose/README.md` | Compose module conventions. |
| `config/README.md` | Configuration directory documentation. |
| `.github/README.md` | GitHub metadata documentation. |

### Commit Message Standards

- Start with an imperative verb (e.g., "Add", "Fix", "Update", "Remove").
- Keep the subject line under 72 characters.
- Use a blank line between subject and body.
- Use bullet points for multi-change commits.
- Reference issues or PRs when relevant.

Example:

```text
Fix network conflict in included Compose modules

- Remove duplicate network definitions from security.yml and traefik.yml
- Networks are defined only in network.yml
- Other modules reference networks by name via include directive
```

---

## 7. Naming Standards

### Repository

- Repository name: `Hermes-Enterprise` (PascalCase in GitHub URL).
- Local directory: `Hermes-Enterprise`.

### Branches

- `main` — stable, production-ready releases only.
- `develop` — ongoing integration for the next release.
- `feature/sprint-NN-description` — sprint-scoped work (e.g., `feature/sprint-01-foundation`).
- `feature/description` — standalone features.
- `bugfix/description` — non-sprint bug fixes.
- `hotfix/description` — urgent production fixes from `main`.
- `release/vX.Y.Z` — release preparation.

### Docker Networks

- `hes-public` — public ingress network.
- `hes-internal` — internal-only infrastructure network.
- Concrete names include environment context: `hes-production-public`, `hes-production-internal`.

### Docker Services

- Lowercase, DNS-safe names.
- Use hyphens as separators (e.g., `docker-socket-proxy`, `traefik`).
- No `container_name` overrides.

### Docker Labels

Every service and network must carry:

```yaml
com.hermes.stack: "${HES_PROJECT_NAME:-hermes-enterprise}"
com.hermes.environment: "${HES_ENVIRONMENT:-production}"
com.hermes.phase: "1"
```

Optional OCI labels:

```yaml
org.opencontainers.image.title: "..."
org.opencontainers.image.description: "..."
```

### Environment Variables

- All variables use the `HES_` prefix.
- Uppercase with underscores: `HES_TRAEFIK_HTTP_PORT`.
- Descriptive names — no abbreviations unless widely understood.

### Scripts

- Lowercase with hyphens or single words: `install.sh`, `doctor.sh`, `validate.sh`.
- One action per script.

### Files

- Markdown: `UPPERCASE.md` for root docs, `lowercase.md` for `docs/`.
- YAML: `lowercase.yml`.
- Shell: `lowercase.sh`.
- Config: `lowercase.yml` in `config/traefik/dynamic/`.

---

## 8. Security Standards

### Secrets

- HES does not hardcode secrets.
- Local secret values belong in `.env` or a future secret manager integration.
- `.env` is ignored by Git.
- Backup archives include `.env` and must use owner-only permissions (`chmod 600`).
- Never commit `.env` or any derived secret file.

### Docker API Exposure

- Traefik must not mount `/var/run/docker.sock` directly.
- Docker API discovery goes through the Docker socket proxy only.
- Docker socket proxy permissions must be minimal — only `CONTAINERS`, `EVENTS`, `INFO`, `NETWORKS`, `VERSION` are enabled.
- `SERVICES`, `TASKS`, `POST`, `AUTH`, `BUILD`, `COMMIT`, `EXEC`, `IMAGES`, `NODES`, `PLUGINS`, `SECRETS`, `SESSION`, `SWARM`, `SYSTEM`, `VOLUMES` are all disabled (`0`).
- The Docker socket is mounted read-only (`:ro`) into the proxy.

### Container Hardening

Phase 1 services use:

- `no-new-privileges: true`
- Dropped Linux capabilities (`cap_drop: [ALL]`)
- Read-only root filesystems where supported
- Explicit `tmpfs` paths for writable runtime
- Process limits (`pids_limit`)
- `init: true` for signal handling
- Internal-only networking for the Docker socket proxy

### TLS

- Traefik is configured for ACME HTTP challenge by default.
- TLS 1.2 minimum (`minVersion: VersionTLS12`).
- HSTS enabled with `stsSeconds: 31536000`, `stsIncludeSubdomains: true`, `stsPreload: true`.
- Production deployments must set `HES_ENVIRONMENT=production`, `HES_DOMAIN`, and `HES_ADMIN_EMAIL` before public exposure.

### Dashboard

- The Traefik dashboard is disabled in Phase 1 (`--api.dashboard=false`).
- No dashboard router labels are published.
- Future dashboard exposure must be added as an authenticated administrative path, not as a default.

### Destructive Operations

- Destructive cleanup must refuse unmanaged directories.
- `clear_managed_dir` requires `.hes-managed` marker.
- `remove_project_subdir` only allows `compose` and `config`.
- Destructive commands use `--` terminator.
- `HES_REMOVE_DATA=false` by default — data removal requires explicit opt-in.

### Production Validation

- When `HES_ENVIRONMENT=production`, the stack refuses to start with placeholder values.
- `HES_DOMAIN` must not be `example.com`.
- `HES_ADMIN_EMAIL` must not be `admin@example.com`.

---

## 9. Versioning

### Semantic Versioning

HES follows [Semantic Versioning 2.0.0](https://semver.org/):

```text
MAJOR.MINOR.PATCH
```

- **MAJOR**: Incompatible infrastructure contract changes (e.g., new mandatory environment variables, removed scripts, changed Compose structure that requires operator migration).
- **MINOR**: New infrastructure features, new Compose modules, new scripts, new documentation (backward-compatible).
- **PATCH**: Bug fixes, security hardening, documentation corrections (backward-compatible).

### Pre-release Identifiers

- `v0.1.0` — Phase 1 initial release.
- `v0.x.0` — Pre-1.0 phases. The `0.x` signals that the infrastructure contract is still evolving.
- `v1.0.0` — First stable infrastructure contract. No breaking changes without a major version bump.
- Pre-release builds: `v0.1.0-alpha.1`, `v0.1.0-beta.1`, `v0.1.0-rc.1`.

### Version Tags

- Git tags use `v` prefix: `v0.1.0`, `v0.2.0`.
- Tags are annotated: `git tag -a v0.1.0 -m "Phase 1 initial release"`.
- The `release.yml` GitHub Actions workflow triggers on `v*` tags to create GitHub Releases.

### Changelog

- All user-visible changes are documented in `CHANGELOG.md`.
- Each release section includes: Added, Changed, Removed, Fixed, and Not Included subsections as applicable.

---

## 10. Release Strategy

### Release Flow

```text
develop (merged and validated)
  ↓
release/vX.Y.Z (release prep branch)
  ↓
Tag vX.Y.Z on main
  ↓
GitHub Release (auto-generated by release.yml)
```

### Release Steps

1. Ensure `develop` is green (all CI checks pass).
2. Create a release branch: `git checkout -b release/vX.Y.Z develop`.
3. Update `CHANGELOG.md` with the new version section.
4. Update any version references in documentation.
5. Commit: `git commit -m "Prepare release vX.Y.Z"`.
6. Open a PR from `release/vX.Y.Z` to `main`.
7. After review and merge, tag `main`: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`.
8. Push the tag: `git push origin vX.Y.Z`.
9. The `release.yml` workflow creates the GitHub Release automatically.
10. Merge `main` back into `develop` to keep them in sync.

### GitHub Release

- Created automatically by `.github/workflows/release.yml`.
- Uses `softprops/action-gh-release@v2`.
- Generates release notes from commit history.
- Draft releases for branch pushes (prerelease).
- Full releases for version tags (`v*`).

### Hotfix Release

1. Create branch from `main`: `git checkout -b hotfix/description main`.
2. Fix the issue.
3. Validate: `make validate`.
4. Open PR to `main`.
5. After merge, tag: `git tag -a vX.Y.Z+1 -m "Hotfix: description"`.
6. Push tag.
7. Merge `main` back into `develop`.

---

## 11. Git Strategy

### Git Flow

HES follows the Git Flow branching model:

```text
main        ← stable, production-ready releases only
  ▲
  │ (release PRs)
develop     ← integration branch for the next release
  ▲
  │ (feature PRs)
feature/*   ← sprint and feature work
```

### Flow Summary

```text
feature → Pull Request → Review → develop → Release → main
```

### Rules

- **Never commit directly to `main`.** No exceptions.
- **Never commit directly to `develop`.** All changes come through PRs.
- All work happens on feature or hotfix branches.
- Feature branches merge into `develop` via Pull Request.
- `develop` merges into `main` during a release via a release PR.
- Hotfixes branch from `main` and merge back to both `main` and `develop`.
- Branch protection rules on `main` enforce PR-only merges.
- Branch protection rules on `develop` enforce PR-only merges.

### Commit Hygiene

- One logical change per commit.
- Commits must pass validation (`make validate`).
- Use clear, descriptive commit messages (see Documentation Standards).
- Do not mix unrelated changes in a single commit.
- Squash commits if requested during review.

### Conventional Branch Prefixes

| Prefix | Purpose | Merges into |
| --- | --- | --- |
| `feature/` | New features, sprint work | `develop` |
| `bugfix/` | Non-urgent bug fixes | `develop` |
| `hotfix/` | Urgent production fixes | `main` + `develop` |
| `release/` | Release preparation | `main` |

---

## 12. Branch Strategy

### Sprint Branches

Each sprint gets its own isolated feature branch:

```text
main
develop
feature/sprint-01-foundation
feature/sprint-02-security
feature/sprint-03-traefik
feature/sprint-04-hermes
feature/sprint-05-dashboard
feature/sprint-06-monitoring
```

### Sprint Branch Rules

- Sprint branches are created from `develop`.
- Each sprint branch contains only the work for that sprint.
- Sprint branches merge back into `develop` via Pull Request.
- No cross-sprint merging — each sprint is independent.
- After merge, the sprint branch is deleted.

### Sprint Workflow

1. `git checkout develop && git pull origin develop`
2. `git checkout -b feature/sprint-NN-description`
3. Work on the sprint tasks.
4. Validate: `make validate`.
5. Push: `git push -u origin feature/sprint-NN-description`.
6. Open a Pull Request against `develop`.
7. Ensure all CI checks pass (Validate, Lint, ShellCheck, Docker).
8. Request review.
9. After approval, merge into `develop`.
10. Delete the sprint branch: `git push origin --delete feature/sprint-NN-description`.

### Branch Protection

- `main`: Requires PR, requires status checks (Validate, Lint, ShellCheck, Docker), requires review, no force push.
- `develop`: Requires PR, requires status checks, requires review, no force push.
- Feature branches: No protection, can be force-pushed during development.

---

## 13. Review Process

### Pull Request Requirements

Every Pull Request must:

1. Target the correct branch (`develop` for features, `main` for hotfixes/releases).
2. Pass all CI checks:
   - **Validate** — `make validate` (Bash syntax, ShellCheck, Compose config, policy checks).
   - **Lint** — Markdown lint (`markdownlint-cli`) and YAML lint (`yamllint`).
   - **ShellCheck** — Shell script validation, CRLF check, shebang check.
   - **Docker** — Compose config validation, policy checks (no `version`, `container_name`, `latest`).
3. Have a clear PR description with:
   - What changed and why.
   - Breaking changes (if any).
   - Testing performed.
   - Documentation updated (if applicable).
4. Be reviewed by at least one maintainer.
5. Have no unresolved review comments.
6. Have up-to-date branch (rebased or merged with target branch).

### Review Checklist

Reviewers must verify:

- [ ] Branch name follows naming conventions.
- [ ] Commit messages follow standards.
- [ ] No secrets committed.
- [ ] No `.env` committed.
- [ ] No `container_name` in Compose files.
- [ ] No `latest` image tags.
- [ ] No deprecated `version` key in Compose files.
- [ ] Health checks present for long-running services.
- [ ] Log rotation present for long-running services.
- [ ] Labels applied (`com.hermes.*`).
- [ ] Scripts start with `set -Eeuo pipefail`.
- [ ] Scripts use shared helpers from `common.sh`.
- [ ] Scripts are idempotent.
- [ ] LF line endings (no CRLF).
- [ ] Documentation updated and in sync.
- [ ] `.env.example` updated if new variables added.
- [ ] No unrelated changes.
- [ ] All CI checks green.

### Review Etiquette

- Be respectful and constructive.
- Focus on the code, not the author.
- Suggest improvements, not just problems.
- Approve only when confident the change is correct and safe.
- Request changes for blocking issues.
- Use inline comments for specific feedback.

---

## 14. Acceptance Criteria

### Phase 1 Acceptance Criteria

Phase 1 is acceptable when:

- All required files exist (see Required Documentation table).
- `make repair` is idempotent — running it multiple times produces the same result.
- `make backup` creates a restricted archive (`chmod 600`) containing `.env`, `compose/`, `config/`, `ssl/`, `storage/`, `data/`.
- `make restore` restores a trusted archive through staged extraction with path validation.
- `make validate` passes on Ubuntu 24.04 LTS with Docker Compose V2.
- No secrets are committed.
- Documentation matches implementation.
- The stack remains infrastructure-only.
- All GitHub Actions CI checks pass (Validate, Lint, ShellCheck, Docker).
- No `container_name`, `version` key, or `latest` tag in Compose files.
- Every long-running service has a health check and log rotation.
- Every service and network has `com.hermes.*` labels.

### Sprint Acceptance Criteria

A sprint is acceptable when:

- All sprint tasks are completed.
- `make validate` passes.
- All CI checks are green on the sprint branch.
- PR is reviewed and approved.
- PR is merged into `develop`.
- Sprint branch is deleted.
- Documentation is updated if behavior changed.

### Release Acceptance Criteria

A release is acceptable when:

- `develop` is fully tested and all CI checks pass.
- `CHANGELOG.md` is updated with the new version section.
- Release PR is reviewed and merged into `main`.
- Version tag is created and pushed.
- GitHub Release is created automatically.
- `main` is merged back into `develop`.

---

## 15. Definition of Done

A task, feature, or sprint is **Done** when **all** of the following are true:

### Code

- [ ] Code follows all standards in this document.
- [ ] Code passes `make validate` on Ubuntu 24.04 LTS.
- [ ] Code passes ShellCheck with zero errors.
- [ ] Code passes yamllint and markdownlint.
- [ ] No CRLF line endings.
- [ ] No hardcoded secrets.
- [ ] No `container_name`, `version`, or `latest` in Compose files.
- [ ] Health checks and log rotation present for long-running services.
- [ ] Labels applied to all services and networks.
- [ ] Scripts are idempotent and use shared helpers.

### Configuration

- [ ] All runtime values are in `.env`.
- [ ] `.env.example` is updated with new variables.
- [ ] No secrets in Compose files or `.env.example`.
- [ ] Configuration is environment-driven.

### Documentation

- [ ] Documentation is updated to reflect the change.
- [ ] Documentation matches implementation.
- [ ] `CHANGELOG.md` is updated for user-visible changes.
- [ ] `DECISIONS.md` is updated for architectural decisions.

### Git

- [ ] Work is on a feature or hotfix branch (never `main` or `develop` directly).
- [ ] Commit messages follow standards.
- [ ] Branch is up-to-date with target branch.
- [ ] PR is opened against the correct target.
- [ ] All CI checks pass.
- [ ] PR is reviewed and approved.
- [ ] PR is merged.
- [ ] Feature branch is deleted after merge.

### Security

- [ ] No secrets committed.
- [ ] No new attack surface introduced.
- [ ] Container hardening maintained.
- [ ] Docker socket proxy permissions remain minimal.
- [ ] Destructive operations remain guarded.

### Operations

- [ ] `make doctor` passes.
- [ ] `make validate` passes.
- [ ] `make backup` creates a valid archive.
- [ ] `make restore` restores from a valid archive.
- [ ] Script lifecycle logs are written.
- [ ] No regressions in existing behavior.

---

## Amendment Process

This Constitution is a living document. To amend it:

1. Open a Pull Request with the proposed change.
2. Title the PR: `Update PROJECT_SPEC: <summary of change>`.
3. Add an entry to `DECISIONS.md` explaining the rationale.
4. The PR follows the standard review process.
5. The PR must target `develop`.
6. After merge, the change is effective immediately for all future work.

---

*This document is the single source of truth for HES project standards. When in doubt, follow this document.*
