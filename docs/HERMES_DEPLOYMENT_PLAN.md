<!--
Hermes Enterprise Stack (HES)
File: docs/HERMES_DEPLOYMENT_PLAN.md
Purpose: Non-implementation deployment plan for future Hermes Agent support.
-->

# Hermes Deployment Plan

## Status

This is a planning document only. Sprint 2.5 does not implement Hermes, does not create `compose/hermes.yml`, and does not create containers.

## Deployment Order

Future implementation should deploy Hermes in this order:

1. Select provider through `HERMES_PROVIDER`.
2. Resolve provider metadata with `runtime/provider-loader.sh`.
3. Confirm provider-specific version pin from `docs/HERMES_VERSION_POLICY.md`.
4. Add future implementation variables for UID/GID, ports, hostnames, secrets, and feature toggles.
5. Prepare persistent data and secret paths.
6. Add provider-specific runtime modules only in an implementation sprint.
7. Add dashboard service only after local-only or authenticated routing is designed.
8. Add WebUI only if an official WebUI artifact is verified or a project owner explicitly approves a third-party artifact.
9. Add Traefik routes with security middleware.
10. Add health checks and validation rules.
11. Add backup and restore coverage.
12. Run self review and PR review before merge.

## Agent

The `nous-hermes` provider runtime metadata currently points to `nousresearch/hermes-agent`. Upstream starts the gateway with:

```text
command: ["gateway", "run"]
```

Future HES implementation must adapt this into HES Compose standards:

- Resolve provider metadata before selecting runtime details.
- No `container_name`.
- No `network_mode: host` unless explicitly approved by an ADR.
- Use HES-managed networks.
- Use a provider-selected pinned runtime version.
- Use HES labels, health checks, restart policy, resource limits, log rotation, and security options.

## Dashboard

Upstream starts the dashboard with:

```text
command: ["dashboard", "-host", "127.0.0.1", "--no-open"]
```

Security requirement:

- The dashboard must not be exposed publicly without authentication.
- If routed through Traefik, it must use HTTPS and approved authentication middleware.
- Dashboard exposure must be disabled by default unless the future sprint explicitly requires it.

## WebUI

No separate official Hermes WebUI image was verified during Sprint 2.5.

Future policy:

- Treat built-in dashboard/web assets as provider-specific surfaces, not global HES assumptions.
- Do not use third-party `hermes-webui` images unless a future discovery sprint approves the exact repository, image, owner, tag, and security posture.
- Do not implement WebUI routing until a verified artifact and security model exist.

## Dependencies

Verified upstream dependencies and runtime expectations include:

- Docker-capable Linux runtime for container deployment.
- Persistent `HERMES_HOME`, mapped by upstream to `/opt/data`.
- UID/GID mapping through `HERMES_UID` and `HERMES_GID`.
- API keys and provider secrets supplied as environment variables or files.
- Optional messaging integrations requiring additional secrets.
- Optional Docker access if Hermes workflows need container-backed tools.

HES must decide future Docker socket access separately. Direct Docker socket mounts are not allowed by default; any Docker access must go through the established Docker socket proxy pattern or a dedicated ADR.

## Volumes

Future implementation should use HES-managed persistent storage.

Recommended volume mapping concept:

| Purpose | Upstream path | HES storage concept |
| --- | --- | --- |
| Hermes home/state | `/opt/data` | `HES_DATA_DIR` or dedicated `HES_HERMES_DATA_DIR` |
| Lazy packages | `/opt/data/lazy-packages` | Under Hermes data path |
| Secrets | Mounted read-only secret files | `secrets/` or Docker secrets |
| Logs | Container stdout plus app logs if configured | `HES_LOG_DIR` |

## Secrets

Future implementation must not hardcode secrets.

Potential secret inputs:

- Provider API keys.
- API server key.
- Messaging integration credentials.
- OAuth/session credentials.
- Dashboard authentication credentials if Traefik exposes it.

Secrets must be provided through `.env`, Docker secrets, or another approved secret manager. Public routes must never expose setup screens or stored API keys without authentication.

## Networks

Future Hermes services should attach only to the minimum required networks.

Baseline network intent:

| Service | Public ingress | Internal service traffic | Management access |
| --- | --- | --- | --- |
| Agent/gateway | Only if serving approved API route | Yes | No by default |
| Dashboard | Only through authenticated Traefik route | Yes | No by default |
| WebUI | Not until official artifact is verified | Yes if approved | No |

If the active HES branch includes frontend/backend/management/internal segmentation, Hermes should prefer frontend only for Traefik-routed services and backend for private service traffic. If the active HES branch still uses public/internal only, Hermes should follow that existing contract until an architecture change is approved.

## Traefik Routing

Future Traefik routing must be explicit and secure.

Required route properties:

- HTTPS only.
- No direct host port publishing for public endpoints.
- Security headers middleware.
- Rate limiting middleware.
- Compression middleware where appropriate.
- Authentication middleware for dashboard and admin surfaces.
- Route names and hostnames driven by `.env`.

Suggested future route categories:

| Route | Purpose | Default exposure |
| --- | --- | --- |
| Agent API | Controlled API access if required | Disabled until authenticated |
| Dashboard | Administrative UI | Disabled or authenticated only |
| WebUI | User-facing UI if verified | Disabled until approved |

## Health Checks

Future implementation must define health checks before merge.

Candidate checks:

- Agent process responds to a local health or version command.
- Gateway port responds on an internal endpoint if enabled.
- Dashboard local endpoint responds if dashboard is enabled.
- Logs do not contain startup failures.
- Required data directory is writable by the configured UID/GID.

If upstream does not provide a stable health endpoint, HES must document the fallback health command and its limitations.

## Acceptance Criteria

A future Hermes implementation is acceptable only when:

- The provider is selected and provider version metadata is pinned.
- No forbidden floating tags are used.
- The upstream host-network Compose model is not copied blindly.
- All services are behind HES networks and Traefik contracts.
- Dashboard and admin routes are authenticated or disabled.
- Secrets are externalized.
- Validation scripts detect missing config, secrets, volumes, networks, and health checks.
- Rollback to the previous pinned tag is documented and tested.
