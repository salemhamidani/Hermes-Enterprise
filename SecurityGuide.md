<!--
Hermes Enterprise Stack (HES)
File: SecurityGuide.md
Purpose: Comprehensive security reference for Sprint 2 infrastructure.
-->

# Security Guide

Sprint 2 implements the HES security foundation while keeping the stack infrastructure-only. No Hermes Agent, Dashboard, WebUI, database, or monitoring service is deployed.

## Security Layers

```text
Internet -> Traefik -> Security middleware -> Future service routes
             |
             +-> Docker socket proxy -> read-limited Docker API
```

## Docker Socket Proxy

Traefik never mounts `/var/run/docker.sock` directly. Docker provider discovery uses `tcp://docker-socket-proxy:2375` over the internal management network.

Allowed proxy endpoints:

| Endpoint | Value |
| --- | --- |
| `CONTAINERS` | `1` |
| `EVENTS` | `1` |
| `INFO` | `1` |
| `NETWORKS` | `1` |
| `VERSION` | `1` |

All mutating or sensitive endpoints remain disabled, including `POST`, `EXEC`, `IMAGES`, `SECRETS`, `SYSTEM`, and `VOLUMES`.

## Network Segmentation

| Network | Role |
| --- | --- |
| `hes-frontend` | Public ingress network. |
| `hes-backend` | Future private service network. |
| `hes-management` | Traefik and Docker socket proxy management path. |
| `hes-internal` | Reserved internal infrastructure network. |
| `hes-public` | Backward-compatible public network. |

Concrete Docker network names are controlled by `.env`.

## Traefik Security Middleware

`config/traefik/dynamic.yml` defines reusable middleware:

- `hes-security-headers`
- `hes-rate-limit`
- `hes-compress`
- `hes-secure-chain`

Security headers include HSTS, CSP, X-Frame-Options, Referrer-Policy, Permissions-Policy, and X-Content-Type-Options behavior.

## TLS

Traefik supports Let's Encrypt HTTP challenge and automatic renewal. ACME state is stored in `ssl/letsencrypt/acme.json` and must be `chmod 600`.

## Logging

Logs are separated by purpose:

| Path | Purpose |
| --- | --- |
| `logs/traefik/access/` | Structured access logs. |
| `logs/traefik/application/` | Traefik application logs. |
| `logs/traefik/security/` | Reserved security event logs. |
| `logs/scripts/` | Lifecycle script logs. |

## Secrets

No hardcoded secrets are allowed. `.env` is ignored by Git and parsed as data. `secrets/` is reserved for future Docker Secrets source files and ignores secret values by default.

## Container Hardening

Current long-running services include health checks, restart policy, resource limits, `no-new-privileges`, dropped capabilities, read-only filesystems where supported, `tmpfs`, graceful stop periods, and log rotation.
