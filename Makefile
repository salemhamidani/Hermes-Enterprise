# Hermes Enterprise Stack (HES)
# File: Makefile
# Purpose: Provide stable operator entrypoints for Phase 1 infrastructure tasks.

SHELL := /bin/bash

.PHONY: install doctor validate repair update backup restore logs status restart clean uninstall security-scan compose-validate

install:
	./scripts/compose-up.sh

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
	./scripts/compose-up.sh -- logs --tail=200 -f

status:
	./scripts/compose-up.sh -- ps

restart:
	./scripts/compose-restart.sh

clean:
	./scripts/compose-down.sh

uninstall:
	./scripts/uninstall.sh

security-scan:
	./scripts/security-scan.sh

compose-validate:
	./scripts/compose-validate.sh
