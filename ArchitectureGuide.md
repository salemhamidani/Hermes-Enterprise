<!--
Hermes Enterprise Stack (HES)
File: ArchitectureGuide.md
Purpose: Comprehensive architecture reference for Phase 1 infrastructure.
-->

# Architecture Guide

This guide explains the complete Hermes Enterprise Stack (HES) Phase 1 architecture: the layered model, network design, security boundaries, Compose module structure, script architecture, and the future extension model.

## System Architecture Overview

HES Phase 1 is an infrastructure-only foundation for future Hermes services. It deliberately excludes application services, data-plane services, and observability stacks. Phase 1 delivers the platform building blocks that all future services consume through documented contracts.

### Architecture Goals

- Keep infrastructure concerns separate from application concerns.
- Keep the stack modular and readable as the number of services grows.
- Keep security boundaries explicit.
- Keep operations repeatable and idempotent.
- Keep configuration externalized through `.env`.
- Keep future service onboarding predictable.

### Phase 1 Components

| Layer | Component | Responsibility |
| --- | --- | --- |
| Orchestration | `compose/compose.yml` | Includes the active infrastructure modules. |
| Network | `compose/network.yml` | Defines public and internal Docker networks. |
| Security | `compose/security.yml` | Runs the Docker socket proxy with reduced API access. |
| Ingress | `compose/traefik.yml` | Provides HTTP/HTTPS entrypoints and service discovery. |
| Configuration | `config/` | Holds safe-to-commit runtime configuration. |
| Operations | `scripts/` | Provides install, validate, doctor, repair, update, backup, restore, and uninstall workflows. |
| State | `logs/`, `backup/`, `storage/`, `ssl/`, `data/` | Holds runtime state outside tracked source files. |
| CI/CD | `.github/workflows/` | Automated validation, linting, and releases. |
| Documentation | `docs/`, `*.md` | Operator, architecture, security, audit, and development docs. |

## Layer Model

HES uses a strict layered model. Each layer calls the next. No layer skips ahead.

```text
Operator → Makefile → Bash Lifecycle Scripts → Docker Compose V2 → Infrastructure Modules
```

### Layer Responsibilities

1. **Operator** — runs `make` targets or scripts directly. Interacts through documented entrypoints only.
2. **Makefile** — maps short targets to lifecycle scripts. Provides stable operator commands.
3. **Bash Lifecycle Scripts** — validate the host, load `.env`, prepare directories, validate configuration, and invoke Docker Compose. Scripts are idempotent.
4. **Docker Compose V2** — assembles modular infrastructure from separate Compose files using the `include` directive.
5. **Infrastructure Modules** — individual Compose files for networks, security, ingress, and future services.

### Layer Boundaries

- Operators never call Docker Compose directly for lifecycle operations. They use `make` targets.
- Scripts never bypass Docker Compose to manipulate containers manually.
- Compose files never hardcode secrets or runtime values. Everything flows through `.env`.
- No layer embeds business logic. Phase 1 is infrastructure only.

## Network Architecture

HES defines two Docker networks with explicit segmentation.

### Networks

| Network | Driver | Internal | Attachable | Purpose |
| --- | --- | --- | --- | --- |
| `hes-public` | bridge | no | yes | Public ingress traffic. Traefik and future public-facing services. |
| `hes-internal` | bridge | yes | no | Internal-only traffic. Docker socket proxy and future private services. |

The `hes-internal` network uses `internal: true`, which blocks external connectivity. This isolates the Docker API proxy from the public internet.

### Concrete Network Names

Network names include environment context to support multiple environments on the same host:

- `hes-production-public` (when `HES_ENVIRONMENT=production`)
- `hes-production-internal`

These names are configurable through `HES_PUBLIC_NETWORK` and `HES_INTERNAL_NETWORK` in `.env`.

### Network Flow

```text
Internet → Traefik (hes-public) → Future Services
                    ↓
           Docker Socket Proxy (hes-internal) → Docker API (read-only)
```

Traefik joins both networks. It receives public traffic on `hes-public` and reaches the Docker socket proxy on `hes-internal`. The socket proxy joins `hes-internal` only, keeping the Docker API isolated from public traffic.

### Future Service Network Rules

- Public-facing services join `hes-public`.
- Internal-only services join `hes-internal`.
- Services join only the networks they need.
- Never expose an internal-only service through published ports.
- East-west traffic between services uses DNS service names.

## Security Architecture

### Docker Socket Proxy

