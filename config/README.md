<!--
Hermes Enterprise Stack (HES)
File: config/README.md
Purpose: Document configuration files used by Phase 1 infrastructure.
-->

# Configuration

This directory contains configuration consumed by infrastructure containers.

## Traefik

Dynamic Traefik configuration lives in `config/traefik/dynamic`.

The default security headers middleware is provided as a reusable baseline for future Hermes services. Phase 1 does not register any Hermes application routers.
