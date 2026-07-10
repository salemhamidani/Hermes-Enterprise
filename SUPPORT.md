# Hermes Enterprise Stack (HES)
# File: SUPPORT.md
# Purpose: Provide support channels and resources for HES users and operators.

# Support

## Documentation

Before opening an issue, review the project documentation:

- **README.md** — Quick start, layout, and Make targets.
- **PROJECT_SPEC.md** — Project specification, standards, and extension contract.
- **docs/ARCHITECTURE.md** — Infrastructure architecture and future extension model.
- **docs/OPERATIONS.md** — Operator procedures for install, validate, update, and uninstall.
- **docs/SECURITY.md** — Security decisions and practices.
- **docs/BACKUP_RESTORE.md** — Backup and restore procedures.
- **docs/DEVELOPMENT.md** — Contribution and development standards.
- **ROADMAP.md** — Milestone roadmap from Phase 1 through future expansion.
- **DECISIONS.md** — Architectural decision register.
- **AUDIT_REPORT.md** — Senior DevOps audit report for Phase 1.
- **docs/PHASE1_REVIEW_REPORT.md** — Phase 1 review findings and remediations.

## Troubleshooting

See the Troubleshooting section in `docs/Phase1.html` or the following common issues:

| Symptom | Likely Cause | Action |
| --- | --- | --- |
| `Required command not found: docker` | Docker CLI not installed. | Install Docker Engine and Docker Compose V2 on Ubuntu 24.04. |
| `Docker daemon is not reachable` | Docker service stopped or permissions missing. | Start Docker and verify operator access. |
| `CRLF line endings detected` | Files edited with Windows line endings. | Convert scripts and Compose files to LF. |
| Ports 80 or 443 fail to bind | Another service using the ports. | Stop the conflicting service or change `HES_TRAEFIK_HTTP_PORT` / `HES_TRAEFIK_HTTPS_PORT`. |
| ACME certificates fail | Domain, DNS, email, or inbound HTTP access is wrong. | Check `HES_DOMAIN`, `HES_ADMIN_EMAIL`, DNS records, and firewall rules. |
| Cleanup refuses a directory | Directory not marked with `.hes-managed`. | Run `make repair` or verify the path. |

## Reporting Issues

1. Search existing issues to avoid duplicates.
2. Open a new issue with:
   - Steps to reproduce.
   - Expected behavior.
   - Actual behavior.
   - Relevant logs from `logs/scripts/`.
   - Environment details (OS, Docker version, Compose version).

## Reporting Security Vulnerabilities

Do not open a public issue for security vulnerabilities.

Report security issues privately to **security@hermes-enterprise.example**.

Include:
- A description of the vulnerability.
- Steps to reproduce.
- Potential impact.
- Suggested fix if available.

## Community

This is an open-source project under the MIT License. Contributions are welcome following the guidelines in **CONTRIBUTING.md**.
