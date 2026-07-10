<!--
Hermes Enterprise Stack (HES)
File: docs/providers/FutureHermes.md
Purpose: Provider notes for future Hermes-compatible providers.
-->

# Future Hermes Provider

## Status

`future-hermes` is a reserved provider slot. It exists so the architecture can support another verified Hermes-compatible provider later without redesign.

## Requirements Before Use

A future provider must provide:

- Official or approved repository.
- Official or approved documentation.
- Runtime mode.
- Versioning policy.
- Security model.
- Secrets model.
- Network model.
- Upgrade policy.
- Rollback policy.

## HES Rules

- Do not use `future-hermes` in production.
- Do not assign images or endpoints without a discovery sprint.
- Do not implement Compose services until provider metadata is verified.
