<!--
Hermes Enterprise Stack (HES)
File: TraefikGuide.md
Purpose: Operator guide for Sprint 2 production Traefik foundation.
-->

# Traefik Guide

Sprint 2 implements Traefik as the production ingress foundation without adding Hermes routes.

## Runtime Role

Traefik provides:

- HTTP entrypoint on port `80`.
- HTTPS entrypoint on port `443`.
- HTTP to HTTPS redirection.
- ACME HTTP challenge support.
- Docker provider discovery through the Docker socket proxy.
- File provider dynamic middleware from `config/traefik/dynamic.yml`.
- Ping health endpoint preparation.
- Prometheus-format metrics endpoint preparation.
- Structured JSON application and access logs.

## Files

| File | Purpose |
| --- | --- |
| `compose/traefik.yml` | Active Traefik Compose service. |
| `config/traefik/dynamic.yml` | Active reusable dynamic middleware. |
| `config/traefik/traefik.yml` | Reference static config for future config-file migration. |
| `config/traefik/headers.yml` | Header middleware reference. |
| `config/traefik/middlewares.yml` | Rate limit, compression, and chain reference. |
| `config/traefik/tls.yml` | TLS policy reference. |
| `config/traefik/certificates.yml` | Certificate resolver policy reference. |
| `config/traefik/accesslog.yml` | Structured access log policy reference. |
| `config/traefik/metrics.yml` | Metrics and ping endpoint reference. |
| `config/traefik/providers.yml` | Provider policy reference. |
| `config/traefik/entrypoints.yml` | Entrypoint policy reference. |

## Security Defaults

- Dashboard routing is disabled.
- Docker discovery uses `tcp://docker-socket-proxy:2375`.
- Services are not exposed by default.
- Traefik has `read_only: true`, `cap_drop: [ALL]`, and only `NET_BIND_SERVICE` added.
- Traefik joins `hes-frontend` and `hes-management` only.

## Future Routing

Future services must add their own router labels and explicitly opt into `hes-secure-chain`. Sprint 2 intentionally does not publish any Hermes router.
