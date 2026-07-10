<!--
Hermes Enterprise Stack (HES)
File: docs/QualityTooling.md
Purpose: Document local and CI quality tooling for Sprint 1.1 production hardening.
-->

# Quality Tooling

HES quality tooling is split between CI workflows and local scripts. CI enforces repeatable checks, while local commands let maintainers reproduce failures before opening a pull request.

## Tools

| Tool | Purpose | Config |
| --- | --- | --- |
| Trivy | Scan container images for critical vulnerabilities | `.trivyignore` |
| Hadolint | Lint Dockerfiles | `.hadolint.yaml` |
| Markdownlint | Lint Markdown documentation | `.github/markdownlint.json` |
| Yamllint | Lint YAML syntax and style | `.yamllint.yml` |
| ShellCheck | Lint Bash scripts | `.shellcheckrc` |

## Local Commands

Run the complete project validation gate:

```bash
make validate
```

Run the security and quality scanner:

```bash
make security-scan
```

Run Compose validation through portable launcher scripts:

```bash
scripts/compose-validate.sh
```

Run individual tools when installed locally:

```bash
yamllint -c .yamllint.yml .yamllint.yml .github/dependabot.yml compose/ config/ .github/workflows/
markdownlint --config .github/markdownlint.json --ignore docs/Phase1.html "**/*.md"
shellcheck scripts/*.sh scripts/lib/*.sh scripts/install/*.sh
hadolint --config .hadolint.yaml Dockerfile
trivy image --severity CRITICAL --ignore-unfixed traefik:v3.3
```

## CI Workflows

| Workflow | File | Purpose |
| --- | --- | --- |
| CodeQL | `.github/workflows/codeql.yml` | Security analysis for supported languages |
| Docker | `.github/workflows/docker.yml` | Compose configuration validation |
| Docker Lint | `.github/workflows/docker-lint.yml` | Hadolint and Compose policy checks |
| ShellCheck | `.github/workflows/shellcheck.yml` | Bash linting and script hygiene |
| YAML Lint | `.github/workflows/yamllint.yml` | YAML style and syntax validation |
| Markdown Lint | `.github/workflows/markdownlint.yml` | Markdown style validation |
| Lint | `.github/workflows/lint.yml` | Aggregate Markdown and YAML lint gate |
| Validate | `.github/workflows/validate.yml` | Project validation through `make validate` |
| Release | `.github/workflows/release.yml` | GitHub Release generation for release tags |

## Suppression Rules

Suppressions must be narrow and reviewed:

- Trivy suppressions go in `.trivyignore` with a documented review reason.
- ShellCheck suppressions should be line-scoped with `# shellcheck disable=SCxxxx`.
- Hadolint suppressions should be line-scoped in Dockerfiles.
- Markdownlint and yamllint global rule changes require maintainer review because they affect documentation and workflow consistency.
