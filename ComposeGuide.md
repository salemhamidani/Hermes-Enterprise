<!--
Hermes Enterprise Stack (HES)
File: ComposeGuide.md
Purpose: Comprehensive Docker Compose V2 reference for HES infrastructure.
-->

# Compose Guide

This guide documents how HES uses Docker Compose V2: the modular file architecture, include directives, network conventions, label conventions, health check standards, log rotation, container hardening, how to add new service modules, validation rules, and image version policy.

## Docker Compose V2 Usage in HES

HES uses Docker Compose V2 exclusively. The `docker compose` subcommand (not the legacy `docker-compose` standalone binary) is the only supported interface. All lifecycle scripts call Compose through the `compose()` helper in `scripts/lib/common.sh`, which ensures consistent project directory and env-file handling.

### Compose Helper

Every script uses the shared `compose()` function:

```bash
compose() {
  docker compose \
    --project-directory "${HES_PROJECT_ROOT}" \
    --env-file "${HES_ENV_FILE}" \
    -f "${HES_COMPOSE_FILE}" \
    "$@"
}
```

This guarantees:

- The project directory is always the repository root.
- The `.env` file is always loaded.
- The entry point is always `compose/compose.yml`.
- Variable substitution works consistently.

### Project Name

The project name is set in `compose/compose.yml`:

```yaml
name: ${HES_COMPOSE_PROJECT_NAME:-hes}
```

This is configurable through `HES_COMPOSE_PROJECT_NAME` in `.env` (default `hes`). All resources (containers, networks) are prefixed with this name, keeping HES isolated from other Docker projects on the same host.

## Modular File Architecture

HES splits infrastructure into separate Compose files, one concern per file. This is a deliberate architectural decision (see `DECISIONS.md`, Decision 1) to support growth beyond 50 services.

### Module Files

| File | Purpose |
| --- | --- |
| `compose/compose.yml` | Orchestration entry point. Includes all active modules. |
| `compose/network.yml` | Defines `hes-public` and `hes-internal` Docker networks. |
| `compose/security.yml` | Defines the `docker-socket-proxy` service. |
| `compose/traefik.yml` | Defines the `traefik` ingress service. |

### Why Modular

- Reviews stay small and focused.
- Ownership is clear per module.
- Validation can check each file independently.
- Future services add their own module without touching infrastructure files.
- A single monolithic file becomes unmaintainable at 50+ services.

## Include Directive and Ordering

### Entry Point

`compose/compose.yml` uses the `include` directive to merge modules:

```yaml
name: ${HES_COMPOSE_PROJECT_NAME:-hes}

include:
  - path: compose/network.yml
  - path: compose/security.yml
  - path: compose/traefik.yml
```

### How Include Works

The `include` directive merges the contents of referenced files into the same Compose project. All services, networks, volumes, and configurations from included files become part of one unified project.

### Ordering

Modules are listed from foundational to dependent:

1. **`network.yml`** — networks must be defined before services reference them.
2. **`security.yml`** — the socket proxy must be available for Traefik to use as its Docker endpoint.
3. **`traefik.yml`** — Traefik depends on the socket proxy and both networks.

Order matters for readability and review, not for runtime behavior. Docker Compose resolves dependencies through service-to-service references and health checks.

### Adding a Module to the Include List

When adding a new module, append it after the existing entries:

```yaml
include:
  - path: compose/network.yml
  - path: compose/security.yml
  - path: compose/traefik.yml
  - path: compose/<new-module>.yml
```

## Network Conventions

### Two Networks

| Network | Driver | Internal | Attachable | Purpose |
| --- | --- | --- | --- | --- |
| `hes-public` | bridge | no | yes | Public ingress. Traefik and future public-facing services. |
| `hes-internal` | bridge | yes | no | Internal-only. Socket proxy and future private services. |

### Network Definitions

