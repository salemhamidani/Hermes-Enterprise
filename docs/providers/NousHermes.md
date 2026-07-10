<!--
Hermes Enterprise Stack (HES)
File: docs/providers/NousHermes.md
Purpose: Provider notes for the official Nous Hermes provider.
-->

# Nous Hermes Provider

## Status

`nous-hermes` is a supported reference provider. It is not implemented by Sprint 3.0.

## Source

| Field | Value |
| --- | --- |
| Provider ID | `nous-hermes` |
| Provider type | `official` |
| Runtime mode | `container-image` |
| Repository | `https://github.com/NousResearch/hermes-agent` |
| Documentation | `https://hermes-agent.nousresearch.com/docs` |
| Default registry | `docker.io` |
| Default image | `nousresearch/hermes-agent` |
| Default version | `v2026.7.7.2` |

## HES Rules

- The provider layer selects Nous Hermes; the project must not assume it globally.
- The default image and version are metadata, not an implementation.
- Future deployment must adapt upstream behavior to HES Compose standards.
- Upstream host-network examples must not be copied into HES without an ADR.
- Dashboard and WebUI exposure remain out of scope until explicitly implemented.
