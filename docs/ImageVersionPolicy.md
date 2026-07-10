# Hermes Enterprise Stack (HES)

# File: docs/ImageVersionPolicy.md
# Purpose: Define the container image versioning, pinning, and upgrade policy.

## Overview

HES pins every container image to an explicit, immutable-by-convention tag and
never uses floating `latest` tags. Images are referenced through `HES_*`
environment variables so that version bumps and digest pinning require no edits
to Compose files. This document explains why pinned tags are used, when to
prefer digests over tags, how to pin a digest, the currently pinned images, and
the upgrade policy.

## Why pinned tags instead of `latest`

- **Reproducibility:** A pinned tag guarantees that the same Compose file
  produces the same container behavior across hosts and over time. Floating
  `latest` tags resolve to different digests on every pull, making deployments
  non-deterministic.
- **Auditability:** Pinned tags make it trivial to answer "exactly which
  version is running in production?" without inspecting remote registries.
- **Safe rollback:** If an upgrade misbehaves, reverting the tag in `.env` and
  re-deploying restores the prior, known-good version.
- **Supply-chain hygiene:** Floating tags can be silently re-pushed with
  different content. Fixed tags reduce that risk surface and make drift
  detectable.
- **CI stability:** Validation and integration tests run against the same
  images operators deploy, avoiding "works in CI, breaks in prod" drift.

This is enforced project-wide: `scripts/validate.sh` rejects any Compose file
containing `image: ...:latest`.

## When to use digests vs tags

HES supports two levels of pinning. Both are configured through the same
`HES_*_IMAGE` environment variables, so no Compose file edits are required.

| Strategy | Format | When to use |
| --- | --- | --- |
| **Tag pinning** (default) | `image:tag` | Day-to-day operations, development, staging, and most production deployments. Easy to read, easy to upgrade. |
| **Digest pinning** | `image:tag@sha256:<digest>` | Regulated or locked-down production, change freezes, or any case where an image must never move even if the tag is re-pushed. Maximum immutability. |

**Recommendation:** pin by tag in `.env` for normal operations. Promote to
digest pinning in production when the environment requires cryptographic
immutability, and re-resolve the digest during each upgrade cycle.

## How to pin a digest

Compose accepts the `image:tag@sha256:<digest>` reference directly in the
`HES_*_IMAGE` variables. Because every service image is parameterized, digest
pinning is a pure configuration change in `.env`:

1. **Resolve the digest** for the tag you intend to pin:

   ```bash
   docker buildx imagetools inspect traefik:v3.3
   # or, after a local pull:
   docker inspect --format '{{index .RepoDigests 0}}' traefik:v3.3
   ```

   The output looks like `traefik@sha256:abcd1234...`.

2. **Set the variable in `.env`** using `tag@sha256:<digest>` form:

   ```bash
   HES_TRAEFIK_IMAGE=traefik:v3.3@sha256:<digest>
   ```

3. **Validate and apply:**

   ```bash
   scripts/compose-validate.sh
   scripts/compose-up.sh
   ```

   `compose-up.sh` runs `docker compose pull`, which will verify and fetch the
   exact digest. Keep the tag portion alongside the digest so the running
   version remains human-readable.

## Currently pinned images

| Service | Image | Tag | Variable | Compose file |
| --- | --- | --- | --- | --- |
| `docker-socket-proxy` | `tecnativa/docker-socket-proxy` | `0.3.0` | `HES_SOCKET_PROXY_IMAGE` | `compose/security.yml` |
| `traefik` | `traefik` | `v3.3` | `HES_TRAEFIK_IMAGE` | `compose/traefik.yml` |

Defaults are declared inline in each Compose file (e.g.
`${HES_TRAEFIK_IMAGE:-traefik:v3.3}`) and mirrored in `.env.example`. The
`.env` file is the source of truth for a deployed environment.

## Upgrade policy

- **One image at a time.** Bump a single image per change so regressions can be
  attributed unambiguously.
- **Test before production.** Validate and run the stack with
  `HES_ENVIRONMENT=development` first, then promote to production.
- **Review upstream changes.** Check the image's release notes and security
  advisories before upgrading.
- **Update both env files.** Bump the tag in `.env` and `.env.example` so the
  example stays authoritative. Keep them in sync.
- **Validate, then apply.** Run `scripts/compose-validate.sh`, then
  `scripts/compose-up.sh` (which pulls and restarts affected services).
- **Re-resolve digests.** When digest pinning is in use, re-resolve the digest
  for the new tag and update `.env` accordingly.
- **Never commit `latest`.** Floating tags are rejected by validation.
- **Record changes.** Note image bumps in the project changelog so the
  deployment history stays traceable.