```yaml
networks:
  hes-public:
    name: ${HES_PUBLIC_NETWORK:-hes-production-public}
    driver: bridge
    attachable: true
    labels:
      com.hermes.stack: "${HES_PROJECT_NAME:-hermes-enterprise}"
      com.hermes.environment: "${HES_ENVIRONMENT:-production}"
      com.hermes.phase: "1"

  hes-internal:
    name: ${HES_INTERNAL_NETWORK:-hes-production-internal}
    driver: bridge
    internal: true
    attachable: false
    labels:
      com.hermes.stack: "${HES_PROJECT_NAME:-hermes-enterprise}"
      com.hermes.environment: "${HES_ENVIRONMENT:-production}"
      com.hermes.phase: "1"
```

### Network Rules

- Public-facing services join `hes-public`.
- Private infrastructure services join `hes-internal`.
- Future application services join only the networks they need.
- Never expose an internal-only service through published ports.
- The `hes-internal` network uses `internal: true`, which blocks external connectivity entirely.
- Network names include environment context (e.g., `hes-production-public`) to support multiple environments on the same host.

### Traefik Network Membership

Traefik joins both networks:

```yaml
networks:
  - hes-public
  - hes-internal
```

This allows Traefik to receive public traffic on `hes-public` and reach the Docker socket proxy on `hes-internal`.

## Label Conventions

### Required Labels

Every service and network carries these labels:

| Label | Value | Source |
| --- | --- | --- |
| `com.hermes.stack` | Project name | `${HES_PROJECT_NAME:-hermes-enterprise}` |
| `com.hermes.environment` | Environment | `${HES_ENVIRONMENT:-production}` |
| `com.hermes.phase` | Phase number | `"1"` |

### Optional OCI Labels

Services also carry descriptive OCI labels for inventory and documentation:

| Label | Purpose |
| --- | --- |
| `org.opencontainers.image.title` | Human-readable service title. |
| `org.opencontainers.image.description` | One-line service description. |

### Traefik-Specific Label

The Traefik service carries `traefik.enable: "false"` to prevent self-routing. The Traefik dashboard is disabled in Phase 1.

### Label Example

```yaml
labels:
  traefik.enable: "false"
  com.hermes.stack: "${HES_PROJECT_NAME:-hermes-enterprise}"
  com.hermes.environment: "${HES_ENVIRONMENT:-production}"
  com.hermes.phase: "1"
  org.opencontainers.image.title: "Hermes Enterprise Stack Traefik"
  org.opencontainers.image.description: "Ingress reverse proxy for HES Phase 1 infrastructure."
```

## Health Check Standards

Every long-running service defines a health check. This lets Docker detect unhealthy containers and provides operational visibility through `make status`.

### Health Check Structure

```yaml
healthcheck:
  test: ["CMD", "<command>", "<args>"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 15s
```

### Current Health Checks

| Service | Test | Interval | Timeout | Retries | Start Period |
| --- | --- | --- | --- | --- | --- |
| `docker-socket-proxy` | `wget` to `http://127.0.0.1:2375/version` | 30s | 5s | 3 | 10s |
| `traefik` | `traefik healthcheck --ping` | 30s | 5s | 3 | 15s |

### Standards

- Use `CMD` test format with an array of strings.
- Set `start_period` to allow for slow startup (10-15s for infrastructure services).
- Keep `interval` at 30s unless the service has specific requirements.
- Set `timeout` to 5s or appropriate for the check.
- Set `retries` to 3 to avoid false negatives from transient failures.

## Log Rotation Standards

All long-running services configure Docker log rotation to prevent unbounded disk growth.

### Log Rotation Structure

```yaml
logging:
  driver: json-file
  options:
    max-size: "${HES_DOCKER_LOG_MAX_SIZE:-10m}"
    max-file: "${HES_DOCKER_LOG_MAX_FILE:-5}"
```

### Defaults

| Variable | Default | Description |
| --- | --- | --- |
| `HES_DOCKER_LOG_MAX_SIZE` | `10m` | Maximum size of each log file before rotation. |
| `HES_DOCKER_LOG_MAX_FILE` | `5` | Number of rotated log files to retain. |

