<!--
Hermes Enterprise Stack (HES)
File: docs/BACKUP_RESTORE.md
Purpose: Document backup and restore procedures for Phase 1 infrastructure.
-->

# Backup and Restore

## Backup

```bash
make backup
```

The backup script creates a timestamped `.tar.gz` archive in `HES_BACKUP_DIR`, which defaults to `backup/`.

Included paths:

- `.env`
- `compose/`
- `config/`
- `ssl/`
- `storage/`
- `data/`

Old backups are removed based on `HES_BACKUP_RETENTION_DAYS`. Backup archives are written with owner-only permissions because `.env` is included.

## Restore

Use either an environment variable:

```bash
HES_RESTORE_ARCHIVE=backup/hes-backup-20260709T000000Z.tar.gz make restore
```

Or call the script directly with an archive path:

```bash
./scripts/restore.sh backup/hes-backup-20260709T000000Z.tar.gz
```

Restore stops running containers when Docker Compose is available, validates archive paths before extraction, restores the project Compose/config files, repairs expected directories, and validates Compose configuration when Docker Compose is available.

Only restore archives from trusted sources.
