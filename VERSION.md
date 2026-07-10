<!--
Hermes Enterprise Stack (HES)
File: VERSION.md
Purpose: Document the current version, semantic versioning policy, version history, and bumping rules.
-->

# Versioning

## Current Version

```
1.0.0
```

The canonical version of Hermes Enterprise Stack lives in the `VERSION` file at the repository root. This file contains only the version string and a trailing newline. No other content may be added to it.

The version is the single source of truth for the current release state of the project. It is read by release tooling, CI workflows, and documentation generators.

## Semantic Versioning 2.0.0

HES follows [Semantic Versioning 2.0.0](https://semver.org/). Every version has the form:

```
MAJOR.MINOR.PATCH
```

Given a version number MAJOR.MINOR.PATCH, increment the:

- **MAJOR** version when you make **incompatible API changes**. For HES this means breaking changes to the Compose module contract, network contract, script CLI, or configuration variable contract that require operators to change their workflow, `.env`, or Compose includes.
- **MINOR** version when you add functionality in a **backward-compatible** manner. For HES this means new Compose modules, new lifecycle script targets, new optional `.env` variables, new services, or new documentation that does not break existing operator workflows.
- **PATCH** version when you make **backward-compatible bug fixes**. For HES this means fixes to scripts, configuration, documentation, or Compose files that do not change the documented operator contract or add new functionality.

### Pre-release Identifiers

Pre-release versions append a hyphen and a series of dot-separated identifiers after the patch number:

```
1.0.0-alpha.1
1.0.0-beta.2
1.0.0-rc.1
```

Pre-release identifiers follow the precedence defined by SemVer 2.0.0: `alpha` < `beta` < `rc` < release. Pre-release versions have lower precedence than the associated normal version.

### Build Metadata

Build metadata may be appended with a plus sign:

```
1.0.0+20260710
```

Build metadata does not affect version precedence.

### Precedence Rules

1. Precedence is calculated by comparing MAJOR, then MINOR, then PATCH.
2. When equal, a pre-release version has lower precedence than a normal version.
3. Pre-release identifiers are compared field by field: numeric identifiers compared numerically, alphanumeric identifiers compared lexically in ASCII order.

## Version History

| Version | Date | Notes |
| --- | --- | --- |
| 0.1.0 | 2026-07-09 | Initial Phase 1 infrastructure foundation. Modular Compose, Traefik ingress, Docker socket proxy, lifecycle scripts, backup/restore, production-oriented documentation. |
| 1.0.0 | 2026-07-10 | Phase 1 stable release. Infrastructure contract frozen. Versioning, architecture diagrams, ADRs, and quality gates formalized. |

Future versions must be added to this table as part of the release workflow described in `docs/ReleaseStrategy.md`.

## How to Bump Versions

### Who Can Bump

Only a maintainer may bump the version. Version bumps happen during the release workflow, never on feature or hotfix branches.

### Bump Steps

1. Confirm the target bump level (major, minor, or patch) based on the change set merged into `develop` since the last release. See the bump rules below.
2. Update the `VERSION` file to the new version string with a single trailing newline.
3. Add a new entry to the Version History table in this file.
4. Update `CHANGELOG.md` with the new version section.
5. Create and push a git tag using the tag format below.
6. Publish the GitHub Release referencing the tag.

### Version Bump Rules

| Change merged into `develop` | Bump |
| --- | --- |
| Breaking change to Compose module contract, network contract, script CLI, or required `.env` variables | **MAJOR** |
| New Compose module, new script target, new optional `.env` variable, new service, or new non-breaking feature | **MINOR** |
| Bug fix, documentation fix, configuration fix, or Compose fix that does not change the operator contract | **PATCH** |

When in doubt, choose the lower bump and document the rationale in the release PR.

## Tag Format

Git tags follow the format:

```
vX.Y.Z
```

Examples:

- `v0.1.0`
- `v1.0.0`
- `v1.1.0`
- `v1.1.1`

Pre-release tags:

- `v1.1.0-alpha.1`
- `v1.1.0-beta.1`
- `v1.1.0-rc.1`

Tags are **annotated** git tags, created and pushed as part of the release workflow. See `docs/ReleaseStrategy.md` for the full release procedure.

## Compatibility Promise

Starting with `1.0.0`, HES guarantees backward compatibility within the same major version:

- Minor and patch releases never break the operator contract.
- Major releases are announced in advance and documented in `DECISIONS.md` and the relevant ADRs.
- Deprecation of any contract requires at least one minor release of notice before removal in a major release.
