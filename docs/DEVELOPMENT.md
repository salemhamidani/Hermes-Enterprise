<!--
Hermes Enterprise Stack (HES)
File: docs/DEVELOPMENT.md
Purpose: Document contribution and development standards for Phase 1.
-->

# Development

## Standards

- Use Docker Compose V2 and the current Compose Specification.
- Do not use deprecated Compose syntax.
- Keep each infrastructure concern in its own Compose file.
- Follow the Compose module rules in `compose/README.md`.
- Keep every runtime value configurable through `.env`.
- Use Bash for scripts.
- Start every shell script with `set -Eeuo pipefail`.
- Make operations idempotent.
- Use LF line endings.
- Keep `.env` entries as simple `HES_KEY=value` assignments.
- Do not commit secrets or runtime state.

## Validation

Run:

```bash
make validate
```

Before opening a pull request.

## Adding Future Services

Future Hermes services should be added in later phases only. Each service family should have a dedicated Compose module, documentation, and environment variables.