Traefik does not mount `/var/run/docker.sock` directly. Instead, a Docker socket proxy (`tecnativa/docker-socket-proxy:0.3.0`) provides a read-limited API boundary.

The proxy is configured with:

- `CONTAINERS=1`, `EVENTS=1`, `INFO=1`, `NETWORKS=1`, `VERSION=1` — read-only discovery endpoints Traefik needs.
- `POST=0`, `AUTH=0`, `BUILD=0`, `COMMIT=0`, `EXEC=0`, `IMAGES=0`, `PLUGINS=0`, `SECRETS=0`, `SWARM=0`, `VOLUMES=0` — all mutating and sensitive endpoints are blocked.

The proxy mounts the host socket as read-only (`/var/run/docker.sock:/var/run/docker.sock:ro`) and sits on `hes-internal` only.

### Container Hardening

Phase 1 services apply:

- `no-new-privileges:true` via `security_opt`.
- All Linux capabilities dropped (`cap_drop: [ALL]`). Traefik adds back only `NET_BIND_SERVICE`.
- Read-only root filesystems (`read_only: true`).
- Explicit `tmpfs` mounts for writable runtime paths (`/run`, `/tmp`).
- Process limits via `pids_limit`.
- `init: true` for proper signal handling.
- `stop_grace_period` for clean shutdown.

### TLS

Traefik handles TLS termination with ACME HTTP challenge by default:

- Port 80 redirects to port 443.
- ACME certificates persist under `ssl/letsencrypt/acme.json`.
- TLS options enforce minimum TLS 1.2 and SNI strict mode (defined in `config/traefik/dynamic/security-headers.yml`).
- Security headers middleware adds HSTS, X-Content-Type-Options, X-Frame-Options, and Referrer-Policy.

Production deployments must set `HES_ENVIRONMENT=production`, `HES_DOMAIN`, and `HES_ADMIN_EMAIL` before public exposure.

### Dashboard

The Traefik dashboard is disabled in Phase 1 (`--api.dashboard=false`, `traefik.enable: "false"` on the Traefik service). Future dashboard exposure must use authenticated middleware, not a public route.

See `SecurityGuide.md` for the full security reference.

## Compose Module Architecture

HES uses modular Docker Compose files instead of a single monolithic file. This is a deliberate architectural decision (see `DECISIONS.md`, Decision 1) to support growth beyond 50 services.

### Entry Point

`compose/compose.yml` is the orchestration entry point. It declares the project name and includes all active modules:

```yaml
name: ${HES_COMPOSE_PROJECT_NAME:-hes}

include:
  - path: compose/network.yml
  - path: compose/security.yml
  - path: compose/traefik.yml
```

### Module Files

| File | Purpose |
| --- | --- |
| `compose/network.yml` | Defines `hes-public` and `hes-internal` networks. |
| `compose/security.yml` | Defines the `docker-socket-proxy` service. |
| `compose/traefik.yml` | Defines the `traefik` ingress service. |

### Module Rules

- One infrastructure concern per file.
- No top-level `version` key.
- No `container_name`.
- No floating `latest` image tags.
- All runtime values come from `.env` variables.
- Every service and network carries `com.hermes.stack`, `com.hermes.environment`, and `com.hermes.phase` labels.
- Long-running services have health checks and log rotation.

### Include Directive and Ordering

The `include` directive merges modules into a single project. Order matters for readability, not for runtime behavior — Docker Compose resolves service dependencies through network membership and health checks.

Modules are listed from foundational to dependent:

1. `network.yml` — networks must exist before services reference them.
2. `security.yml` — the socket proxy must be available for Traefik.
3. `traefik.yml` — Traefik depends on the socket proxy and both networks.

See `ComposeGuide.md` for the full Compose reference.

## Script Architecture

HES scripts live in `scripts/` with shared utilities in `scripts/lib/common.sh`.

### Common Library

`scripts/lib/common.sh` provides the shared foundation for all lifecycle scripts:

