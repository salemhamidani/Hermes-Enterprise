<!--
Hermes Enterprise Stack (HES)
File: .github/README.md
Purpose: Document GitHub project metadata, automation, and workflow ownership for HES.
-->

# GitHub Metadata

This directory contains repository automation, CI workflows, Dependabot configuration, and shared lint configuration for Hermes Enterprise Stack.

## Workflows

| Workflow | File | Trigger | Purpose |
| --- | --- | --- | --- |
| CodeQL | `.github/workflows/codeql.yml` | Push, pull request, weekly schedule | Runs GitHub CodeQL analysis and uploads security results to the Security tab. |
| Docker | `.github/workflows/docker.yml` | Push and pull request | Validates Docker Compose configuration and base stack compatibility. |
| Docker Lint | `.github/workflows/docker-lint.yml` | Compose and Dockerfile changes | Runs Hadolint, validates Compose config, and enforces Compose policy checks. |
| ShellCheck | `.github/workflows/shellcheck.yml` | Script changes | Runs ShellCheck and validates script line endings and shebangs. |
| YAML Lint | `.github/workflows/yamllint.yml` | YAML changes | Runs yamllint with the shared `.yamllint.yml` configuration. |
| Markdown Lint | `.github/workflows/markdownlint.yml` | Markdown changes | Runs markdownlint with `.github/markdownlint.json`. |
| Lint | `.github/workflows/lint.yml` | Markdown and YAML changes | Aggregate lint gate for Markdown and YAML changes. |
| Validate | `.github/workflows/validate.yml` | Push and pull request | Runs `make validate` after preparing the CI environment. |
| Release | `.github/workflows/release.yml` | `main` pushes and `v*` tags | Validates release state and publishes GitHub Releases. |

## Dependency Automation

Dependabot is configured in `.github/dependabot.yml` for:

- GitHub Actions updates.
- Docker ecosystem updates.

Dependabot PRs must pass the same quality gates as human-authored changes.

## Shared Configuration

| File | Purpose |
| --- | --- |
| `.github/markdownlint.json` | Markdownlint rule configuration. |
| `.yamllint.yml` | Yamllint rule configuration. |
| `.hadolint.yaml` | Hadolint rule configuration. |
| `.shellcheckrc` | ShellCheck rule configuration. |
| `.trivyignore` | Reviewed Trivy vulnerability suppressions. |

## Branch Policy

Workflow changes follow the project Git Flow:

1. Create a `feature/*` branch from `develop`.
2. Open a pull request to `develop`.
3. Require review and green CI before merge.
4. Release branches promote validated changes to `main`.
