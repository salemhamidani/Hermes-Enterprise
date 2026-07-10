<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0005-environment-driven-configuration.md
Purpose: Architectural decision record for environment-driven configuration and safe .env parsing.
-->

# ADR-0005: Parse .env as Data, Not Shell

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-07-09 |
| Supersedes | None |
| Superseded by | None |

## Context

HES requires all runtime configuration to be controlled through `.env`. Every runtime value lives in `.env` so that secrets are never hardcoded and environments are portable.

## Problem

Sourcing `.env` as Bash (e.g. with `source .env`) would allow malformed or malicious values to execute code. A typo or an injected line could run arbitrary commands during script startup.

## Alternatives

1. **Source `.env` directly with `source`.** Maximally flexible, but turns configuration into executable shell code and creates a code-injection vector.
2. **Parse `.env` manually as data.** Restricts syntax to safe `KEY=value` assignments and treats configuration as inert data.
3. **Move immediately to an external secret/config system (Vault, SOPS, etc.).** Strongest isolation, but introduces heavyweight tooling before the platform needs it.

## Chosen Solution

Parse `.env` as data in shared script logic and allow only simple `HES_*` assignments. The parser reads key-value pairs without evaluating them as shell.

## Reason

This keeps configuration portable and safe while preserving the simplicity of `.env` for Phase 1. It follows the principle of treating configuration as data, not code.

## Tradeoffs

- `.env` syntax is more restrictive than full shell syntax.
- Complex value handling must remain simple and explicit; no shell expansion is available.

## Consequences

- Operators must use `HES_KEY=value` entries only.
- Future secret-management integration can evolve from a safer baseline.
- Validation can reason about configuration format consistently across all scripts.
