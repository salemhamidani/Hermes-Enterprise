<!--
Hermes Enterprise Stack (HES)
File: docs/ComposeCompatibility.md
Purpose: Document Docker Compose compatibility, include portability, and launcher script policy.
-->

# Compose Compatibility

## Compatibility Position

HES supports Docker Compose V2 and keeps `compose/compose.yml` for backward compatibility with existing operator workflows.

The preferred production entrypoints are the launcher scripts in `scripts/`:

- `scripts/compose-up.sh`
- `scripts/compose-down.sh`
- `scripts/compose-restart.sh`
- `scripts/compose-validate.sh`

These scripts load Compose modules with explicit `-f` arguments instead of depending on the Compose `include` directive.

## Why Launchers Are Preferred

The `include` directive is useful, but it is less portable across older Docker Compose V2 installations. Explicit `-f` loading is supported broadly and keeps local development, CI, and production operations aligned.

The launcher scripts preserve the existing modular architecture while making the operator entrypoints more portable.

## Module Load Order

The launcher scripts load modules in this order:

1. `compose/network.yml`
2. `compose/security.yml`
3. `compose/traefik.yml`
4. Future `compose/*.yml` modules in alphabetical order, excluding `compose/compose.yml`
5. Any extra files passed with `-f` / `--file`

This order keeps shared networks available before infrastructure services and preserves the Phase 1 dependency contract.

## Backward Compatibility

`compose/compose.yml` still contains the `include` block so older documentation and direct operator usage continue to work:

```bash
docker compose --env-file .env -f compose/compose.yml config
```

For production and CI, prefer:

```bash
scripts/compose-validate.sh
scripts/compose-up.sh
scripts/compose-down.sh
scripts/compose-restart.sh
```

## Minimum Compose Requirement for Include

If an operator chooses to use `compose/compose.yml` directly, they must use a Docker Compose V2 release that supports the Compose Specification `include` directive.

Operators who cannot guarantee that support should use the launcher scripts. The launchers are the compatibility boundary for production automation.
