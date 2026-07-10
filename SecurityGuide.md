<!--
Hermes Enterprise Stack (HES)
File: SecurityGuide.md
Purpose: Comprehensive security reference for Phase 1 infrastructure.
-->

# Security Guide

This guide documents the security architecture, controls, policies, scanning tools, and incident response procedures for Hermes Enterprise Stack (HES) Phase 1.

## Security Architecture Overview

HES Phase 1 applies defense in depth. Security controls are explicit at every layer: network segmentation, Docker API isolation, container hardening, TLS termination, and secret management.

```text
Internet → Host Firewall / Port Policy → Traefik
  → Security Headers Middleware → Docker Socket Proxy
  → Read-Limited Docker API → Current and Future Services
```

The guiding principle is deny by default, allow by exception. Every service starts with all capabilities dropped and all sensitive endpoints blocked. Only the minimum required access is granted.

### Security Goals

- Reduce attack surface at every layer.
- Isolate the Docker API from public traffic.
- Enforce least-privilege container permissions.
- Externalize all secrets through `.env`.
- Maintain auditable, idempotent operations.
- Keep security boundaries explicit and documented.

## Docker Socket Proxy Security

### Problem

Traefik uses the Docker provider to discover services. The default approach mounts `/var/run/docker.sock` directly into the Traefik container. This grants full Docker API access — including the ability to start containers, execute commands, and escalate privileges on the host.

### Solution

HES places a Docker socket proxy between Traefik and the host Docker socket. The proxy (`tecnativa/docker-socket-proxy:0.3.0`) exposes a filtered HTTP API on port 2375.

### Proxy Configuration

The proxy enables only the read-only endpoints Traefik needs for service discovery:

| Endpoint | Enabled | Purpose |
| --- | --- | --- |
| `CONTAINERS` | 1 | List and inspect containers. |
| `EVENTS` | 1 | Subscribe to container lifecycle events. |
| `INFO` | 1 | Docker daemon info. |
| `NETWORKS` | 1 | List and inspect networks. |
| `VERSION` | 1 | API version info. |

All mutating and sensitive endpoints are explicitly disabled:

| Endpoint | Enabled | Rationale |
| --- | --- | --- |
| `POST` | 0 | Blocks all write operations. |
| `AUTH` | 0 | Blocks authentication operations. |
| `BUILD` | 0 | Blocks image builds. |
| `COMMIT` | 0 | Blocks container commits. |
| `CONFIGS` | 0 | Blocks Docker config objects. |
| `DISTRIBUTION` | 0 | Blocks distribution operations. |
| `EXEC` | 0 | Blocks command execution in containers. |
| `IMAGES` | 0 | Blocks image listing and inspection. |
| `NODES` | 0 | Blocks Swarm node operations. |
| `PLUGINS` | 0 | Blocks plugin operations. |
| `SECRETS` | 0 | Blocks Docker secrets. |
| `SESSION` | 0 | Blocks session operations. |
| `SERVICES` | 0 | Blocks service operations. |
| `SWARM` | 0 | Blocks Swarm operations. |
| `SYSTEM` | 0 | Blocks system operations. |
| `TASKS` | 0 | Blocks task operations. |
| `VOLUMES` | 0 | Blocks volume operations. |

### Network Isolation

The socket proxy joins `hes-internal` only. The `hes-internal` network uses `internal: true`, which blocks external connectivity. The proxy is unreachable from the public internet and from the `hes-public` network.

### Socket Mount

The host socket is mounted as read-only:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

This prevents the proxy from modifying the host socket file even if the proxy itself is compromised.

### Proxy Hardening

The proxy container applies the same hardening as all Phase 1 services: read-only root filesystem, all capabilities dropped, `no-new-privileges`, process limits, and log rotation.

## Container Hardening Measures

Every Phase 1 service applies the following hardening by default:

### Privilege Reduction

- `security_opt: [no-new-privileges:true]` — prevents privilege escalation through setuid binaries.
- `cap_drop: [ALL]` — drops all Linux capabilities. Traefik adds back only `NET_BIND_SERVICE` to bind ports 80 and 443.

### Filesystem Isolation

- `read_only: true` — the container root filesystem is read-only.
- `tmpfs` — explicit temporary filesystems for paths that need writes. The socket proxy uses `/run`; Traefik uses `/tmp`.

### Process Management

- `init: true` — proper PID 1 signal handling and zombie reaping.
- `pids_limit` — limits the number of processes a container can run (128 for the proxy, 256 for Traefik).
- `stop_grace_period` — defines clean shutdown time before forced kill (10s for the proxy, 30s for Traefik).

### Restart Policy

All services use `restart: ${HES_RESTART_POLICY:-unless-stopped}`. Services restart automatically on failure but not after an explicit stop.

### Health Checks

