<!--
Hermes Enterprise Stack (HES)
File: FolderGuide.md
Purpose: Complete directory structure reference for Phase 1.
-->

# Folder Guide

This guide documents the complete directory structure of Hermes Enterprise Stack (HES), the purpose of every directory, what belongs where, what is Git-tracked versus ignored, the `.hes-managed` marker system, the distinction between runtime and source directories, and how to add new directories.

## Complete Directory Structure

```text
Hermes-Enterprise/
├── .env                        # Local environment config (Git-ignored)
├── .env.example                # Example environment template (Git-tracked)
├── .gitattributes              # LF line ending enforcement (Git-tracked)
├── .gitignore                  # Git ignore rules (Git-tracked)
├── .shellcheckrc               # ShellCheck configuration (Git-tracked)
├── Makefile                    # Operator entrypoints (Git-tracked)
├── PROJECT_SPEC.md             # Project constitution (Git-tracked)
├── README.md                   # Project overview (Git-tracked)
├── CHANGELOG.md                # Changelog (Git-tracked)
├── CONTRIBUTING.md             # Contribution guidelines (Git-tracked)
├── DECISIONS.md                # Architectural decision records (Git-tracked)
├── LICENSE                     # MIT license (Git-tracked)
├── ROADMAP.md                  # Milestone roadmap (Git-tracked)
├── SECURITY.md                 # Security policy (Git-tracked)
├── SUPPORT.md                  # Support guide (Git-tracked)
├── AUDIT_REPORT.md             # Phase 1 audit report (Git-tracked)
│
├── compose/                    # Modular Docker Compose files (Git-tracked)
│   ├── compose.yml             # Orchestration entry point with includes
│   ├── network.yml             # hes-public and hes-internal networks
│   ├── security.yml            # Docker socket proxy service
│   ├── traefik.yml             # Traefik ingress service
│   └── README.md               # Compose module conventions
│
├── config/                     # Safe-to-commit runtime configuration (Git-tracked)
│   ├── README.md
│   └── traefik/
│       └── dynamic/
│           └── security-headers.yml  # TLS options and security middleware
│
├── scripts/                    # Idempotent operational scripts (Git-tracked)
│   ├── install.sh
│   ├── doctor.sh
│   ├── validate.sh
│   ├── repair.sh
│   ├── update.sh
│   ├── backup.sh
│   ├── restore.sh
│   ├── uninstall.sh
│   └── lib/
│       └── common.sh           # Shared Bash utilities
│
├── docs/                       # Professional operator documentation (Git-tracked)
│   ├── ARCHITECTURE.md
│   ├── DEVELOPMENT.md
│   ├── OPERATIONS.md
│   ├── SECURITY.md
│   ├── BACKUP_RESTORE.md
│   ├── PHASE1_REVIEW_REPORT.md
│   └── Phase1.html
│
├── .github/                    # GitHub automation and CI workflows (Git-tracked)
│   ├── README.md
│   └── workflows/
│       ├── validate.yml
│       ├── shellcheck.yml
│       ├── lint.yml
│       ├── docker.yml
│       └── release.yml
│
├── backup/                     # Backup archives (Git-ignored)
│   ├── .gitkeep
│   └── .hes-managed
│
├── data/                       # Future persistent service data (Git-ignored)
│   ├── .gitkeep
│   └── .hes-managed
│
├── logs/                       # Container and script logs (Git-ignored)
│   ├── .gitkeep
│   ├── .hes-managed
│   ├── scripts/
│   │   ├── .hes-managed
│   │   ├── backup.log
│   │   ├── doctor.log
│   │   ├── install.log
│   │   ├── repair.log
│   │   ├── restore.log
│   │   ├── uninstall.log
│   │   ├── update.log
│   │   └── validate.log
│   └── traefik/
│       ├── .hes-managed
│       └── access.log
│
├── ssl/                        # TLS and ACME state (Git-ignored)
│   ├── .gitkeep
│   ├── .hes-managed
│   └── letsencrypt/
│       └── .hes-managed
│       └── acme.json
│
├── storage/                    # Future service storage (Git-ignored)
│   ├── .gitkeep
│   └── .hes-managed
│
└── workspace/                  # Local operator workspace (Git-ignored)
    └── .gitkeep
```

