<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0010-observability-future-module.md
Purpose: Architectural decision record for reserving observability as a future module.
-->

# ADR-0010: Reserve Observability as a Dedicated Future Module

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-07-09 |
| Supersedes | None |
| Superseded by | None |

## Context

Monitoring, metrics, and centralized logs are important, but the current phase is intentionally infrastructure-only and excludes Grafana, Prometheus, and Loki.

## Problem

Adding observability tooling too early would broaden scope and create platform noise before Hermes services exist. An observability stack with nothing meaningful to observe adds operational burden without proportional value.

## Alternatives

1. **Add observability stack in Phase 1.** Most capable, but violates the infrastructure-only scope and adds services to operate before the platform contract is stable.
2. **Delay observability entirely.** Simplest, but risks leaving a gap where operators have no visibility at all.
3. **Keep minimal local signals now and add a dedicated observability module later.** Provides enough visibility for Phase 1 while reserving a structured path for the full stack.

## Chosen Solution

Use minimal current signals such as Docker Compose status, container logs, script logs, and health checks, and plan a dedicated observability module for a later milestone.

## Reason

This keeps Phase 1 lean while still preserving useful operational visibility. Observability arrives as a structured milestone, not an ad hoc addon.

## Tradeoffs

- Current visibility is limited compared to a full monitoring platform.
- Future observability integration will still require substantial work.

## Consequences

- Operators have enough visibility for Phase 1 infrastructure.
- Observability remains a structured milestone, not an ad hoc addon.
- Later service growth will require a formal metrics and logging platform.
