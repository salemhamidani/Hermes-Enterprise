<!--
Hermes Enterprise Stack (HES)
File: TLSGuide.md
Purpose: Operator guide for Sprint 2 TLS and ACME behavior.
-->

# TLS Guide

Sprint 2 prepares production TLS through Traefik and Let's Encrypt ACME HTTP challenge.

## Configuration

| Variable | Purpose |
| --- | --- |
| `HES_DOMAIN` | Public domain for future routes. |
| `HES_ADMIN_EMAIL` | ACME account email. |
| `HES_TRAEFIK_CERT_RESOLVER` | Resolver name, default `letsencrypt`. |
| `HES_TRAEFIK_ACME_STORAGE` | In-container ACME storage path. |
| `HES_TRAEFIK_ACME_CA_SERVER` | Production ACME directory URL. |
| `HES_TRAEFIK_ACME_STAGING_CA_SERVER` | Staging ACME directory URL for dry runs. |

## Production Mode

Production deployments must use real `HES_DOMAIN` and `HES_ADMIN_EMAIL` values. Validation rejects `example.com` and `admin@example.com` when `HES_ENVIRONMENT=production`.

## Staging Mode

Use the staging CA server before production exposure to avoid Let's Encrypt rate limits:

```text
HES_TRAEFIK_ACME_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory
```

## Certificate Storage

ACME state lives under `ssl/letsencrypt/acme.json`. Repair creates the file if missing and sets `chmod 600`; validation confirms the directory and permissions.

## TLS Policy

The default TLS option requires TLS 1.2 minimum and strict SNI. A modern TLS 1.3-only option is documented for future service-specific use.
