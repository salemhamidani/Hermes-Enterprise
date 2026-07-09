# Hermes Enterprise Stack (HES)
# File: DECISIONS.md
# Purpose: Record the major architectural decisions for Hermes Enterprise Stack Phase 1.

# Architectural Decisions

This document records the important architectural decisions made for Hermes Enterprise Stack Phase 1. It is intended to serve as the decision register for future phases.

## Decision 1: Use Modular Docker Compose Files

### Context

HES is expected to grow beyond 50 Docker services over time. Phase 1 starts with infrastructure only, but the project must already look and behave like an enterprise open-source platform.

### Problem

A single Compose file becomes difficult to review, validate, extend, and own as the stack grows. It also encourages unrelated changes to accumulate in one place.

### Alternatives

- Use one monolithic `docker-compose.yml`.
- Use modular Compose files split by concern.
- Adopt a heavier orchestrator immediately.

### Chosen Solution

Use modular Compose files in `compose/`, with `compose/compose.yml` orchestrating included modules such as `network.yml`, `security.yml`, and `traefik.yml`.

### Reason

This gives Phase 1 a maintainable structure now without prematurely introducing cluster orchestration complexity.

### Tradeoffs

- More files to navigate.
- Requires stronger naming and validation rules.
- Cross-module relationships must be documented carefully.

### Consequences

- Future Hermes services can be added as dedicated Compose modules.
- Reviews stay smaller and more ownership-friendly.
- Validation policy must guard against module drift.

## Decision 2: Use Traefik as the Ingress Layer

### Context

HES needs a reverse proxy and ingress controller that fits Docker Compose V2 and can scale with future service growth.

### Problem

Future Hermes services need a consistent ingress contract for routing, TLS, and service discovery. Ad hoc host port publishing would not scale cleanly.

### Alternatives

- Publish ports directly from each future service.
- Use Traefik for shared ingress.
- Use another reverse proxy with more manual configuration.

### Chosen Solution

Use Traefik as the shared ingress layer for HTTP/HTTPS entrypoints and future service routing.

### Reason

Traefik works naturally with container discovery, reduces per-service routing boilerplate, and provides a clean ingress contract for future modules.

### Tradeoffs

- Adds a control-plane dependency early.
- Requires careful security treatment around Docker service discovery.
- Dashboard exposure must remain tightly controlled.

### Consequences

- Future public Hermes services should route through Traefik.
- Direct host port publishing should remain exceptional.
- Traefik becomes a critical infrastructure dependency.

## Decision 3: Do Not Mount Docker Socket Directly into Traefik

### Context

Traefik needs Docker metadata for service discovery, but direct Docker socket access is a major security risk.

### Problem

Mounting `/var/run/docker.sock` into Traefik would expose a broad and sensitive host control surface to the ingress layer.

### Alternatives

- Mount Docker socket directly into Traefik.
- Use a Docker socket proxy with reduced permissions.
- Avoid Docker-based discovery and configure routes manually.

### Chosen Solution

Use `tecnativa/docker-socket-proxy` and point Traefik to the proxy endpoint instead of the raw Docker socket.

### Reason

This preserves Docker-based discovery while reducing the exposed Docker API surface.

### Tradeoffs

- Adds another infrastructure component.
- Requires maintenance of proxy permission settings.
- Some advanced provider features may require revisiting proxy scope later.

### Consequences

- Traefik never touches the raw Docker socket directly.
- Security review focuses on a smaller API surface.
- Future changes to discovery behavior must consider proxy permissions.

## Decision 4: Keep Phase 1 Infrastructure-Only

### Context

The project needs a solid base before business services, observability stacks, or data-plane components are added.

### Problem

Mixing Hermes services, monitoring, and stateful services into Phase 1 would blur infrastructure decisions and increase the number of moving parts before the platform contract is stable.

### Alternatives

- Build infrastructure and application services together.
- Build infrastructure first, then layer services later.
- Start with a local-only developer stack and evolve afterward.

### Chosen Solution

Keep Phase 1 strictly limited to infrastructure: Compose modules, ingress, security boundary, scripts, backup/restore, and documentation.

### Reason

This reduces ambiguity, makes the platform easier to audit, and creates a cleaner extension path.

### Tradeoffs

- No immediate business workload is deployable in Phase 1.
- Some future assumptions are documented rather than exercised by live services.

### Consequences

- Hermes services, databases, and observability arrive in later milestones.
- Phase 1 documentation can focus on platform behavior.
- The infrastructure contract becomes the foundation for later phases.

## Decision 5: Parse `.env` as Data, Not Shell

### Context

HES requires all runtime configuration to be controlled through `.env`.

### Problem

Sourcing `.env` as Bash would allow malformed or malicious values to execute code.

### Alternatives

- Source `.env` directly with `source`.
- Parse `.env` manually as data.
- Move immediately to an external secret/config system.

### Chosen Solution

Parse `.env` as data in shared script logic and allow only simple `HES_*` assignments.

### Reason

This keeps configuration portable and safe while preserving the simplicity of `.env` for Phase 1.

