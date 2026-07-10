<!--
Hermes Enterprise Stack (HES)
File: docs/SecurityScanGuide.md
Purpose: Document the unified security scanner, tool installation, result interpretation, CI integration, and suppression policy.
-->

# Security Scan Guide

HES ships a unified security scanner at `scripts/security-scan.sh` and an optional Compose-based Trivy module at `compose/security-scan.yml`. The scanner is idempotent and safe to run repeatedly. Each tool runs only if it is installed; missing tools are reported as `SKIP` rather than failing the run.

## Quick Start

Run the unified scanner from the project root:

```bash
./scripts/security-scan.sh
```

Results print to stdout and are written to `logs/security-scan.log` (overwritten each run).

## Failure Policy

The scanner exits non-zero **only** when a critical finding is detected:

- `CRITICAL` — fails the run (exit code 1).
- `WARN` — advisory; reported and logged but does not fail the run.
- `PASS` — tool ran clean.
- `SKIP` — tool not installed or no matching files.

Critical findings come from:

- **Trivy** — critical-severity, fixable vulnerabilities (`--severity CRITICAL --ignore-unfixed --exit-code 1`).
- **ShellCheck** — error-level script issues (re-scanned with `--severity=error`).
- **Hadolint** — error-level Dockerfile issues.
- **Docker Bench** — non-zero exit (abnormal failure of the benchmark itself).

yamllint and markdownlint are advisory by design; their findings are recorded as `WARN` so style drift does not block the security gate.

## Tools

### Trivy (image vulnerability scanning)

Checks container images for known CVEs using the upstream vulnerability database.

- **Run (host):** the unified scanner scans `HES_TRIVY_SCAN_IMAGES` (defaults to `traefik:v3.3 tecnativa/docker-socket-proxy:0.3.0`).
- **Run (Compose):** `docker compose --env-file .env -f compose/security-scan.yml run --rm trivy`
- **Install:** see <https://aquasecurity.github.io/trivy/latest/getting-started/installation/>
- **Interpret:** `CRITICAL` rows with a fix available fail the run. Review the `VulnerabilityID`, `PkgName`, and `Fixed Version` columns in `logs/security-scan.log`.

### Docker Bench Security (host hardening)

Checks the Docker daemon and host configuration against the CIS Docker Benchmark.

- **Run:** included automatically when `docker-bench-security` is on `PATH`.
- **Install:** `git clone https://github.com/docker/docker-bench-security.git` then run `docker-bench-security/docker-bench-security.sh` (or symlink it onto your `PATH`).
- **Interpret:** output lines tagged `[PASS]`, `[WARN]`, `[INFO]`, and `[NOTE]`. `[WARN]` entries are advisory; address host-level CIS gaps outside of this scanner.

### Hadolint (Dockerfile linting)

Static analysis for Dockerfiles (best practices, build efficiency, and security-relevant rules).

- **Run:** scans every `Dockerfile*` in the project root.
- **Install:** see <https://github.com/hadolint/hadolint#install>
- **Interpret:** findings are `DLxxxx` rules. Error-level findings fail the run; warnings are advisory.

### ShellCheck (shell script linting)

Static analysis for all `scripts/**/*.sh`.

- **Run:** scans `scripts/` recursively.
- **Install:** see <https://github.com/koalaman/shellcheck#installing>
- **Interpret:** error-level findings fail the run; warnings and info are advisory. Project rules live in `.shellcheckrc`.

### yamllint (YAML linting)

Validates syntax and style for every `*.yml` / `*.yaml` file.

- **Run:** scans the project tree (excluding `.git/`).
- **Install:** `pip install yamllint` (see <https://yamllint.readthedocs.io/>).
- **Interpret:** the scanner disables `line-length` and `document-start` rules to match HES conventions; other findings are advisory.

### markdownlint (Markdown linting)

Validates Markdown style for every `*.md` file.

- **Run:** scans the project tree (excluding `.git/`).
- **Install:** `npm install -g markdownlint-cli` (see <https://github.com/igorshubovych/markdownlint-cli>).
- **Interpret:** findings are advisory; add a `.markdownlint.json` config if you want to enforce rules in CI.

## Reading the Output

The scanner prints a structured summary table:

```text
TOOL            STATUS     DETAIL
----            ------     ------
trivy           PASS       no critical vulnerabilities
shellcheck      PASS       no issues
yamllint        WARN       yaml lint findings (see log)
```

Full per-tool output is appended to `logs/security-scan.log` under `=== <tool> (rc=<code>) ===` headers.

## CI Integration Summary

Recommended pipeline stages:

1. Install tools (cache the Trivy DB between runs to avoid rate limits).
2. Run `./scripts/security-scan.sh`.
3. Fail the job on non-zero exit (critical findings only).
4. Upload `logs/security-scan.log` as a build artifact for triage.

For container-based CI, the optional Compose module runs Trivy in isolation:

```bash
docker compose --env-file .env -f compose/security-scan.yml run --rm trivy
```

Note: the Compose Trivy service joins the `hes-internal` network only, so seed `HES_TRIVY_CACHE_DIR` (default `./storage/trivy`) with the vulnerability database before running it without external network access.

## Suppression Policy (False Positives)

- Prefer fixing the finding over suppressing it.
- To suppress a Trivy finding, add the vulnerability ID to a `.trivyignore` file and set `TRIVY_IGNOREFILE` if needed; the host scanner picks up `.trivyignore` automatically.
- To suppress a ShellCheck rule for a specific line, use a `# shellcheck disable=SCxxxx` directive above the line (preferred over a global disable).
- To suppress a Hadolint rule, add a `# hadolint ignore=DLxxxx` comment above the offending Dockerfile line.
- To suppress yamllint findings, add inline `# yamllint disable-line rule:...` directives or extend the inline config in `scripts/security-scan.sh`.
- Document every suppression with a short rationale so reviewers understand why a finding is accepted.
