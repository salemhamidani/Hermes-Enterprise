<!--
Hermes Enterprise Stack (HES)
File: docs/OPERATIONS.md
Purpose: Provide operator procedures for Phase 1 infrastructure.
-->

# Operations

## Install

```bash
cp .env.example .env
make install
```

The installer is idempotent. It creates missing runtime directories, validates Compose configuration, pulls images, and starts containers.

## Health Check

```bash
make doctor
```

Doctor checks the host operating system, Docker daemon, Docker Compose V2, `.env`, writable directories, and Compose configuration.

## Validate

```bash
make validate
```

Validation checks Bash scripts and Docker Compose configuration. If `shellcheck` is installed, it is used automatically.

## Update

```bash
make update
```

Update pulls current configured images and recreates changed containers.

## Logs

```bash
make logs
```

Logs follow all Compose services with the latest 200 lines.

Lifecycle script logs are also written under `HES_LOG_DIR/scripts`, which defaults to `logs/scripts`.

## Status

```bash
make status
```

Status shows Docker Compose container state.

## Uninstall

```bash
make uninstall
```

Uninstall stops containers and removes orphans. Runtime data is preserved by default.

To remove runtime data, set:

```bash
HES_REMOVE_DATA=true
```

Then run:

```bash
make uninstall
```
