<!--
Hermes Enterprise Stack (HES)
File: docs/adr/ADR-0011-hermes-provider-layer.md
Purpose: Explain why the Hermes provider layer exists.
-->

# ADR-0011: Why Hermes Provider Layer Exists

## Status

Accepted

## Context

Sprint 2.5 discovered an official Nous Hermes Agent provider, including repository, documentation, Docker image, and release tags. Treating that discovery as a permanent global assumption would couple HES to one provider and one container delivery model.

The project must support:

- Nous Hermes.
- Future Hermes-compatible providers.
- Operator-defined custom Hermes providers.

The project must also avoid implementing Hermes before the dedicated implementation sprint.

## Decision

HES will introduce a provider layer before implementing Hermes services.

The provider layer consists of:

- Provider manifests under `config/providers/`.
- Reserved provider Compose space under `compose/providers/`.
- Runtime selection helpers under `runtime/`.
- Provider documentation under `docs/providers/`.
- Environment variables `HERMES_PROVIDER`, `HERMES_REGISTRY`, `HERMES_IMAGE`, and `HERMES_VERSION`.

## Consequences

Positive consequences:

- HES no longer assumes Hermes is one fixed Docker image.
- Nous Hermes remains supported without becoming a hardcoded global dependency.
- Future and custom providers can be introduced without redesigning the stack.
- Provider decisions become auditable before implementation.

Tradeoffs:

- Future implementation must resolve provider metadata before generating Compose services.
- Documentation and validation are slightly more complex.
- Custom providers require stricter review because their trust boundary is operator-defined.

## Guardrails

- Sprint 3.0 must not create Hermes containers.
- Sprint 3.0 must not pull images.
- Sprint 3.0 must not implement Agent, Dashboard, or WebUI.
- Provider defaults must not justify using floating tags.
- Provider-specific Compose modules require a later implementation sprint and review.
