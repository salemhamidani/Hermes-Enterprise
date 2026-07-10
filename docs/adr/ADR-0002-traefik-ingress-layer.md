<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0002-traefik-ingress-layer.md
Purpose: Architectural decision record for Traefik as the ingress layer.
-->

# ADR-0002: Use Traefik as the Ingress Layer

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-07-09 |
| Supersedes | None |
| Superseded by | None |

## Context

HES needs a reverse proxy and ingress controller that fits Docker Compose V2 and can scale with future service growth beyond 50 services.

## Problem

Future Hermes services need a consistent ingress contract for routing, TLS, and service discovery. Ad hoc host port publishing from each service would not scale cleanly and would scatter port policy across the stack.

## Alternatives

1. **Publish ports directly from each future service.** Maximally simple per service, but scatters TLS, redirect, and routing concerns across every service and breaks the shared ingress contract.
2. **Use Traefik for shared ingress.** Centralizes routing, TLS, redirect, and discovery behind one well-understood contract that integrates natively with Docker.
3. **Use another reverse proxy with more manual configuration.** Workable, but requires more boilerplate per service and loses native container discovery benefits.

## Chosen Solution

Use Traefik as the shared ingress layer for HTTP/HTTPS entrypoints and future service routing.

## Reason

Traefik works naturally with container discovery, reduces per-service routing boilerplate, and provides a clean ingress contract for future modules. It is the established choice for Docker-native, label-driven ingress.

## Tradeoffs

- Adds a control-plane dependency early in the platform lifecycle.
- Requires careful security treatment around Docker service discovery (see ADR-0003).
- Dashboard exposure must remain tightly controlled; in Phase 1 it is disabled.

## Consequences

- Future public Hermes services should route through Traefik rather than publishing host ports.
- Direct host port publishing should remain exceptional and documented.
- Traefik becomes a critical infrastructure dependency whose failure takes down ingress.