## Purpose of Every Directory

### Source Directories (Git-Tracked)

| Directory | Purpose |
| --- | --- |
| `compose/` | Modular Docker Compose V2 files. Each file covers one infrastructure concern. |
| `config/` | Safe-to-commit runtime configuration. Traefik dynamic config lives here. |
| `scripts/` | Idempotent Bash lifecycle scripts and shared utilities. |
| `scripts/lib/` | Shared library (`common.sh`) sourced by all lifecycle scripts. |
| `docs/` | Professional operator documentation, architecture, security, and reports. |
| `.github/workflows/` | GitHub Actions CI workflows for validation, linting, ShellCheck, Docker, and releases. |

### Runtime Directories (Git-Ignored)

| Directory | Purpose | Default Env Var |
| --- | --- | --- |
| `backup/` | Timestamped backup archives. | `HES_BACKUP_DIR` |
| `data/` | Future persistent service data. | `HES_DATA_DIR` |
| `logs/` | Container and script lifecycle logs. | `HES_LOG_DIR` |
| `logs/scripts/` | Per-script log files. | `HES_LOG_DIR` (derived) |
| `logs/traefik/` | Traefik access logs. | `HES_LOG_DIR` (derived) |
| `ssl/` | TLS certificates and ACME state. | `HES_SSL_DIR` |
| `ssl/letsencrypt/` | ACME certificate store. | `HES_SSL_DIR` (derived) |
| `storage/` | Future service storage. | `HES_STORAGE_DIR` |
| `workspace/` | Local operator scratch space. | `HES_WORKSPACE_DIR` |

## What Belongs Where

### In `compose/`

- Docker Compose V2 files, one concern per file.
- The `compose.yml` entry point with `include` directives.
- The `README.md` module conventions file.
- No secrets, no runtime values (use `.env` variables).

### In `config/`

- Safe-to-commit runtime configuration.
- Traefik dynamic configuration (middleware, TLS options).
- Configuration that is version-controlled but applied at runtime.
- No secrets.

### In `scripts/`

- Lifecycle scripts (`install.sh`, `doctor.sh`, etc.).
- Shared utilities in `scripts/lib/`.
- Scripts that start with `set -Eeuo pipefail` and use `common.sh`.
- No hardcoded runtime values.

### In `docs/`

- Markdown documentation.
- The HTML Phase 1 review document.
- No executable code, no secrets.

### In `.github/workflows/`

- GitHub Actions workflow YAML files.
- CI configuration.

### In Runtime Directories

- `backup/` — only `.tar.gz` backup archives and the `.hes-managed` marker.
- `data/` — only future service persistent data.
- `logs/` — only log files and the `.hes-managed` marker.
- `ssl/` — only certificate and ACME state.
- `storage/` — only future service storage.
- `workspace/` — only local operator files.

## Git-Tracked vs Ignored

### Git-Tracked

All source files, configuration, scripts, documentation, and CI workflows are tracked:

- `.env.example` (never `.env`)
- `.gitattributes`, `.gitignore`, `.shellcheckrc`
- `Makefile`
- All root `.md` files (`README.md`, `PROJECT_SPEC.md`, etc.)
- `compose/` and `compose/README.md`
- `config/` and its contents
- `scripts/` and `scripts/lib/`
- `docs/` and its contents
- `.github/` and its contents

### Git-Ignored

All runtime state and local secrets are ignored:

- `.env` and all `.env.*` (except `.env.example`)
- `logs/*` (except `.gitkeep`)
- `backup/*` (except `.gitkeep`)
- `storage/*` (except `.gitkeep`)
- `ssl/*` (except `.gitkeep`)
- `data/*` (except `.gitkeep`)
- `workspace/*` (except `.gitkeep`)
- `*.log`, `*.tmp`, `*.bak`, `*.swp`
- `.hes-managed` files
- `.DS_Store`, `Thumbs.db`

The `.gitkeep` files ensure Git tracks the directory structure even when empty. The `.gitignore` uses negation patterns (`!logs/.gitkeep`) to keep the `.gitkeep` file while ignoring everything else.

## .hes-managed Marker System

### Purpose