Every long-running service defines a health check with interval, timeout, retries, and start period. This enables Docker to detect and respond to unhealthy containers.

## TLS and Certificate Management

### Traefik TLS Termination

Traefik handles TLS at the edge:

- Port 80 accepts HTTP and redirects to HTTPS (port 443).
- Port 443 terminates TLS.
- ACME HTTP challenge obtains certificates automatically.
- Certificate state persists at `ssl/letsencrypt/acme.json`.

### TLS Options

Default TLS options are defined in `config/traefik/dynamic/security-headers.yml`:

- Minimum TLS version: `VersionTLS12`.
- SNI strict mode enabled.
- HSTS with `stsSeconds: 31536000`, `stsIncludeSubdomains: true`, `stsPreload: true`.

### Security Headers Middleware

The `hes-security-headers` middleware adds:

- `browserXssFilter` — X-XSS-Protection header.
- `contentTypeNosniff` — X-Content-Type-Options: nosniff.
- `frameDeny` — X-Frame-Options: DENY.
- `referrerPolicy: strict-origin-when-cross-origin`.
- HSTS headers (see above).
- `X-Powered-By` header stripped.

### Certificate Storage

ACME state lives under `ssl/letsencrypt/`. This directory is:

- Created by `ensure_directories` in `common.sh`.
- Permission-restricted to `chmod 700`.
- Marked with `.hes-managed`.
- Included in backup archives.
- Git-ignored (runtime state, not source).

### Production Requirements

Before public exposure, set:

```bash
HES_ENVIRONMENT=production
HES_DOMAIN=your-domain.com
HES_ADMIN_EMAIL=admin@your-domain.com
```

The validation script enforces that `HES_DOMAIN` and `HES_ADMIN_EMAIL` are not left at placeholder values when `HES_ENVIRONMENT=production`.

## Secrets Handling Policy

### Core Principle

HES never hardcodes secrets. All secret values belong in `.env` or a future secret manager integration.

### `.env` Is Data, Not Shell

The `.env` file is parsed as data, not as executable shell. The `load_env` function in `common.sh`:

- Reads line by line.
- Accepts only lines matching `^[A-Za-z_][A-Za-z0-9_]*=`.
- Rejects any variable not prefixed with `HES_`.
- Strips surrounding quotes.
- Invalid lines cause an immediate error.

This prevents shell injection through `.env` values.

### Git Policy

- `.env` and all `.env.*` variants are Git-ignored, except `.env.example`.
- `.env.example` contains only placeholder values, never real secrets.
- Validation checks for CRLF line endings and rejects them.
- The `.gitignore` file also excludes `*.log`, `*.tmp`, `*.bak`, `*.swp`, and `.hes-managed`.

### Backup Archives

Backup archives include `.env`, which may contain secrets. To protect them:

- Archives are written with `chmod 600` (owner-only permissions).
- Archives are timestamped and pruned by retention policy (`HES_BACKUP_RETENTION_DAYS`).
- Only restore archives from trusted sources.

### Future Secret Management

Phase 1 uses `.env` for all configuration. A future milestone (see `ROADMAP.md`, Milestone 2) defines a secret management strategy for moving beyond local `.env`. This may include Docker secrets, a secrets manager, or an encrypted store.

## Security Scanning Tools

### ShellCheck

ShellCheck is the primary static analysis tool for Bash scripts.

- Runs automatically in CI (`.github/workflows/shellcheck.yml`).
- Runs locally through `make validate` when installed.
- Checks all files in `scripts/*.sh` and `scripts/lib/*.sh`.
- Configuration in `.shellcheckrc` (disables `SC2155` for declare-and-assign patterns).
- CI also checks shebang lines and rejects CRLF in scripts.

### YAML Lint

`yamllint` validates Compose and configuration files:

- Runs in CI (`.github/workflows/lint.yml`).
- Checks `compose/`, `config/`, and `.github/workflows/`.
- Rules: line-length max 200, document-start disabled.

### Markdown Lint

`markdownlint-cli` validates documentation formatting:

- Runs in CI.
- Checks all `**/*.md` files except `docs/Phase1.html`.

### Validation Script

`make validate` runs repository-specific policy checks:

- Rejects CRLF line endings anywhere in the repository.
- Rejects deprecated `version` keys in Compose files.
- Rejects `container_name` in Compose files.
- Rejects floating `latest` image tags.
- Validates Docker Compose configuration.
- Runs ShellCheck or falls back to `bash -n` syntax checks.

### Future Scanning Direction

Phase 1 does not yet include Docker Bench for Security, Trivy, or Hadolint in CI. These are recommended for future hardening milestones:

- **Docker Bench for Security** — checks host configuration, daemon configuration, and container configuration against CIS Docker Benchmark.
- **Trivy** — scans container images for known vulnerabilities.
- **Hadolint** — lints Dockerfiles for best practices when application Dockerfiles are introduced.

