<!--
Hermes Enterprise Stack (HES)
File: ProviderArchitecture.md
Purpose: Architecture guide for the Hermes provider layer.
-->

# Provider Architecture

## Intent

The provider layer decouples HES from a fixed Hermes runtime. HES prepares for multiple Hermes-compatible providers while preserving infrastructure standards.

## Layer Model

```text
Operator .env
  ↓
HERMES_PROVIDER
  ↓
config/providers/<provider>.yml
  ↓
runtime/provider-loader.sh
  ↓
Future implementation sprint
  ↓
Provider-specific Compose/runtime integration
```

## Directory Responsibilities

| Directory | Responsibility |
| --- | --- |
| `config/providers/` | Provider manifests and provider interface contract. |
| `compose/providers/` | Reserved future location for provider-specific Compose fragments. |
| `runtime/` | Runtime selection and validation helpers. |
| `docs/providers/` | Provider specification and provider-specific documentation. |

## Boundaries

Sprint 3.0 stops at provider selection. It does not:

- Create Hermes containers.
- Pull Hermes images.
- Implement Hermes Agent.
- Implement Dashboard.
- Implement WebUI.
- Add Traefik routes for Hermes.

## Future Integration Flow

1. Select provider with `HERMES_PROVIDER`.
2. Resolve provider metadata through `runtime/provider-loader.sh`.
3. Validate that provider versioning avoids floating tags.
4. Generate or select provider-specific Compose only in an implementation sprint.
5. Apply HES network, secrets, logs, labels, health checks, and Traefik rules.
6. Review and merge through Git Flow.

## Design Constraint

No future sprint may hardcode Hermes as a single Docker image. Provider defaults may exist, but implementation must flow through provider selection.
