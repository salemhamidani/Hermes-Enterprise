# Hermes Enterprise Stack (HES)
# File: compose/README.md
# Purpose: Define Compose module conventions for scalable HES infrastructure.

# Compose Conventions

HES is expected to grow beyond 50 Docker services. Keep Compose modular from the beginning.

## Module Rules

- Keep one infrastructure concern per Compose file.
- Use Docker Compose V2 and the Compose Specification.
- Do not add a top-level `version` key.
- Do not use `container_name`.
- Do not use floating `latest` image tags.
- Keep service names lowercase and DNS-safe.
- Use service DNS names for service-to-service communication.
- Keep secrets out of Compose files and `.env.example`.
- Put runtime values in `.env`.
- Add health checks to long-running services.
- Add log rotation to long-running services.
- Add `com.hermes.stack`, `com.hermes.environment`, and `com.hermes.phase` labels.

## Network Rules

- Public ingress services join `hes-public`.
- Private infrastructure services join `hes-internal`.
- Future application services should join only the networks they need.
- Never expose an internal-only service through published ports.

## File Naming

Use clear module names:

```text
compose/<domain>.yml
```

Examples for future phases:

```text
compose/observability.yml
compose/datastore.yml
compose/messaging.yml
compose/hermes-api.yml
```

Do not generate future service modules during Phase 1.
