<!--
Hermes Enterprise Stack (HES)
File: NetworkingGuide.md
Purpose: Operator guide for Sprint 2 Docker network foundation.
-->

# Networking Guide

Sprint 2 expands HES network segmentation while keeping the stack infrastructure-only.

## Networks

| Logical name | Docker name variable | External access | Purpose |
| --- | --- | --- | --- |
| `hes-frontend` | `HES_FRONTEND_NETWORK` | Bridge, attachable | Public ingress network for Traefik. |
| `hes-backend` | `HES_BACKEND_NETWORK` | Internal only | Future private service traffic. |
| `hes-management` | `HES_MANAGEMENT_NETWORK` | Internal only | Traefik to Docker socket proxy. |
| `hes-internal` | `HES_INTERNAL_NETWORK` | Internal only | Reserved internal infrastructure network. |
| `hes-public` | `HES_PUBLIC_NETWORK` | Bridge, attachable | Backward compatibility for existing operators. |

## Rules

- Do not hardcode concrete Docker network names in services.
- Public services must use Traefik instead of direct host port publishing.
- Management services must stay off public networks.
- Backend-only services must not publish host ports.
- Future services join only the networks they actually need.

## Current Attachment

- `traefik`: `hes-frontend`, `hes-management`.
- `docker-socket-proxy`: `hes-management` only.

No Hermes service is attached in Sprint 2.
