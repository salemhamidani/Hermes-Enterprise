<!--
Hermes Enterprise Stack (HES)
File: docs/providers/ProviderSpecification.md
Purpose: Provider layer specification for Hermes-compatible providers.
-->

# Provider Specification

## Purpose

The provider layer prevents HES from assuming that Hermes is one fixed Docker image. A provider is a verified runtime source and integration contract for a Hermes-compatible implementation.

## Required Environment Variables

| Variable | Purpose |
| --- | --- |
| `HERMES_PROVIDER` | Selects the provider manifest under `config/providers/`. |
| `HERMES_REGISTRY` | Optional registry override for container-image providers. |
| `HERMES_IMAGE` | Optional image override for container-image providers. |
| `HERMES_VERSION` | Optional version override for providers with versioned artifacts. |

Empty `HERMES_REGISTRY`, `HERMES_IMAGE`, and `HERMES_VERSION` values mean "use provider metadata". They do not mean "use latest".

## Provider Types

| Type | Meaning |
| --- | --- |
| `official` | Verified official provider with known upstream ownership. |
| `future` | Reserved provider slot pending future discovery. |
| `custom` | Operator-supplied provider requiring explicit review. |

## Runtime Modes

| Mode | Meaning |
| --- | --- |
| `container-image` | Provider can be deployed from a container image in a future sprint. |
| `external-endpoint` | Provider may be reached through an external API or service endpoint. |
| `custom-runtime` | Provider requires a custom integration plan before implementation. |

## Provider Rules

- Provider metadata is configuration, not implementation.
- Provider selection must happen before Compose service generation.
- Provider-specific Compose fragments belong under `compose/providers/` only after an implementation sprint approves them.
- Provider manifests must not introduce secrets.
- Provider manifests must not use floating `latest` or `main` versions.
- Provider implementations must preserve HES network, Traefik, security, logging, and validation standards.

## Required Provider Manifest Fields

| Field | Required | Description |
| --- | --- | --- |
| `provider_id` | Yes | Stable slug matching `HERMES_PROVIDER`. |
| `display_name` | Yes | Human-readable provider name. |
| `provider_type` | Yes | `official`, `future`, or `custom`. |
| `runtime_mode` | Yes | `container-image`, `external-endpoint`, or `custom-runtime`. |
| `default_registry` | No | Default registry, if applicable. |
| `default_image` | No | Default image, if applicable. |
| `default_version` | No | Default version, if applicable. |
| `documentation` | No | Provider documentation URL. |
| `repository` | No | Provider source repository URL. |

## Acceptance Criteria

A provider is ready for implementation only when:

- The provider manifest is complete.
- The provider has documented upgrade and rollback behavior.
- Security boundaries are reviewed.
- Required secrets are documented but not committed.
- Compose impact is documented without using host networking by default.
- The implementation plan does not create a hard dependency on one provider for all future Hermes work.
