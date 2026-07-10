<!--
Hermes Enterprise Stack (HES)
File: DeveloperGuide.md
Purpose: Developer onboarding, coding standards, and contribution workflow for Phase 1.
-->

# Developer Guide

This guide helps developers set up a working environment, understand HES coding standards, add new Compose modules and scripts, validate changes, and submit pull requests.

## Development Environment Setup

### Prerequisites

- Ubuntu 24.04 LTS (or a compatible Linux VM for local development).
- Docker Engine installed and running.
- Docker Compose V2 (`docker compose version` succeeds).
- Bash 4.0 or later.
- GNU coreutils: `tar`, `find`, `date`, `chmod`, `mkdir`.
- `git` for cloning and branching.
- Optional but recommended: `shellcheck`, `yamllint`, `markdownlint-cli`.

### Install Docker on Ubuntu 24.04

```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable --now docker
```

Verify:

```bash
docker --version
docker compose version
```

### Install ShellCheck (Optional)

```bash
sudo apt-get install -y shellcheck
```

## How to Clone, Configure, and Run Locally

### Clone the Repository

```bash
git clone https://github.com/salemhamidani/Hermes-Enterprise.git
cd Hermes-Enterprise
```

### Configure the Environment

Copy the example environment file and adjust values:

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

- `HES_ENVIRONMENT` — use `development` for local work.
- `HES_DOMAIN` — set to a test domain or keep `example.com` in development.
- `HES_ADMIN_EMAIL` — set to a valid email for ACME certificate registration.

Review every variable in `.env` before switching to production. The `.env` file is parsed as data, not as executable shell. Only simple `HES_KEY=value` lines are allowed. Only `HES_*` variables are accepted.

### Run the Stack Locally

```bash
make doctor
make validate
make install
```

`make doctor` checks the host OS, Docker daemon, Compose V2, `.env`, writable directories, and Compose configuration. `make validate` checks Bash scripts and Compose files. `make install` creates runtime directories, pulls images, and starts containers.

### Verify the Stack

```bash
make status
make logs
```

## Code Style and Conventions

### General Principles

- Keep changes minimal, focused, and backward compatible.
- Never remove features without an explicit decision in `DECISIONS.md`.
- Use LF line endings everywhere. CRLF is rejected by validation.
- Do not commit secrets, `.env`, or runtime state.
- Keep documentation in sync with the actual implementation.

### Compose Conventions

- Use Docker Compose V2 and the current Compose Specification.
- Do not add a top-level `version` key.
- Do not use `container_name`.
- Do not use floating `latest` image tags.
- Keep one infrastructure concern per Compose file.
- Add health checks and log rotation to long-running services.
- Apply `com.hermes.stack`, `com.hermes.environment`, and `com.hermes.phase` labels to every service and network.
- Put runtime values in `.env`. Never hardcode secrets in Compose files.
- Use service DNS names for service-to-service communication.

See `compose/README.md` for the full module rules.

### Shell Scripting Standards

- Start every script with `set -Eeuo pipefail`.
- Use `#!/usr/bin/env bash` as the shebang.
- Source shared helpers from `scripts/lib/common.sh`.
- Keep scripts idempotent — safe to run multiple times.
- Provide colored terminal output and persistent logs via `log_info`, `log_success`, `log_warn`, and `log_error`.
- Use `die` for fatal errors with a meaningful exit code.
- Use LF line endings.

### Configuration Standards

- All runtime values belong in `.env`.
- Only `HES_*` variables are allowed.
- Update `.env.example` whenever new variables are introduced.
- Never commit secrets or `.env`.

### Documentation Standards

- Documentation is Markdown.
- Keep documentation in sync with actual scripts and Compose behavior.
- Update relevant docs when changing behavior.
- Use present tense and active voice.
- Professional, operator-focused tone.

## How to Add New Compose Modules

HES uses a modular Compose architecture. Each infrastructure concern lives in its own file under `compose/`.

### Steps

1. Create a new file: `compose/<domain>.yml`.
2. Add a file header comment block:
   ```yaml
   # Hermes Enterprise Stack (HES)
   # File: compose/<domain>.yml
   # Purpose: <one-line description>.
   ```
3. Include the project name and any networks or services.
4. Add the new module to the `include` list in `compose/compose.yml`:
   ```yaml
   include:
     - path: compose/network.yml
     - path: compose/security.yml
     - path: compose/traefik.yml
     - path: compose/<domain>.yml
   ```
