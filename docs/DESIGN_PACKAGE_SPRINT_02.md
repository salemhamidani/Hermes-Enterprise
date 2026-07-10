<!--
Hermes Enterprise Stack (HES)
File: docs/DESIGN_PACKAGE_SPRINT_02.md
Purpose: Sprint 2 implementation design package for the security foundation.
-->

# Sprint 2 Design Package: Security Foundation

## Objectives

Build the production security foundation for HES version 1.1.0 while keeping the project infrastructure-only.

## Scope

- Production Docker network segmentation.
- Production Traefik security foundation.
- Reusable security headers, rate limiting, compression, TLS, logs, metrics, and health endpoints.
- Docker secrets preparation without secret values.
- Validation and repair upgrades for Traefik, certificates, networks, and permissions.
- Operator documentation and Sprint 2 review artifacts.

## Out of Scope

- Hermes Agent.
- Hermes Dashboard.
- Hermes WebUI.
- Prometheus, Grafana, Loki, Redis, PostgreSQL, Watchtower, Homepage, or any database.
- Application routing for Hermes services.

## Architecture

Sprint 2 keeps the Phase 1 architecture intact:

```text
Operator -> Makefile -> Bash lifecycle scripts -> Docker Compose V2 -> Infrastructure modules
```

The only runtime modules remain network, security, and Traefik. No business service is added.

## Network Design

| Logical network | Env variable | Purpose |
| --- | --- | --- |
| `hes-frontend` | `HES_FRONTEND_NETWORK` | Public ingress network for Traefik and future public services. |
| `hes-backend` | `HES_BACKEND_NETWORK` | Internal backend network reserved for future Hermes services. |
| `hes-management` | `HES_MANAGEMENT_NETWORK` | Internal management network for Traefik and Docker socket proxy. |
| `hes-internal` | `HES_INTERNAL_NETWORK` | Reserved internal infrastructure network for future modules. |
| `hes-public` | `HES_PUBLIC_NETWORK` | Backward-compatible public network retained for existing operators. |

Actual Docker network names are configurable through `.env`; no concrete production network name is required in Compose service definitions.

## Threat Model

| Threat | Control |
| --- | --- |
| Raw Docker socket exposure | Docker socket proxy on the management network only. |
| Public access to internal services | Internal networks are marked `internal: true` and not published. |
| Clickjacking and content sniffing | Reusable Traefik security headers middleware. |
| Protocol downgrade | HTTP to HTTPS redirect and TLS policy. |
| Request flooding | Reusable rate limit middleware. |
| Secret leakage | `.env` ignored, `secrets/` ignored except metadata, no hardcoded secrets. |
| Unsafe certificate state | ACME directory permissions and repair workflow. |

## Deployment Flow

```text
cp .env.example .env
make repair
make validate
make install
make status
```

Traefik starts with HTTPS, ACME HTTP challenge, structured logs, metrics endpoint preparation, and ping health checks. No Hermes route is published.

## Rollback Plan

1. Stop the Sprint 2 stack with `make clean`.
2. Revert to the previous validated branch or tag.
3. Run `make repair` to restore directory permissions.
4. Run `make validate`.
5. Start the previous stack with `make install`.

Runtime state remains under `logs/`, `ssl/`, `storage/`, `data/`, and `backup/`.

## Test Plan

- Parse all YAML files.
- Validate Markdown and YAML through GitHub Actions.
- Run `make validate` in CI.
- Validate Compose config through Docker workflow.
- Run ShellCheck in CI.
- Confirm no forbidden services are introduced.
- Confirm no hardcoded secrets are added.

## Acceptance Criteria

- All Sprint 2 files exist.
- No Hermes, dashboard, monitoring, database, or WebUI service is implemented.
- Every runtime value is configurable through `.env`.
- Compose services include health checks, restart policy, resource limits, security options, read-only filesystems where possible, `tmpfs`, dropped capabilities, and log rotation.
- GitHub Actions are green on the PR.

## Risks

- ACME production requires valid DNS and routable HTTP port 80.
- Local Windows validation cannot fully replace Ubuntu 24.04 CI validation.
- Future services must opt into the reusable Traefik middlewares explicitly.

## Dependencies

- Ubuntu 24.04 LTS.
- Docker Engine.
- Docker Compose V2.
- Traefik v3.3.
- Docker socket proxy image `tecnativa/docker-socket-proxy:0.3.0`.

## Future Integration

Future Hermes services will attach to `hes-frontend` only when public routing is required, to `hes-backend` for private east-west traffic, and to `hes-management` only for approved infrastructure management use cases.
