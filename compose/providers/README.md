<!--
Hermes Enterprise Stack (HES)
File: compose/providers/README.md
Purpose: Reserve provider-specific Compose extension space without defining services.
-->

# Provider Compose Space

This directory is reserved for future provider-specific Compose fragments.

Sprint 3.0 does not add Compose services, containers, image pulls, dashboards, WebUI, or Hermes Agent runtime definitions.

Rules for future files in this directory:

- Provider fragments must be selected through the provider layer.
- Provider fragments must not bypass `compose/compose.yml` and lifecycle scripts.
- Provider fragments must not use `container_name`.
- Provider fragments must not use floating `latest` tags.
- Provider fragments must not publish host ports directly for public endpoints.
- Provider fragments must document networks, volumes, secrets, health checks, labels, and rollback behavior.