5. Add every service and network label set: `com.hermes.stack`, `com.hermes.environment`, `com.hermes.phase`.
6. Add health checks and log rotation to long-running services.
7. Add any new `HES_*` variables to `.env.example`.
8. Run `make validate` to confirm the module passes all checks.

### Naming Conventions

Use clear, lowercase, DNS-safe module names:

```text
compose/observability.yml
compose/datastore.yml
compose/messaging.yml
compose/hermes-api.yml
```

### Network Membership

- Public-facing services join `hes-public`.
- Internal-only services join `hes-internal`.
- Services join only the networks they need.
- Never expose an internal-only service through published ports.

## How to Add New Scripts

Lifecycle scripts live in `scripts/`. Shared utilities live in `scripts/lib/common.sh`.

### Steps

1. Create a new file: `scripts/<name>.sh`.
2. Start with the standard header and strict mode:
   ```bash
   #!/usr/bin/env bash
   # Hermes Enterprise Stack (HES)
   # File: scripts/<name>.sh
   # Purpose: <one-line description>.

   set -Eeuo pipefail
   ```
3. Source common helpers:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   # shellcheck disable=SC1091
   source "${SCRIPT_DIR}/lib/common.sh"
   ```
4. Implement a `main()` function and call it at the end:
   ```bash
   main() {
     log_info "Starting <name>."
     ensure_env_file
     load_env
     ensure_directories
     setup_logging
     validate_env
     # ... logic ...
     log_success "<name> completed."
   }

   main "$@"
   ```
5. Use shared helpers: `require_command`, `require_env_file`, `load_env`, `ensure_directories`, `setup_logging`, `validate_env`, `compose`, `runtime_path`, `mark_managed_dir`, `require_managed_dir`.
6. Make the script executable: `chmod +x scripts/<name>.sh`.
7. Add a Make target in `Makefile` if the script needs an operator entrypoint.
8. Run `make validate` to confirm.

### Available Shared Helpers

| Helper | Purpose |
| --- | --- |
| `log_info`, `log_success`, `log_warn`, `log_error` | Colored output and persistent logging. |
| `die` | Log an error and exit with a code. |
| `load_env` | Parse `.env` safely as data. |
| `ensure_env_file` | Copy `.env.example` to `.env` if missing. |
| `require_env_file` | Fail if `.env` does not exist. |
| `ensure_directories` | Create and mark all runtime directories. |
| `setup_logging` | Configure per-script log file under `logs/scripts/`. |
| `validate_env` | Validate all `HES_*` environment values. |
| `compose` | Run `docker compose` with the correct project and env file. |
| `runtime_path` | Resolve a path from an env var with a default. |
| `mark_managed_dir` | Stamp a directory with `.hes-managed`. |
| `require_managed_dir` | Fail if a directory lacks the `.hes-managed` marker. |
| `clear_managed_dir` | Safely clear a managed directory (preserves `.gitkeep` and `.hes-managed`). |

## Testing and Validation Workflow

### Local Validation

Run before every push:

```bash
make validate
```

Validation checks:

- CRLF line endings are rejected across the entire repository.
- Bash scripts pass `shellcheck` if installed, otherwise syntax-only (`bash -n`).
- Compose files contain no deprecated `version` key.
- Compose files contain no `container_name`.
- Compose files contain no floating `latest` image tags.
- Docker Compose configuration is valid (`compose config`).

### Doctor Checks

```bash
make doctor
```

Checks the host OS (Ubuntu 24.04 LTS), Docker daemon, Compose V2, `.env` validity, writable runtime directories, and Compose configuration.

### Idempotency Testing

Run install and repair multiple times to confirm no side effects:

```bash
make install
make install
make repair
make repair
```

Each run must produce the same result without errors.

### Backup and Restore Testing

```bash
make backup
HES_RESTORE_ARCHIVE=backup/<archive>.tar.gz make restore
make validate
```

Confirm the restored state passes validation.

### CI Checks

GitHub Actions run four workflows on every push and pull request to `main` and `develop`:

- **Validate** — runs `make validate`.
- **ShellCheck** — lints all Bash scripts and rejects CRLF.
- **Lint** — runs `markdownlint` and `yamllint`.
- **Docker** — builds and validates Docker-related configuration.

All CI checks must pass before merge.

## PR Submission Process

### Branching Model

HES follows Git Flow:

- `main` — stable releases only. Never commit directly.
- `develop` — integration branch for the next release.
- `feature/*` — feature and sprint work.
- `bugfix/*` — non-sprint bug fixes.
- `hotfix/*` — urgent fixes from `main`.

### Steps

1. Branch from `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/sprint-NN-description
   ```
2. Make changes following all standards above.
3. Validate locally:
   ```bash
   make validate
   ```
4. Push and open a PR against `develop`:
   ```bash
   git push -u origin feature/sprint-NN-description
   ```
5. Ensure all CI checks pass.
6. Request review from a maintainer.
7. Squash or rebase commits if requested.
8. After approval and merge, delete the feature branch.

### Commit Messages

Use clear, descriptive messages with an imperative verb:

```text
Add Traefik security headers middleware

- Add default HSTS and TLS options
- Register reusable middleware in dynamic config
- Link middleware in compose README
```

Keep the subject line under 72 characters.

### PR Checklist

Before requesting review, verify:

- Branch name follows naming conventions.
- Commit messages follow standards.
- No secrets committed.
- No `.env` committed.
- No `container_name` in Compose files.
- No `latest` image tags.
- No deprecated `version` key in Compose files.
- Health checks present for long-running services.
- Log rotation present for long-running services.
- Labels applied (`com.hermes.*`).
- Scripts start with `set -Eeuo pipefail`.
- Scripts use shared helpers from `common.sh`.
- Scripts are idempotent.
- LF line endings (no CRLF).
- Documentation updated and in sync.
- `.env.example` updated if new variables added.
- No unrelated changes.
- All CI checks green.

## Shell Scripting Standards (Expanded)

### Strict Mode

Every script starts with:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

- `-e` — exit on error.
- `-E` — ERR trap works in functions and subshells.
- `-u` — treat unset variables as errors.
- `-o pipefail` — a pipe fails if any command fails.
- The ERR trap in `common.sh` logs the failing line and exit code.

### Error Handling

- Use `die "message" [exit_code]` for fatal errors.
- Use meaningful exit codes: `64` (data error), `65` (data format), `66` (not found), `69` (service unavailable), `70` (internal error), `78` (OS validation), `127` (command not found).
- The ERR trap automatically logs and propagates failures.

### Environment Loading

- Always call `load_env` before using `HES_*` variables.
- `load_env` preserves process-level overrides (important for `make` calls).
- Only `HES_*` variables are accepted from `.env`.
- `.env` is parsed as data, not as shell. Invalid lines cause an error.

### Logging

- Use `setup_logging` to create a per-script log file under `logs/scripts/<script>.log`.
- Log messages include a UTC timestamp and level.
- Color output is automatic when stdout is a terminal.

### Path Safety

- Use `resolve_project_path` for relative-to-absolute path resolution.
- Use `runtime_path` to resolve env-driven runtime directories.
- Use `require_managed_dir` before modifying any runtime directory.
- Use `clear_managed_dir` to safely clear contents while preserving markers.

## Debugging Tips

### Script Debug Output

Enable Bash tracing for a specific script:

```bash
bash -x ./scripts/install.sh
```

Or add `-x` temporarily to the `set` line for verbose output.

### Check Environment

```bash
# Verify .env loads correctly
source scripts/lib/common.sh
load_env
echo "$HES_ENVIRONMENT"
echo "$HES_DOMAIN"
```

### Docker Compose Debugging

```bash
# Render the full merged Compose configuration
docker compose --project-directory . --env-file .env -f compose/compose.yml config

# Check container status
make status

# Follow logs
make logs

# Inspect a specific service
docker compose --project-directory . --env-file .env -f compose/compose.yml logs traefik
```

### Doctor Diagnostics

```bash
make doctor
```

Doctor output identifies the first failing check. Common issues:

- Missing `.env` — run `cp .env.example .env`.
- Docker daemon not running — start Docker service.
- Wrong OS — Ubuntu 24.04 LTS is required.
- Unwritable directory — check permissions on `logs/`, `backup/`, `storage/`, `ssl/`, `data/`.
- Production placeholders — set `HES_DOMAIN` and `HES_ADMIN_EMAIL` when `HES_ENVIRONMENT=production`.

### Repair Runtime State

```bash
make repair
```

Repair recreates missing runtime directories and `.env` without deleting existing data.

### Socket Proxy Connectivity

If Traefik cannot discover containers, verify the Docker socket proxy:

```bash
docker compose --project-directory . --env-file .env -f compose/compose.yml logs docker-socket-proxy
```

The proxy must be healthy and on `hes-internal` for Traefik to reach the Docker API.
