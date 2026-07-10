<!--
Hermes Enterprise Stack (HES)
File: docs/providers/CustomHermes.md
Purpose: Provider notes for operator-defined Hermes-compatible providers.
-->

# Custom Hermes Provider

## Status

`custom-hermes` is an operator-defined provider class. It is not trusted by default and is not implemented by Sprint 3.0.

## Required Operator Inputs

Custom providers must supply:

- `HERMES_REGISTRY`
- `HERMES_IMAGE`
- `HERMES_VERSION`
- Security review notes
- Deployment documentation
- Rollback documentation

## HES Rules

- Custom providers must never use `latest` or `main` as a production version.
- Custom providers must not bypass HES networks or Traefik security policy.
- Custom providers must not mount the Docker socket directly unless a future ADR approves it.
- Custom providers must be reviewed before any Compose module references them.
