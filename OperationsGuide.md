<!--
Hermes Enterprise Stack (HES)
File: OperationsGuide.md
Purpose: Day-to-day operations manual for Phase 1 infrastructure.
-->

# Operations Guide

This guide is the day-to-day operations manual for Hermes Enterprise Stack (HES) Phase 1. It covers installation, health checks, backup and restore, updates, log management, troubleshooting, disaster recovery, and emergency procedures.

## Install and Uninstall Procedures

### Install

```bash
cp .env.example .env
make install
```

The installer (`scripts/install.sh`) is idempotent. It:

1. Verifies Ubuntu 24.04 LTS.
2. Checks Docker Engine and Docker Compose V2.
3. Creates `.env` from `.env.example` if missing.
4. Loads and validates `.env`.
5. Creates all runtime directories with `.hes-managed` markers.
6. Configures per-script logging.
7. Validates the Compose configuration.
8. Pulls images.
9. Starts containers with `--remove-orphans`.

Re-running `make install` is safe and produces the same result.

### Uninstall

```bash
make uninstall
```

Uninstall stops containers and removes orphans. Runtime data is preserved by default.

To remove runtime data directories (logs, backups, storage, SSL, data, workspace):

```bash
HES_REMOVE_DATA=true make uninstall
```

This clears managed directories while preserving `.gitkeep` and `.hes-managed` markers. The script refuses to modify any directory lacking the `.hes-managed` marker.

### Repair

```bash
make repair
```

Repair (`scripts/repair.sh`) recreates missing runtime directories and `.env` without deleting existing data. It is non-destructive and idempotent. If Docker Compose is unavailable, it skips Compose validation with a warning.

## Health Checks and Monitoring

### Doctor

```bash
make doctor
```

Doctor (`scripts/doctor.sh`) checks:

- Host operating system is Ubuntu 24.04 LTS.
- Docker daemon is reachable.
- Docker Compose V2 is available.
- `.env` exists and is valid.
- All runtime directories exist and are writable.
- Compose configuration is valid.
- Current container status.

Doctor is non-destructive and safe to run at any time.

### Status

```bash
make status
```

Shows the Docker Compose service status for all containers in the project.

### Logs

```bash
make logs
```

Follows Docker Compose logs with the latest 200 lines for all services.

To view a specific service:

```bash
docker compose --project-directory . --env-file .env -f compose/compose.yml logs traefik
```

### Container Health Checks

Every Phase 1 service defines a health check. Docker reports health status through `make status`. Unhealthy containers are visible in the status output.

### Traefik Access Logs

When `HES_TRAEFIK_ACCESS_LOG_ENABLED=true` (default), Traefik writes access logs to `logs/traefik/access.log`. These provide HTTP request-level visibility.

### Script Lifecycle Logs

Every lifecycle script writes a log file under `logs/scripts/<script-name>.log`. These include timestamps, log levels (INFO, OK, WARN, FAIL), and error context.

## Backup and Restore Procedures

### Backup

```bash
make backup
```

The backup script (`scripts/backup.sh`):

1. Creates a timestamped `.tar.gz` archive in `HES_BACKUP_DIR` (default `backup/`).
2. Copies these paths into a staging directory before archiving:
   - `.env`
   - `compose/`
   - `config/`
   - `ssl/`
   - `storage/`
   - `data/`
3. Sets archive permissions to `600` (owner-only) because `.env` may contain secrets.
4. Prunes archives older than `HES_BACKUP_RETENTION_DAYS` (default 14 days).

Archive naming: `hes-backup-YYYYMMDDTHHMMSSZ.tar.gz`.

### Restore

Restore from an environment variable:

```bash
HES_RESTORE_ARCHIVE=backup/hes-backup-20260709T172418Z.tar.gz make restore
```

Or pass the archive path directly to the script:

```bash
./scripts/restore.sh backup/hes-backup-20260709T172418Z.tar.gz
```

The restore script (`scripts/restore.sh`):

1. Validates the archive path exists and ends with `.tar.gz`.
2. Validates every entry in the archive — rejects absolute paths, parent traversal (`../`), and any path not in the allowed list (`.env`, `compose/`, `config/`, `ssl/`, `storage/`, `data/`).
3. Stops running containers (if Docker Compose is available).
4. Extracts to a staging directory.
5. Restores `.env`, `compose/`, and `config/` to the project root.
6. Clears and repopulates managed runtime directories (`ssl/`, `storage/`, `data/`) only through validated paths.
7. Re-runs directory creation, logging setup, and validation.

Only restore archives from trusted sources.

See `docs/BACKUP_RESTORE.md` for the summary reference.

## Update and Upgrade Workflow

### Update Images

```bash
make update
```

The update script (`scripts/update.sh`) is idempotent. It:

1. Verifies Ubuntu 24.04 LTS.
2. Checks Docker and Compose V2.
3. Loads and validates `.env`.
4. Validates Compose configuration.
5. Pulls the latest versions of configured images.
6. Recreates changed containers with `--remove-orphans`.
7. Shows the resulting service status.

