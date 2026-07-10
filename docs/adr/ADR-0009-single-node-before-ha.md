<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0009-single-node-before-ha.md
Purpose: Architectural decision record for a single-node foundation before high availability.
-->

# ADR-0009: Use a Strong Single-Node Foundation Before High Availability

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-07-09 |
| Supersedes | None |
| Superseded by | None |

## Context

The project aims for production quality, but full high availability (HA) and cluster orchestration introduce significant operational complexity that is not yet justified.

## Problem

Attempting multi-node HA too early would dilute focus and create fragile complexity before service contracts and operational baselines are stable. HA built on an unproven single-node foundation tends to be brittle.

## Alternatives

1. **Build for multi-node HA immediately.** Ambitious, but adds cluster orchestration and shared-state complexity before the platform contract is proven.
2. **Start with a well-hardened single-node architecture and evolve later.** Establishes production-quality operations on one node, then adds HA when evidence justifies it.
3. **Stay developer-only and defer production concerns.** Lowest effort, but never produces a production-oriented baseline.

## Chosen Solution

Use a production-oriented single-node foundation in Phase 1, then add HA in later milestones when operational evidence justifies it.

## Reason

This balances realism, maintainability, and delivery pace. A hardened single node is operationally serious without the fragility of premature clustering.

## Tradeoffs

- Single-host failure remains a current limitation.
- HA characteristics are planned rather than delivered in Phase 1.

## Consequences

- Phase 1 is operationally serious but not fully highly available.
- Later milestones must explicitly address ingress redundancy, shared state, and failover.
- Documentation must be honest about current HA limits.
