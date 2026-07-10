<!--
Hermes Enterprise Stack (HES)
File: secrets/README.md
Purpose: Document local Docker Secrets preparation without committing secret values.
-->

# Docker Secrets

This directory is reserved for local Docker Secrets source files.

Do not commit secret values. Files in this directory are ignored by Git except this README and `.gitkeep`.

Future services may reference Docker secrets through Compose using file-backed secrets. Secret file names must be documented, environment-independent, and reviewed before use.

Current Sprint 2 status: no Hermes, database, monitoring, or dashboard service consumes secrets yet.