### Changing Image Versions

To change an image version, update the relevant variable in `.env`:

```bash
HES_TRAEFIK_IMAGE=traefik:v3.4
```

Then run:

```bash
make update
```

Never use floating `latest` tags. Always pin to a specific version.

### Compose Configuration Changes

When Compose files change (new module, updated service, changed labels):

```bash
make validate
make install
```

`make install` detects configuration changes and recreates affected containers.

## Log Management and Rotation

### Docker Log Rotation

All Phase 1 services configure Docker log rotation:

```yaml
logging:
  driver: json-file
  options:
    max-size: "${HES_DOCKER_LOG_MAX_SIZE:-10m}"
    max-file: "${HES_DOCKER_LOG_MAX_FILE:-5}"
```

Defaults: 10 MB per file, 5 files. Configure through `HES_DOCKER_LOG_MAX_SIZE` and `HES_DOCKER_LOG_MAX_FILE` in `.env`.

### Traefik Access Logs

Traefik writes access logs to `logs/traefik/access.log` when `HES_TRAEFIK_ACCESS_LOG_ENABLED=true`. Traefik manages its own log output; Docker log rotation applies to the container's stdout/stderr.

### Script Logs

Lifecycle script logs are written to `logs/scripts/<script-name>.log`. These are not automatically rotated. Periodically archive or remove old script logs:

```bash
# Archive old script logs
tar -czf logs/scripts/archive-$(date -u +%Y%m%d).tar.gz -C logs/scripts *.log --remove-files
```

## Troubleshooting Guide

### Doctor Fails: Unsupported OS

```
[FAIL] Unsupported OS: <name>. Ubuntu 24.04 LTS is required.
```

Solution: HES requires Ubuntu 24.04 LTS. Run on a compatible host or VM.

### Doctor Fails: Docker Daemon Not Reachable

```
[FAIL] Docker daemon is not reachable.
```

Solutions:

```bash
sudo systemctl start docker
sudo systemctl enable docker
docker info
```

### Doctor Fails: Docker Compose V2 Required

```
[FAIL] Docker Compose V2 is required.
```

Solution: Install the Docker Compose V2 plugin or use a Docker Engine version that includes it.

### Doctor Fails: Missing .env

```
[FAIL] Missing .env. Run: cp .env.example .env
```

Solution:

```bash
cp .env.example .env
```

Or run `make repair` which creates it automatically.

### Validation Fails: CRLF Line Endings

```
[FAIL] CRLF line endings detected. Use LF line endings for Linux scripts and Compose files.
```

Solution: Configure `git` to use LF and re-checkout:

```bash
git config --global core.autocrlf false
git rm --cached -r .
git reset --hard
```

Or convert files manually:

```bash
sudo apt-get install -y dos2unix
find . -type f \( -name '*.sh' -o -name '*.yml' -o -name '*.md' \) -exec dos2unix {} +
```

### Validation Fails: Deprecated Compose Version Key

```
[FAIL] Deprecated Compose version keys are not allowed.
```

Solution: Remove the top-level `version:` key from the offending Compose file. HES uses the current Compose Specification which does not require it.

### Validation Fails: container_name

```
[FAIL] Fixed container_name values are not allowed.
```

Solution: Remove the `container_name:` directive. HES uses Compose project namespacing for predictable container names.

### Validation Fails: latest Tag

```
[FAIL] Floating latest image tags are not allowed.
```

Solution: Pin the image to a specific version tag, e.g., `traefik:v3.3` instead of `traefik:latest`.

### Validation Fails: Production Placeholders

```
[FAIL] Set HES_DOMAIN before production deployment.
[FAIL] Set HES_ADMIN_EMAIL before production deployment.
```

Solution: Set real values in `.env`:

```bash
HES_DOMAIN=your-domain.com
HES_ADMIN_EMAIL=admin@your-domain.com
```

Or use development mode:

```bash
HES_ENVIRONMENT=development
```

### Traefik Cannot Discover Services

If Traefik reports no services or cannot reach the Docker API:

1. Check the socket proxy health: `make status` — the `docker-socket-proxy` container must be healthy.
2. Check proxy logs: `docker compose --project-directory . --env-file .env -f compose/compose.yml logs docker-socket-proxy`.
3. Verify `HES_TRAEFIK_DOCKER_ENDPOINT` is set to `tcp://docker-socket-proxy:2375`.
4. Verify the socket proxy is on `hes-internal` and Traefik is on both networks.

### Containers Do Not Start

1. Run `make doctor` to check the host and configuration.
2. Run `make validate` to check Compose syntax.
3. Check logs: `make logs`.
4. Verify images are pulled: the install/update scripts pull automatically, but a failed pull may leave no image.
5. Check for port conflicts: only ports 80 and 443 are published by default.

### Backup Fails

