<!--
Hermes Enterprise Stack (HES)
File: docs/SECURITY.md
Purpose: Document security decisions for Phase 1 infrastructure.
-->

# Security

## Secrets

HES does not hardcode secrets. Local secret values belong in `.env` or a future secret manager integration. `.env` is ignored by Git.

## Docker API Exposure

Traefik uses a Docker socket proxy instead of mounting the host Docker socket directly. The proxy is configured with read-only API permissions needed for discovery and blocks mutating operations.

## Container Hardening

Phase 1 services use:

- `no-new-privileges`.
- Dropped Linux capabilities by default.
- Read-only root filesystems where supported.
- Explicit temporary filesystems for writable runtime paths.
- Internal-only networking for the Docker socket proxy.

## TLS

Traefik is configured for ACME HTTP challenge by default. Production deployments must set `HES_ENVIRONMENT=production`, `HES_DOMAIN`, and `HES_ADMIN_EMAIL` before public exposure.

## Dashboard

The Traefik dashboard is disabled in Phase 1.

Phase 1 does not publish dashboard router labels. Do not add public dashboard exposure without authentication middleware.