### Tradeoffs

- `.env` syntax is more restrictive than full shell syntax.
- Complex value handling must remain simple and explicit.

### Consequences

- Operators must use `HES_KEY=value` entries only.
- Future secret-management integration can evolve from a safer baseline.
- Validation can reason about configuration format consistently.

## Decision 6: Use Managed Runtime Directories

### Context

Phase 1 scripts create, clean, back up, and restore local runtime paths such as `logs/`, `backup/`, `ssl/`, `storage/`, and `data/`.

### Problem

Destructive operations become risky if scripts cannot distinguish managed paths from arbitrary operator-owned directories.

### Alternatives

- Trust configured paths and delete directly.
- Mark managed directories and refuse cleanup without markers.
- Avoid automated cleanup entirely.

### Chosen Solution

Mark script-managed runtime directories with `.hes-managed` and refuse destructive cleanup for unmanaged directories.

### Reason

This provides a simple, auditable safeguard for idempotent automation.

### Tradeoffs

- Adds an extra marker file to managed directories.
- Restore and repair logic must preserve the managed state model.

### Consequences

- Cleanup becomes safer and easier to reason about.
- Runtime directory ownership is explicit.
- Backup and restore workflows must remain marker-aware.

## Decision 7: Validate Environment and Compose Policy Early

### Context

The project is intended to scale to dozens of services, where small policy drift compounds quickly.

### Problem

Without policy checks, future service additions can introduce bad patterns such as `container_name`, floating `latest` tags, invalid ports, or production placeholder values.

### Alternatives

- Rely on human review alone.
- Add lightweight repository-specific validation.
- Introduce a full policy engine immediately.

### Chosen Solution

Use `scripts/validate.sh` plus shared helpers to enforce environment validation and key Compose policies early.

### Reason

This is enough structure to prevent common drift without adding heavyweight tooling in Phase 1.

### Tradeoffs

- Validation rules must be maintained as the platform evolves.
- Some advanced future use cases may require exceptions or refined checks.

### Consequences

- Future contributors get fast feedback.
- The project can scale with fewer style and policy regressions.
- Validation becomes part of the platform contract, not just syntax checking.

## Decision 8: Treat Backup and Restore as First-Class Infrastructure Features

### Context

Even in an infrastructure-only phase, HES manages important mutable state such as `.env`, certificates, configuration, and future persistent directories.

### Problem

If backup and restore are deferred, later stateful phases inherit weak recovery habits and undocumented assumptions.

### Alternatives

- Postpone backup and restore until databases exist.
- Provide basic archive scripts without validation.
- Build validated backup and restore workflows in Phase 1.

### Chosen Solution

Implement backup and restore now, with staged extraction, archive path validation, and runtime path awareness.

### Reason

Recovery discipline is easier to establish early than retrofit after critical data exists.

### Tradeoffs

- Adds script complexity before application services exist.
- Requires documentation even for infrastructure-only state.

### Consequences

- Disaster recovery planning starts with a real mechanism, not a placeholder.
- Future data-plane services will extend an existing recovery model.
- Operators can rehearse recovery workflows earlier.

## Decision 9: Use a Strong Single-Node Foundation Before High Availability

### Context

The project aims for production quality, but full HA and cluster orchestration introduce significant operational complexity.

### Problem

Attempting multi-node HA too early would dilute focus and create fragile complexity before service contracts and operational baselines are stable.

### Alternatives

- Build for multi-node HA immediately.
- Start with a well-hardened single-node architecture and evolve later.
- Stay developer-only and defer production concerns.

### Chosen Solution

Use a production-oriented single-node foundation in Phase 1, then add HA in later milestones when operational evidence justifies it.

### Reason

This balances realism, maintainability, and delivery pace.

### Tradeoffs

- Single-host failure remains a current limitation.
- HA characteristics are planned rather than delivered in Phase 1.

### Consequences

- Phase 1 is operationally serious but not fully highly available.
- Later milestones must explicitly address ingress redundancy, shared state, and failover.
- Documentation must be honest about current HA limits.

## Decision 10: Reserve Observability as a Dedicated Future Module

### Context

Monitoring, metrics, and centralized logs are important, but the current phase is intentionally infrastructure-only and excludes Grafana, Prometheus, and Loki.

### Problem

Adding observability tooling too early would broaden scope and create platform noise before Hermes services exist.

### Alternatives

- Add observability stack in Phase 1.
- Delay observability entirely.
- Keep minimal local signals now and add a dedicated observability module later.

### Chosen Solution

Use minimal current signals such as Docker Compose status, container logs, script logs, and health checks, and plan a dedicated observability module for a later milestone.

### Reason

This keeps Phase 1 lean while still preserving useful operational visibility.

### Tradeoffs

- Current visibility is limited compared to a full monitoring platform.
- Future observability integration will still require substantial work.

### Consequences

- Operators have enough visibility for Phase 1 infrastructure.
- Observability remains a structured milestone, not an ad hoc addon.
- Later service growth will require a formal metrics and logging platform.
