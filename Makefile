# Hermes Enterprise Stack (HES)
# File: Makefile
# Purpose: Provide stable operator entrypoints for Phase 1 infrastructure tasks.

SHELL := /bin/bash

.PHONY: install doctor validate repair update backup restore logs status clean uninstall

install:
	./scripts/install.sh

doctor:
	./scripts/doctor.sh

validate:
	./scripts/validate.sh

repair:
	./scripts/repair.sh

update:
	./scripts/update.sh

backup:
	./scripts/backup.sh

restore:
	./scripts/restore.sh

logs:
	docker compose --project-directory . --env-file .env -f compose/compose.yml logs --tail=200 -f

status:
	docker compose --project-directory . --env-file .env -f compose/compose.yml ps

clean:
	docker compose --project-directory . --env-file .env -f compose/compose.yml down --remove-orphans

uninstall:
	./scripts/uninstall.sh
