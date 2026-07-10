<!--
Hermes Enterprise Stack (HES)
File: docs/adr/README.md
Purpose: Index architecture decision records for HES.
-->

# Architecture Decision Records

This directory contains the accepted ADRs for Hermes Enterprise Stack. `DECISIONS.md` remains the root decision register, while ADR files provide durable records for individual decisions.

| ADR | Title | Status |
| --- | --- | --- |
| [ADR-0001](ADR-0001.md) | Use Modular Docker Compose Files | Accepted |
| [ADR-0002](ADR-0002.md) | Use Traefik as the Ingress Layer | Accepted |
| [ADR-0003](ADR-0003.md) | Do Not Mount Docker Socket Directly into Traefik | Accepted |
| [ADR-0004](ADR-0004-phase1-infrastructure-only.md) | Keep Phase 1 Infrastructure-Only | Accepted |
| [ADR-0005](ADR-0005-environment-driven-configuration.md) | Parse Environment Configuration as Data | Accepted |
| [ADR-0006](ADR-0006-managed-directory-markers.md) | Use Managed Directory Markers | Accepted |
| [ADR-0007](ADR-0007-early-validation.md) | Validate Early Before Runtime Operations | Accepted |
| [ADR-0008](ADR-0008-backup-restore-first-class.md) | Make Backup and Restore First-Class | Accepted |
| [ADR-0009](ADR-0009-single-node-before-ha.md) | Start with Single-Node Operations | Accepted |
| [ADR-0010](ADR-0010-observability-future-module.md) | Reserve Observability for Future Modules | Accepted |

## Compatibility Aliases

`ADR-0001.md`, `ADR-0002.md`, and `ADR-0003.md` are canonical short aliases for the first three ADRs requested during Sprint 1.1. Their long-form originals are retained for backward compatibility with existing links.
