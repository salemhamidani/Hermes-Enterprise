<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0004-phase1-infrastructure-only.md
Purpose: Architectural decision record for keeping Phase 1 infrastructure-only.
-->

# ADR-0004: Keep Phase 1 Infrastructure-Only

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-07-09 |
| Supersedes | None |
| Superseded by | None |

## Context

The project needs a solid base before business services, observability stacks, or data-plane components are added. Phase 1 establishes the platform contract that all later services must follow.

## Problem

Mixing Hermes application services, monitoring, and stateful services into Phase 1 would blur infrastructure decisions and increase the number of moving parts before the platform contract is stable. It would also make Phase 1 harder to audit and review.

## Alternatives

1. **Build infrastructure and application services together.** Delivers a working product faster, but entangles platform and application concerns before the contract is proven.
2. **Build infrastructure first, then layer services later.** Establishes a clean, auditable platform contract before any business service depends on it.
3. **Start with a local-only developer stack and evolve afterward.** Lower initial effort, but risks shipping platform assumptions that were never exercised under production intent.

## Chosen Solution

Keep Phase 1 strictly limited to infrastructure: Compose modules, ingress, security boundary, scripts, backup/restore, and documentation. No application, data-plane, or observability services ship in Phase 1.

## Reason

This reduces ambiguity, makes the platform easier to audit, and creates a cleaner extension path. Future services attach to a stable contract instead of being built alongside an unstable one.

## Tradeoffs

- No immediate business workload is deployable in Phase 1.
- Some future assumptions are documented rather than exercised by live services.

## Consequences

- Hermes services, databases, and observability arrive in later milestones.
- Phase 1 documentation can focus on the platform contract rather than application behavior.
- The extension path is explicit and reviewed rather than ad hoc.