The `.hes-managed` marker file identifies directories that HES lifecycle scripts own and may modify. This is a safety mechanism (see `DECISIONS.md`, Decision 6) to prevent scripts from accidentally destroying data in directories they do not own.

### How It Works

1. **Creation**: `mark_managed_dir()` in `common.sh` writes a `.hes-managed` file into a directory.
2. **Verification**: `require_managed_dir()` fails with an error if a directory lacks the marker.
3. **Safe cleanup**: `clear_managed_dir()` removes all contents except `.gitkeep` and `.hes-managed`, but only after verifying the marker exists.
4. **Git-ignored**: `.hes-managed` files are listed in `.gitignore` and never committed.

### Marker File Contents

Each `.hes-managed` file contains:

```text
# Hermes Enterprise Stack (HES)
# File: .hes-managed
# Purpose: Mark this runtime directory as managed by HES lifecycle scripts.
```

### Directories With Markers

- `backup/`
- `data/`
- `logs/`
- `logs/scripts/`
- `logs/traefik/`
- `ssl/`
- `ssl/letsencrypt/`
- `storage/`
- `workspace/` is created with `.gitkeep` but may not carry the marker depending on the script path.

### Safety Guarantee

Scripts refuse to:

- Modify a directory that lacks `.hes-managed` (via `require_managed_dir`).
- Clear a directory without first verifying it is managed (via `clear_managed_dir`).
- Replace `compose/` or `config/` through unmanaged paths (via `remove_project_subdir`, which only allows `compose` and `config`).

## Runtime vs Source Directories

### Source Directories

Source directories are version-controlled, human-authored, and read by scripts and Compose at runtime. They should never be written to by lifecycle scripts at runtime.

- `compose/`
- `config/`
- `scripts/` and `scripts/lib/`
- `docs/`
- `.github/`

Exception: `restore.sh` replaces `compose/` and `config/` from a trusted backup archive. This is an intentional, validated operation using `remove_project_subdir`, which explicitly allows only `compose` and `config`.

### Runtime Directories

Runtime directories hold mutable state generated by the stack. They are Git-ignored, created by `ensure_directories()`, and marked with `.hes-managed`.

- `backup/`
- `data/`
- `logs/`
- `ssl/`
- `storage/`
- `workspace/`

All runtime directory paths are configurable through `.env`:

| Variable | Default | Description |
| --- | --- | --- |
| `HES_WORKSPACE_DIR` | `./workspace` | Operator scratch space. |
| `HES_LOG_DIR` | `./logs` | Container and script logs. |
| `HES_BACKUP_DIR` | `./backup` | Backup archives. |
| `HES_STORAGE_DIR` | `./storage` | Future service storage. |
| `HES_SSL_DIR` | `./ssl` | TLS and ACME state. |
| `HES_DATA_DIR` | `./data` | Future persistent data. |
| `HES_CONFIG_DIR` | `./config` | Runtime configuration. |

Paths are relative to the project root unless absolute paths are supplied. The `runtime_path()` helper resolves env-driven paths with defaults.

## How to Add New Directories

### Adding a Runtime Directory

1. Add the directory to the `dirs` array in `ensure_directories()` in `scripts/lib/common.sh`.
2. Add a corresponding `HES_<NAME>_DIR` variable to `.env.example`.
3. Add the directory to `.gitignore` with a negation pattern for `.gitkeep`:
   ```text
   <dir>/*
   !<dir>/.gitkeep
   ```
4. Create the directory placeholder: `mkdir -p <dir> && touch <dir>/.gitkeep`.
5. If the directory should be managed, `mark_managed_dir()` is called automatically by `ensure_directories()`.

### Adding a Source Directory

1. Create the directory with the intended contents.
2. Add it to the project structure documentation (this guide and `docs/ARCHITECTURE.md`).
3. Ensure it follows the relevant conventions (Compose, config, scripts, or docs).
4. Do not add `.gitignore` entries for source directories — they should be fully tracked.

### Naming Conventions

- Use lowercase, hyphen-separated names for directories.
- Use singular domain names for Compose modules (`compose/datastore.yml`).
- Use descriptive names that communicate ownership and purpose.
- Avoid abbreviations that are not self-explanatory.