1. Verify `tar`, `cp`, and `mktemp` are available.
2. Verify `HES_BACKUP_DIR` is writable.
3. Check `logs/scripts/backup.log` for the error.
4. Verify disk space is sufficient for the archive.

### Restore Fails

1. Verify the archive path exists and ends with `.tar.gz`.
2. Verify the archive contains only allowed paths.
3. Check `logs/scripts/restore.log` for the specific rejection.
4. Do not force a restore from an untrusted archive.

## Disaster Recovery Steps

### Recovery Model

Phase 1 disaster recovery relies on repeatable infrastructure plus backup and restore:

1. Rebuild or replace the Ubuntu 24.04 host.
2. Install Docker Engine and Docker Compose V2.
3. Clone the repository.
4. Restore `.env` from a trusted backup archive.
5. Run `make restore` with the trusted archive.
6. Run `make doctor` and `make validate`.
7. Run `make install`.

### Recovery Strengths

- Infrastructure is code-driven and version-controlled.
- Configuration is externalized in `.env`.
- Backups are restorable through staged extraction with path validation.
- Scripts are idempotent and environment-aware.
- The `.hes-managed` marker system prevents accidental destruction of unmanaged directories.

### Current DR Limitation

- Recovery is host-centric, not region- or cluster-centric.
- Single-host failure is a current risk (see `DECISIONS.md`, Decision 9).

### DR Rehearsal

Regularly rehearse recovery:

```bash
# On a fresh host:
git clone https://github.com/salemhamidani/Hermes-Enterprise.git
cd Hermes-Enterprise
cp .env.example .env
# Edit .env with production values

# Restore from a trusted backup
./scripts/restore.sh /path/to/hes-backup-YYYYMMDDTHHMMSSZ.tar.gz

# Validate and start
make doctor
make validate
make install
make status
```

## Common Operational Tasks

### Check Environment Configuration

```bash
cat .env
```

Or load it through the common library:

```bash
source scripts/lib/common.sh
load_env
echo "Environment: $HES_ENVIRONMENT"
echo "Domain: $HES_DOMAIN"
echo "Project: $HES_COMPOSE_PROJECT_NAME"
```

### Render Full Compose Configuration

```bash
docker compose --project-directory . --env-file .env -f compose/compose.yml config
```

### Stop the Stack Without Removing Data

```bash
make clean
```

This runs `docker compose down --remove-orphans`, which stops and removes containers but preserves volumes, images, and runtime data.

### Recreate Runtime Directories

```bash
make repair
```

### Follow Traefik Logs Only

```bash
docker compose --project-directory . --env-file .env -f compose/compose.yml logs -f traefik
```

### Check Container Health

```bash
docker compose --project-directory . --env-file .env -f compose/compose.yml ps
```

The `STATUS` column shows health: `healthy`, `unhealthy`, or `starting`.

### List Backup Archives

```bash
ls -la backup/
```

### Verify Backup Archive Contents

```bash
tar -tzf backup/hes-backup-YYYYMMDDTHHMMSSZ.tar.gz
```

## Emergency Procedures

### Emergency Stop

To immediately stop all HES containers:

```bash
make clean
```

This is the fastest safe stop. It does not delete data.

### Emergency Data Removal

Only in cases of confirmed compromise or intentional full teardown:

```bash
HES_REMOVE_DATA=true make uninstall
```

This is destructive and irreversible. It clears all managed runtime directories (logs, backups, storage, SSL, data, workspace).

### Restore During an Incident

```bash
# Stop everything
make clean

# Restore from the last known good backup
HES_RESTORE_ARCHIVE=backup/hes-backup-<timestamp>.tar.gz make restore

# Validate and restart
make validate
make install
```

### Disk Full

If the host disk fills:

1. Stop the stack: `make clean`.
2. Prune old Docker images and build cache: `docker system prune -a`.
3. Prune old backup archives: manually delete archives older than the retention period in `backup/`.
4. Prune old script logs in `logs/scripts/`.
5. Restart: `make install`.

### Certificate Issues

If TLS certificates fail or expire:

1. Check Traefik logs for ACME errors: `docker compose --project-directory . --env-file .env -f compose/compose.yml logs traefik`.
2. Verify `HES_DOMAIN` and `HES_ADMIN_EMAIL` are correct.
3. Verify port 80 is reachable from the internet (ACME HTTP challenge).
4. If the ACME store is corrupt, clear and re-request:

   ```bash
   make clean
   rm -f ssl/letsencrypt/acme.json
   make install
   ```

   This re-requests certificates. Do not do this during peak traffic without planning.

### Socket Proxy Down

If the Docker socket proxy is unhealthy, Traefik cannot discover services:

1. Check proxy logs for errors.
2. Verify the host Docker socket exists at `/var/run/docker.sock`.
3. Verify the proxy container has read access to the socket.
4. Restart the proxy: `make install` or `docker compose ... up -d docker-socket-proxy`.
5. If the proxy cannot start, check for conflicting socket mounts or Docker daemon issues.
