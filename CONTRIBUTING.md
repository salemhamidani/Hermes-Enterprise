# Hermes Enterprise Stack (HES)
# File: CONTRIBUTING.md
# Purpose: Define contribution guidelines and workflow for HES.

# Contributing to Hermes Enterprise Stack

Thank you for your interest in contributing to Hermes Enterprise Stack (HES). This document describes the workflow, standards, and expectations for contributors.

## Branching Model

HES follows a Git Flow branching strategy:

```text
main        ← stable, production-ready releases only
  ▲
  │ (release/PR)
develop     ← integration branch for the next release
  ▲
  │ (feature PRs)
feature/*   ← sprint and feature work
```

### Branch Naming

- `develop` — ongoing integration.
- `feature/sprint-NN-description` — sprint-scoped work.
- `feature/description` — standalone features.
- `bugfix/description` — non-sprint bug fixes.
- `hotfix/description` — urgent production fixes from `main`.

### Rules

- **Never commit directly to `main`.**
- All changes flow through Pull Requests.
- Feature branches merge into `develop` via PR.
- `develop` merges into `main` during a release.
- Hotfixes branch from `main` and merge back to both `main` and `develop`.

## Pull Request Process

1. Create a feature branch from `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/sprint-NN-description
   ```

2. Make your changes following the project standards below.

3. Validate before pushing:
   ```bash
   make validate
   ```

4. Push and open a Pull Request against `develop`:
   ```bash
   git push -u origin feature/sprint-NN-description
   ```

5. Ensure all CI checks pass.

6. Request review from a maintainer.

7. Squash or rebase commits if requested during review.

8. After approval and merge, delete the feature branch.

## Code Standards

### Docker Compose

- Use Docker Compose V2 and the Compose Specification.
- Do not use deprecated `version` keys.
- Do not use `container_name`.
- Do not use floating `latest` image tags.
- Keep one concern per Compose file.
- Add health checks and log rotation to long-running services.
- Apply `com.hermes.stack`, `com.hermes.environment`, and `com.hermes.phase` labels.

### Bash Scripts

- Start every script with `set -Eeuo pipefail`.
- Use shared helpers from `scripts/lib/common.sh`.
- Keep scripts idempotent.
- Provide colored terminal output and persistent logs.
- Use LF line endings.

### Configuration

- All runtime values belong in `.env`.
- Only `HES_*` variables are allowed.
- Never commit secrets or `.env`.

### Documentation

- Documentation is Markdown (except interactive HTML).
- Keep documentation in sync with actual scripts and Compose behavior.
- Update relevant docs when changing behavior.

## Commit Messages

Use clear, descriptive commit messages:

```text
Add Traefik security headers middleware

- Add default HSTS and TLS options
- Register reusable middleware in dynamic config
- Link middleware in compose README
```

Start with an imperative verb. Keep the subject line under 72 characters.

## Issue Reporting

- Search existing issues before creating a new one.
- Include steps to reproduce, expected behavior, and actual behavior.
- Attach relevant logs from `logs/scripts/` when available.

## License

By contributing, you agree that your contributions are licensed under the MIT License.