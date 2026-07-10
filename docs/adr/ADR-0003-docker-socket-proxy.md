<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0003-docker-socket-proxy.md
Purpose: Architectural decision record for the Docker socket proxy security boundary.
-->

# ADR-0003: Do Not Mount Docker Socket Directly into Traefik

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-07-09 |
| Supersedes | None |
| Superseded by | None |

## Context

Traefik needs Docker metadata for service discovery, but direct Docker socket access is a major security risk: the Docker socket grants near-root control over the host.

## Problem

Mounting `/var/run/docker.sock` directly into Traefik would expose a broad and sensitive host control surface to the ingress layer. A compromised or misconfigured Traefik could then create containers, read secrets, or take over the host.

## Alternatives

1. **Mount Docker socket directly into Traefik.** Simplest for discovery, but grants the ingress layer full Docker API access with no reduction.
2. **Use a Docker socket proxy with reduced permissions.** Preserves Docker-based discovery while exposing only the read-only metadata endpoints Traefik needs.
3. **Avoid Docker-based discovery and configure routes manually.** Removes the socket risk entirely, but loses the dynamic discovery that makes Traefik valuable and increases per-service boilerplate.

## Chosen Solution

Use `tecnativa/docker-socket-proxy` and point Traefik to the proxy endpoint instead of the raw Docker socket. The proxy exposes only the read-only Docker API endpoints required for discovery.

## Reason

This preserves Docker-based discovery while reducing the exposed Docker API surface to the minimum Traefik requires. It follows the deny-by-default, allow-by-exception security posture of the platform.

## Tradeoffs

- Adds another infrastructure component that must be operated and versioned.
- Requires maintenance of proxy permission settings as the platform evolves.
- Some advanced provider features may require revisiting proxy scope in later phases.

## Consequences

- Traefik never touches the raw Docker socket directly.
- Security review focuses on a smaller, well-defined API surface.
- Future changes to discovery behavior must consider proxy permissions before widening access.
