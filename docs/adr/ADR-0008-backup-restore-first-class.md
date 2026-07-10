<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0008-backup-restore-first-class.md
Purpose: Architectural decision record for backup and restore as first-class infrastructure features.
-->

# ADR-0008: Treat Backup and Restore as First-Class Infrastructure Features

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-07-09 |
| Supersedes | None |
| Superseded by | None |

## Context

Even in an infrastructure-only phase, HES manages important mutable state such as `.env`, certificates, configuration, and future persistent directories.

## Problem

If backup and restore are deferred, later stateful phases inherit weak recovery habits and undocumented assumptions. Retrofitting recovery after critical data exists is far harder and riskier than building it early.

## Alternatives

1. **Postpone backup and restore until databases exist.** Defers effort, but ships later phases with no proven recovery model.
2. **Provide basic archive scripts without validation.** Lightweight, but produces untrusted archives and unsafe restore paths.
3. **Build validated backup and restore workflows in Phase 1.** Establishes recovery discipline while the state surface is still small and understandable.

## Chosen Solution

Implement backup and restore now, with staged extraction, archive path validation, and runtime path awareness. Archives are restricted to owner-only permissions (`chmod 600`).

## Reason

Recovery discipline is easier to establish early than retrofit after critical data exists. Operators can rehearse recovery workflows before they are under pressure.

## Tradeoffs

- Adds script complexity before application services exist.
- Requires documentation even for infrastructure-only state.

## Consequences

- Disaster recovery planning starts with a real mechanism, not a placeholder.
- Future data-plane services will extend an existing recovery model rather than invent one.
- Operators can rehearse recovery workflows earlier in the project lifecycle.
