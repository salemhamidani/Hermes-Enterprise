<!--
Hermes Enterprise Stack (HES)
File: QUALITY_GATE.md
Purpose: Define the quality gates that every PR and release must pass before merge.
-->

# Quality Gates

Every pull request and every release for Hermes Enterprise Stack must pass the gates defined in this document before it is merged or tagged. No gate is optional. If a gate fails, the change is blocked until it is resolved or an explicit, documented exception is granted by a maintainer.

The gates are grouped into four categories: code quality, security, Compose, and documentation. All gates must pass before merge.

## Code Quality Gates

These gates keep the codebase clean, consistent, and free of common defects.

| Tool | Scope | Rule | Blocking |
| --- | --- | --- | --- |
| ShellCheck | `scripts/*.sh` | Zero errors. Warnings reviewed and explicitly silenced with a justification comment when necessary. | Yes |
| yamllint | `compose/*.yml`, `config/**/*.{yml,yaml}` | Passes with the project yamllint config. No trailing whitespace, no tabs, consistent indentation, no document-end marker issues. | Yes |
| markdownlint | `**/*.md` | Passes with the project markdownlint config. No style violations. | Yes |
| hadolint | all Dockerfiles (present or future) | Passes with zero errors. Pin versions, no `latest` base tags, no `apt-get upgrade`. | Yes |

### Code Quality Checklist

- [ ] ShellCheck passes with zero errors on every shell script touched.
- [ ] yamllint passes on every YAML file touched.
- [ ] markdownlint passes on every Markdown file touched.
- [ ] hadolint passes on every Dockerfile touched.
- [ ] No CRLF line endings anywhere (LF only).
- [ ] No trailing whitespace.
- [ ] No debug or placeholder code left behind.

## Security Gates

These gates keep the attack surface minimal and the supply chain trustworthy.

| Tool | Scope | Rule | Blocking |
| --- | --- | --- | --- |
| CodeQL | source (shell, YAML, Dockerfile) | Zero high or critical alerts. Medium alerts reviewed. | Yes |
| Trivy | container images referenced in Compose | Zero `CRITICAL` vulnerabilities in referenced images. `HIGH` vulnerabilities reviewed and documented. | Yes |
| Docker Bench | host Docker daemon configuration | No high-severity findings. Configuration follows CIS Docker Benchmark where applicable. | Yes |

### Security Checklist

- [ ] No secrets committed (no API keys, passwords, certificates in tracked files).
- [ ] No `.env` committed (only `.env.example`).
- [ ] No new attack surface introduced.
- [ ] Docker socket proxy permissions remain minimal (read-only metadata only).
- [ ] No raw Docker socket mount in any Compose service.
- [ ] Container hardening maintained (read-only root filesystem where practical, non-root user where possible).
- [ ] Destructive operations remain guarded (managed-directory markers respected).
- [ ] Trivy scan of referenced images shows no critical vulnerabilities.

## Compose Gates

These gates enforce the Compose policy contract that keeps the stack scalable to 50+ services.

| Gate | Rule | Blocking |
| --- | --- | --- |
| Config validation | `docker compose config` succeeds on `compose/compose.yml` with the current `.env.example`. | Yes |
| No `latest` tags | No service uses an image tag ending in `latest`. All images are pinned to a specific version or digest. | Yes |
| No `container_name` | No service defines `container_name`. Compose naming is left to the project name. | Yes |
| No deprecated `version` key | No Compose file contains a top-level `version` key. | Yes |
| Healthchecks | Every long-running service defines a `healthcheck`. | Yes |
| Log rotation | Every long-running service defines logging options with size and retention. | Yes |
| Labels | Every service and network has `com.hermes.*` labels. | Yes |
| Restart policy | Every service defines a `restart` policy. | Yes |

### Compose Checklist

- [ ] `docker compose config` exits successfully.
- [ ] No image uses a `latest` tag.
- [ ] No service defines `container_name`.
- [ ] No Compose file has a deprecated top-level `version` key.
- [ ] Every long-running service has a `healthcheck`.
- [ ] Every long-running service has log rotation configured.
- [ ] Every service and network has `com.hermes.*` labels.
- [ ] Every service has a `restart` policy.
- [ ] Services attach only to the networks they require.
- [ ] No unexpected host port bindings on internal-only services.

## Documentation Gates

These gates keep documentation honest and in sync with implementation.

| Gate | Rule | Blocking |
| --- | --- | --- |
| In sync | Documentation matches implementation. No aspirational or unimplemented features are documented as present. | Yes |
| Updated | Documentation is updated for any user-visible or operator-visible change. | Yes |
| `VERSION.md` | Version History table is current when a release is in progress. | Yes (release) |
| `CHANGELOG.md` | A new version section exists when a release is in progress. | Yes (release) |
| ADRs | A new or updated ADR exists in `docs/adr/` when an architectural decision is made. | Yes |
| Diagrams | Diagrams in `docs/assets/` are updated when architecture changes. | Yes |

### Documentation Checklist

- [ ] Documentation matches implementation.
- [ ] No aspirational documentation (no claims of features that do not exist).
- [ ] `.env.example` is updated if new variables were added.
- [ ] `CHANGELOG.md` is updated for user-visible changes.
- [ ] `DECISIONS.md` is updated for architectural decisions.
- [ ] ADR added or updated in `docs/adr/` for any decision change.
- [ ] Diagrams in `docs/assets/` reflect the current architecture.

## All Gates Must Pass Before Merge

No pull request may be merged into `develop`, `main`, or any release/hotfix branch until every gate above passes. CI automates the gates that can be automated; the checklists cover the gates that require human judgment.

### Enforcement

- CI runs ShellCheck, yamllint, markdownlint, hadolint, CodeQL, Trivy, and Docker Bench automatically.
- `make validate` runs the Compose policy checks and environment validation.
- Reviewers verify the documentation and security checklists before approving.
- A maintainer may grant a documented exception only for a specific gate, recorded in the PR description with rationale. Exceptions never weaken the security gates.

### Release Gate

In addition to the per-PR gates above, every release must additionally pass:

- [ ] `make validate`, `make doctor`, `make backup`, and `make restore` all succeed.
- [ ] `VERSION` and `VERSION.md` are updated for the target release.
- [ ] `CHANGELOG.md` has the new version section.
- [ ] All gates green on the release or hotfix branch, not just `develop`.

See `docs/ReleaseStrategy.md` for the full release workflow and `DefinitionOfDone.md` for the per-task definition of done.
