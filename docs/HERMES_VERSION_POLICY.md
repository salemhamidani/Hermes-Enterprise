<!--
Hermes Enterprise Stack (HES)
File: docs/HERMES_VERSION_POLICY.md
Purpose: Version pinning policy for future Hermes Agent implementation.
-->

# Hermes Version Policy

## Scope

This policy defines how HES will select Hermes provider versions in a future implementation sprint. It does not add services, containers, routes, or Compose modules.

## Provider-Selected Upstream

| Field | Value |
| --- | --- |
| Provider selection | `HERMES_PROVIDER` |
| Provider registry override | `HERMES_REGISTRY` |
| Provider image override | `HERMES_IMAGE` |
| Provider version override | `HERMES_VERSION` |
| Provider metadata | `config/providers/*.yml` |

## Tag Classes

| Tag class | Meaning | HES policy |
| --- | --- | --- |
| `latest` | Moving Docker Hub tag | Never use in HES Compose files |
| `main` | Moving main-branch image | Never use in production |
| `vYYYY.M.D` | Upstream release tag | Allowed after review |
| `vYYYY.M.D.N` | Same-day patch release tag | Allowed after review |
| Digest | Immutable OCI image index or platform digest | Preferred for production |

## Current Discovery Result

As of 2026-07-11, the latest verified stable upstream release for the `nous-hermes` reference provider is:

| Field | Value |
| --- | --- |
| Release name | Hermes Agent v0.18.2 (2026.7.7.2) |
| Git tag | `v2026.7.7.2` |
| PyPI version | `0.18.2` |
| Docker tag | `nousresearch/hermes-agent:v2026.7.7.2` |
| Multi-arch digest | `sha256:9c841866021c54c4596849f6135717e8a4d52ba510b7f52c50aef1de1a283973` |

## Version Decision

| Decision | Value |
| --- | --- |
| `latest` | Forbidden |
| Stable | Provider-specific verified release tag |
| Pinned version | Provider-specific, resolved from manifest or override |
| Recommended production version | Provider-specific version selected through `HERMES_VERSION` |
| Recommended production pin | Provider-specific tag plus digest after implementation validation |
| LTS version | Not available; no official LTS was verified |

## Pinning Requirements

Future HES implementation must:

- Select the provider through `HERMES_PROVIDER`.
- Resolve registry, image, and version through provider metadata plus optional `HERMES_REGISTRY`, `HERMES_IMAGE`, and `HERMES_VERSION` overrides.
- Never use `latest` in Compose files.
- Never use unverified third-party Hermes providers.
- Avoid hardcoding one provider image as the global architecture.

## Upgrade Policy

A Hermes provider upgrade is allowed only when all conditions are met:

1. The target version exists as an upstream GitHub release.
2. The Docker Hub tag exists and matches the release tag.
3. Release notes have been reviewed for breaking changes.
4. Provider runtime behavior has been compared against the currently pinned provider metadata.
5. Security advisories have been reviewed.
6. The change is implemented in a dedicated feature branch.
7. CI passes Compose, Shell, YAML, Markdown, Docker lint, and security checks.
8. A rollback tag remains documented and available.

## Rollback Policy

Rollback must be possible without changing architecture.

Required rollback steps for a future implementation:

1. Stop Hermes services through HES lifecycle scripts.
2. Revert provider metadata or provider override variables to the previous approved values.
3. Preserve the Hermes data volume unless the release notes require a documented migration rollback.
4. Restart only the Hermes service group.
5. Verify health checks, dashboard availability, gateway behavior, logs, and Traefik routing.
6. Record the rollback in the sprint report and changelog.

## Review Checklist

Before changing the pinned Hermes version, reviewers must verify:

- No floating image tags are introduced.
- No upstream host networking is copied into HES.
- No `container_name` is introduced.
- No unauthenticated dashboard route is exposed.
- Secrets remain in `.env`, Docker secrets, or approved secret storage.
- HES networks and Traefik middleware are preserved.
