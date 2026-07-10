<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0007-early-validation.md
Purpose: Architectural decision record for early environment and Compose policy validation.
-->

# ADR-0007: Validate Environment and Compose Policy Early

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-07-09 |
| Supersedes | None |
| Superseded by | None |

## Context

The project is intended to scale to dozens of services, where small policy drift compounds quickly. What is a minor style slip at two services becomes an unmanageable inconsistency at fifty.

## Problem

Without policy checks, future service additions can introduce bad patterns such as `container_name`, floating `latest` tags, invalid ports, or production placeholder values. These drift silently until they cause outages.

## Alternatives

1. **Rely on human review alone.** Flexible, but does not scale; reviewers miss repetitive policy violations as the stack grows.
2. **Add lightweight repository-specific validation.** Catches the most common drift patterns with a single command before they merge.
3. **Introduce a full policy engine (OPA, Conftest, etc.) immediately.** Most thorough, but adds heavyweight tooling before the policy set is stable enough to justify it.

## Chosen Solution

Use `scripts/validate.sh` plus shared helpers to enforce environment validation and key Compose policies early in every workflow.

## Reason

This is enough structure to prevent common drift without adding heavyweight tooling in Phase 1. Validation becomes part of the platform contract rather than an afterthought.

## Tradeoffs

- Validation rules must be maintained as the platform evolves.
- Some advanced future use cases may require exceptions or refined checks that the current rules do not anticipate.

## Consequences

- Future contributors get fast feedback before review.
- The project can scale with fewer style and policy regressions.
- Validation becomes part of the platform contract, not just syntax checking.