### Validation

The `validate_env()` function in `common.sh` checks that `HES_DOCKER_LOG_MAX_SIZE` matches the pattern `^[0-9]+[kKmMgG]?$` and that `HES_DOCKER_LOG_MAX_FILE` is a positive integer.

## Container Hardening Standards

Every Phase 1 service applies the following hardening by default. Future services must follow the same standards.

### Privilege Reduction

```yaml
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
```

Traefik adds back only the capability it needs:

```yaml
cap_add:
  - NET_BIND_SERVICE
```

### Filesystem Isolation

```yaml
read_only: true
tmpfs:
  - /tmp
```

The socket proxy uses `tmpfs: /run` instead.

### Process Management

```yaml
init: true
pids_limit: 256
stop_grace_period: 30s
```

### Restart Policy

```yaml
restart: ${HES_RESTART_POLICY:-unless-stopped}
```

### Complete Service Example

```yaml
services:
  traefik:
    image: ${HES_TRAEFIK_IMAGE:-traefik:v3.3}
    restart: ${HES_RESTART_POLICY:-unless-stopped}
    read_only: true
    init: true
    pids_limit: 256
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    tmpfs:
      - /tmp
    # ... command, ports, volumes, networks, healthcheck, logging, labels
```

## How to Add a New Service Module

### Step 1: Create the Compose File

Create `compose/<domain>.yml` with a header comment:

```yaml
# Hermes Enterprise Stack (HES)
# File: compose/<domain>.yml
# Purpose: <one-line description>.
```

### Step 2: Define the Project Name

Every module file includes the project name:

```yaml
name: ${HES_COMPOSE_PROJECT_NAME:-hes}
```

### Step 3: Define Services

Follow the hardening, health check, log rotation, and label standards:

```yaml
services:
  <service-name>:
    image: ${HES_<SERVICE>_IMAGE:-<image>:<version>}
    restart: ${HES_RESTART_POLICY:-unless-stopped}
    read_only: true
    init: true
    pids_limit: 256
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    tmpfs:
      - /tmp
    healthcheck:
      test: ["CMD", "<command>"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 15s
    logging:
      driver: json-file
      options:
        max-size: "${HES_DOCKER_LOG_MAX_SIZE:-10m}"
        max-file: "${HES_DOCKER_LOG_MAX_FILE:-5}"
    networks:
      - hes-public
    labels:
      com.hermes.stack: "${HES_PROJECT_NAME:-hermes-enterprise}"
      com.hermes.environment: "${HES_ENVIRONMENT:-production}"
      com.hermes.phase: "1"
```

### Step 4: Add to the Include List

Update `compose/compose.yml`:

```yaml
include:
  - path: compose/network.yml
  - path: compose/security.yml
  - path: compose/traefik.yml
  - path: compose/<domain>.yml
```

### Step 5: Add Environment Variables

Add new `HES_*` variables to `.env.example`:

```bash
HES_<SERVICE>_IMAGE=<image>:<version>
```

### Step 6: Validate

```bash
make validate
make doctor
make install
```

### Checklist for New Modules

- [ ] File header comment block present.
- [ ] Project name declared.
- [ ] No top-level `version` key.
- [ ] No `container_name`.
- [ ] No `latest` image tag.
- [ ] Service name is lowercase and DNS-safe.
- [ ] `no-new-privileges:true` in `security_opt`.
- [ ] All capabilities dropped (`cap_drop: [ALL]`).
- [ ] Read-only root filesystem (`read_only: true`).
- [ ] Explicit `tmpfs` for writable paths.
- [ ] `init: true`.
- [ ] `pids_limit` set.
- [ ] `stop_grace_period` set.
- [ ] Restart policy set.
- [ ] Health check present.
- [ ] Log rotation present.
- [ ] `com.hermes.stack`, `com.hermes.environment`, `com.hermes.phase` labels present.
- [ ] Only needed networks joined.
- [ ] No internal service publishes host ports.
- [ ] All runtime values in `.env`.
- [ ] `.env.example` updated with new variables.
- [ ] `make validate` passes.