Operators can run these manually on a deployed host:

```bash
# Docker Bench
docker run --rm --net host --pid --userns host --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --label docker_bench_security \
  docker/docker-bench-security

# Trivy image scan
docker run --rm aquasec/trivy image traefik:v3.3

# Hadolint (for Dockerfiles)
docker run --rm hadolint/hadolint < Dockerfile
```

## Network Segmentation

### Two-Network Model

| Network | Visibility | Attachable | Purpose |
| --- | --- | --- | --- |
| `hes-public` | Bridge, external-capable | yes | Traefik and public-facing services. |
| `hes-internal` | Bridge, `internal: true` | no | Socket proxy and private services. |

### Segmentation Rules

- The Docker socket proxy joins `hes-internal` only.
- Traefik joins both networks: `hes-public` for ingress, `hes-internal` to reach the socket proxy.
- Future services join only the networks they need.
- Internal-only services never publish host ports.
- `hes-internal` with `internal: true` blocks all external network egress.

### Default Compose Project

All services share the Compose project name (`HES_COMPOSE_PROJECT_NAME`, default `hes`). This keeps HES resources isolated from other Docker projects on the same host.

## Production Security Checklist

Before deploying HES to production, verify:

### Environment

- [ ] `HES_ENVIRONMENT=production` is set.
- [ ] `HES_DOMAIN` points to the actual domain (not `example.com`).
- [ ] `HES_ADMIN_EMAIL` is a valid email (not `admin@example.com`).
- [ ] `.env` permissions are restricted (owner-only).
- [ ] `.env` is not committed to Git.

### Host

- [ ] Ubuntu 24.04 LTS is installed and updated.
- [ ] Host firewall limits exposure to only ports 80 and 443.
- [ ] Docker daemon is configured with least privilege.
- [ ] Unattended security updates are configured.
- [ ] SSH access uses key-based authentication only.
- [ ] Fail2ban or equivalent brute-force protection is in place.

### Docker

- [ ] Docker Engine is up to date.
- [ ] Docker Compose V2 is installed.
- [ ] Container runtime uses `live-restore` where appropriate.
- [ ] Log rotation is configured (defaults: `10m` max size, 5 files).

### Network

- [ ] Only ports 80 and 443 are exposed to the internet.
- [ ] The Docker socket proxy is on `hes-internal` only.
- [ ] No internal service publishes host ports.

### Containers

- [ ] All services use `no-new-privileges`.
- [ ] All services drop all capabilities (Traefik adds only `NET_BIND_SERVICE`).
- [ ] All services use read-only root filesystems.
- [ ] All services have health checks.
- [ ] All services have log rotation.
- [ ] All services and networks have `com.hermes.*` labels.

### TLS

- [ ] ACME challenge is configured.
- [ ] Certificate storage is permission-restricted (`ssl/letsencrypt` at `700`).
- [ ] HTTP-to-HTTPS redirect is active.
- [ ] HSTS headers are applied.
- [ ] Minimum TLS version is 1.2.

### Operations

- [ ] `make doctor` passes.
- [ ] `make validate` passes.
- [ ] A backup has been created and tested.
- [ ] A restore rehearsal has been completed.
- [ ] Script logs are being written under `logs/scripts/`.

## Security Incident Response

### Preparation

- Keep `make backup` part of the regular operational rhythm.
- Store backup archives off-host or in a secure secondary location.
- Document the contact path for the on-call operator.
- Know the location of runtime logs: `logs/scripts/`, `logs/traefik/access.log`.

### Detection

Monitor for:

- Unusual Traefik access patterns in `logs/traefik/access.log`.
- Container restarts or health check failures (`make status`).
- Socket proxy errors or unauthorized access attempts.
- Unexpected changes to `.env`, `compose/`, or `config/`.

### Containment

If a compromise is suspected:

1. Stop the stack: `make clean` or `make uninstall`.
2. Do not delete data unless certain it is compromised.
3. Isolate the host from the network if necessary.
4. Preserve logs and backup archives for forensic review.

### Eradication

1. Rotate any secrets that may have been exposed (`.env` values, ACME certificates).
2. Rebuild the host if root-level compromise is suspected.
3. Re-pull all images to ensure clean state: `make update`.
4. Re-run `make validate` to confirm policy compliance.

### Recovery

1. Restore from a trusted backup: `make restore`.
2. Re-run `make doctor` and `make validate`.
3. Start the stack: `make install`.
4. Monitor logs for anomalous behavior.
5. Document the incident timeline and root cause.

### Post-Incident

- Update `DECISIONS.md` if the incident reveals an architectural gap.
- Update this guide if new controls or procedures are needed.
- Review backup and restore procedures for gaps.
