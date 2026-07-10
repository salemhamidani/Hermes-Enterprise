<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0006-managed-directory-markers.md
Purpose: Architectural decision record for managed runtime directory markers.
-->

# ADR-0006: Use Managed Runtime Directories

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-07-09 |
| Supersedes | None |
| Superseded by | None |

## Context

Phase 1 scripts create, clean, back up, and restore local runtime paths such as `logs/`, `backup/`, `ssl/`, `storage/`, and `data/`.

## Problem

Destructive operations become risky if scripts cannot distinguish managed paths from arbitrary operator-owned directories. A cleanup routine could delete a path the operator intended to keep if ownership is implicit.

## Alternatives

1. **Trust configured paths and delete directly.** Simplest, but offers no safeguard against misconfiguration deleting operator-owned data.
2. **Mark managed directories and refuse cleanup without markers.** Makes runtime directory ownership explicit and gives scripts an auditable guard.
3. **Avoid automated cleanup entirely.** Eliminates the risk, but breaks idempotent restore and repair workflows.

## Chosen Solution

Mark script-managed runtime directories with a `.hes-managed` marker file and refuse destructive cleanup for unmarked (unmanaged) directories.

## Reason

This provides a simple, auditable safeguard for idempotent automation. Scripts can confidently manage directories they own and refuse to touch directories they do not.

## Tradeoffs

- Adds an extra marker file (`.hes-managed`) to each managed directory.
- Restore and repair logic must preserve the managed state model across operations.

## Consequences

- Cleanup becomes safer and easier to reason about.
- Runtime directory ownership is explicit rather than implied.
- Backup and restore workflows must remain marker-aware so managed state survives recovery.