## Validation Rules

The `scripts/validate.sh` script enforces Compose policy. These rules are part of the platform contract, not just syntax checking.

### No `version` Key

```bash
if find compose -type f -name '*.yml' -exec grep -H "^version:" {} +; then
  die "Deprecated Compose version keys are not allowed."
fi
```

The current Compose Specification does not require a `version` key. Including it is deprecated and rejected.

### No `container_name`

```bash
if find compose -type f -name '*.yml' -exec grep -H "container_name:" {} +; then
  die "Fixed container_name values are not allowed."
fi
```

Fixed container names cause conflicts, prevent horizontal scaling, and break Compose project namespacing. HES uses the project name for predictable, non-conflicting container names.

### No `latest` Tag

```bash
if find compose -type f -name '*.yml' -exec grep -H "image: .*:latest" {} +; then
  die "Floating latest image tags are not allowed."
fi
```

Floating `latest` tags make deployments non-reproducible and prevent rollback. Always pin to a specific version.

### CRLF Rejection

```bash
if grep -RIl $'\r' . --exclude-dir=.git; then
  die "CRLF line endings detected."
fi
```

CRLF line endings cause failures in Linux containers and scripts. Only LF is allowed.

### Compose Configuration Validation

```bash
compose config >/dev/null
```

Docker Compose validates the full merged configuration, including all included modules and variable substitution.

## Image Version Policy

### Pinned Versions Only

All image references in HES use explicit version tags:

| Service | Image | Version |
| --- | --- | --- |
| Traefik | `traefik` | `v3.3` |
| Docker Socket Proxy | `tecnativa/docker-socket-proxy` | `0.3.0` |

### Image Variables

Image versions are configurable through `.env`:

```bash
HES_TRAEFIK_IMAGE=traefik:v3.3
HES_SOCKET_PROXY_IMAGE=tecnativa/docker-socket-proxy:0.3.0
```

### Rules

- Never use floating `latest` tags.
- Always pin to a specific version tag.
- Update versions through `.env`, not by editing Compose files.
- After changing an image version, run `make update` to pull and recreate.

### Rationale

- Reproducible deployments.
- Predictable rollback (change the version back and run `make update`).
- No silent behavior changes from upstream `latest` updates.
- Clear audit trail of which version is running where.

## Compose Launcher Scripts

HES does not use separate `compose-up.sh`, `compose-down.sh`, or `compose-validate.sh` scripts. Instead, Compose operations are handled through the lifecycle scripts and Make targets.

### Make Targets for Compose Operations

| Target | Compose Operation |
| --- | --- |
| `make install` | `compose pull` and `compose up -d --remove-orphans` |
| `make update` | `compose pull`, `compose up -d --remove-orphans`, `compose ps` |
| `make logs` | `compose logs --tail=200 -f` |
| `make status` | `compose ps` |
| `make clean` | `compose down --remove-orphans` |
| `make uninstall` | `compose down --remove-orphans` (plus optional data removal) |
| `make validate` | `compose config >/dev/null` (plus script and policy checks) |
| `make doctor` | `compose config >/dev/null` and `compose ps` |

### Direct Compose Access

For debugging or advanced operations, run Compose directly using the same flags the helper uses:

```bash
# Render the full merged configuration
docker compose --project-directory . --env-file .env -f compose/compose.yml config

# View a specific service's resolved configuration
docker compose --project-directory . --env-file .env -f compose/compose.yml config <service>

# Start a single service
docker compose --project-directory . --env-file .env -f compose/compose.yml up -d traefik

# Pull images only
docker compose --project-directory . --env-file .env -f compose/compose.yml pull
```

Always use `--project-directory .` and `--env-file .env` to match the behavior of the `compose()` helper.
