<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0001-modular-compose-files.md
Purpose: Architectural decision record for modular Docker Compose files.
-->

# ADR-0001: Use Modular Docker Compose Files

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-07-09 |
| Supersedes | None |
| Superseded by | None |

## Context

HES is expected to grow beyond 50 Docker services over time. Phase 1 starts with infrastructure only, but the project must already look and behave like an enterprise open-source platform from the first commit.

## Problem

A single Compose file becomes difficult to review, validate, extend, and own as the stack grows. It also encourages unrelated changes to accumulate in one place, which erodes the clean architecture boundaries and makes ownership ambiguous.

## Alternatives

1. **Use one monolithic `docker-compose.yml`.** Simplest to start, but does not scale to 50+ services without becoming an unreviewable wall of YAML.
2. **Use modular Compose files split by concern.** Each concern (network, security, ingress, service family) owns its own file, orchestrated through a single include entry point.
3. **Adopt a heavier orchestrator immediately (Swarm or Kubernetes).** Provides native module separation, but introduces cluster complexity far too early for Phase 1.

## Chosen Solution

Use modular Compose files in `compose/`, with `compose/compose.yml` orchestrating included modules such as `network.yml`, `security.yml`, and `traefik.yml`.

## Reason

This gives Phase 1 a maintainable structure now without prematurely introducing cluster orchestration complexity. Modular files keep reviews small, ownership clear, and extension predictable as future Hermes service families are added.

## Tradeoffs

- More files to navigate; the include entry point must be the obvious starting place.
- Requires stronger naming and validation rules to prevent module drift.
- Cross-module relationships must be documented carefully so contributors understand the dependency graph.

## Consequences

- Future Hermes services can be added as dedicated Compose modules (e.g. `compose/hermes-api.yml`).
- Reviews stay smaller and more ownership-friendly.
- Validation policy (`make validate`) must guard against module drift over time.