- **Path resolution** — `HES_PROJECT_ROOT`, `resolve_project_path`, `runtime_path`.
- **Environment loading** — `load_env` parses `.env` as data, not as shell. Only `HES_*` variables are accepted. Process-level overrides are preserved.
- **Logging** — `log_info`, `log_success`, `log_warn`, `log_error` provide colored terminal output and persistent file logging. `setup_logging` configures a per-script log file under `logs/scripts/`.
- **Error handling** — `die` logs and exits with a meaningful code. An `ERR` trap (`on_error`) catches failures and logs the line number.
- **Directory management** — `ensure_directories` creates all runtime directories. `mark_managed_dir` stamps directories with `.hes-managed`. `require_managed_dir` and `clear_managed_dir` provide safe cleanup.
- **Validation** — `validate_env` checks all `HES_*` values. `validate_bool`, `validate_port`, `require_positive_int` provide type checks.
- **Compose access** — `compose()` runs `docker compose` with the correct project directory and env file.
- **Host checks** — `require_ubuntu_2404` verifies the OS. `check_docker_compose` verifies Docker and Compose V2. `docker_compose_cli_available` is a non-fatal check used by `repair.sh` and `restore.sh`.

### Lifecycle Scripts

| Script | Purpose |
| --- | --- |
| `scripts/install.sh` | Prepare directories, validate, pull images, start containers. Idempotent. |
| `scripts/doctor.sh` | Diagnose host and project readiness. Non-destructive. |
| `scripts/validate.sh` | Validate scripts and Compose configuration. |
| `scripts/repair.sh` | Recreate runtime directories and `.env` without deleting data. Idempotent. |
| `scripts/update.sh` | Pull current images and restart changed containers. Idempotent. |
| `scripts/backup.sh` | Create a timestamped, owner-only backup archive. |
| `scripts/restore.sh` | Restore from a trusted archive with staged extraction and path validation. |
| `scripts/uninstall.sh` | Stop containers and remove orphans. Preserves data unless `HES_REMOVE_DATA=true`. |

### Script Execution Pattern

Every lifecycle script follows the same pattern:

1. `set -Eeuo pipefail` — strict mode.
2. Source `common.sh`.
3. `main()` function:
   - `log_info` — start message.
   - `require_ubuntu_2404` / `check_docker_compose` / `require_command` — host checks.
   - `ensure_env_file` / `load_env` — environment loading.
   - `ensure_directories` / `setup_logging` — runtime setup.
   - `validate_env` — configuration validation.
   - Domain logic (compose, backup, restore, etc.).
   - `log_success` — completion message.
4. `main "$@"` — invoke with arguments.

## Future Extension Model

Phase 1 is infrastructure-only, but the platform is structured for future Hermes services and platform expansion.

### Service Onboarding Contract

Future Hermes services must:

- Have a dedicated Compose module under `compose/`.
- Declare only the networks they need.
- Route public traffic through Traefik, not through direct host port bindings.
- Include health checks, log rotation, labels, and restart policy.
- Use environment-driven configuration through `.env`.
- Document backup implications and operational ownership.

### Example Future Modules

```text
compose/hermes-api.yml
compose/hermes-worker.yml
compose/messaging.yml
compose/datastore.yml
compose/observability.yml
```

### Scalability Decisions Already in Place

- Modular Compose files instead of one large file.
- Service-to-service communication by DNS-safe service names.
- Environment-driven naming for shared resources.
- Internal and public network separation.
- Label conventions for inventory and automation.
- Log rotation defaults.
- Validation rules that reject common future drift (`container_name`, `version`, `latest`).

### High Availability Direction

Phase 1 is a strong single-node foundation, not a multi-node control plane. Future HA milestones include:

- Redundant ingress capacity.
- Externalized certificate and state strategy.
- Separation of shared data from local host storage.
- Node-level orchestration when operationally justified.

### Observability Direction

Phase 1 provides minimal signals: Docker Compose status, container logs, script logs, and Traefik access logs. A dedicated observability module is planned for a future milestone.

## Diagrams

Architecture diagrams are embedded as Mermaid code blocks in `docs/ARCHITECTURE.md`. These include:

- Network diagram showing traffic flow through Traefik and the socket proxy.
- Docker diagram showing the operator-to-infrastructure call chain.
- Security diagram showing layered controls from internet to services.

Future SVG renderings may live under `docs/assets/`. Mermaid blocks render directly in GitHub and most Markdown viewers.

## Related Documentation

- `README.md` — project overview and quick start.
- `docs/ARCHITECTURE.md` — original architecture document.
- `docs/SECURITY.md` — security decisions summary.
- `SecurityGuide.md` — full security reference.
- `ComposeGuide.md` — full Compose conventions reference.
- `OperationsGuide.md` — day-to-day operations manual.
- `DeveloperGuide.md` — developer onboarding and standards.
- `FolderGuide.md` — directory structure reference.
- `PROJECT_SPEC.md` — project constitution and standards.
- `DECISIONS.md` — architectural decision records.
- `ROADMAP.md` — milestone roadmap.
