<!--
Hermes Enterprise Stack (HES)
File: docs/ReleaseStrategy.md
Purpose: Define the full release workflow, hotfix workflow, pre-release workflow, release checklist, and version bump rules.
-->

# Release Strategy

This document defines how Hermes Enterprise Stack ships releases. It covers the standard release workflow, hotfix workflow, pre-release workflow, the release checklist, and the version bump rules that govern each release.

All release activity follows [Semantic Versioning 2.0.0](https://semver.org/) as described in `VERSION.md`. The current version lives in the `VERSION` file at the repository root.

## Branch Model

HES uses a `main` / `develop` branching model:

| Branch | Role |
| --- | --- |
| `main` | Always reflects the latest stable release. Every commit on `main` is a release. Only release and hotfix PRs may merge here. |
| `develop` | Integration branch for the next release. Feature branches merge here. Reflects the latest delivered development state. |
| `feature/*` | Short-lived branches for new work. Merge into `develop`. |
| `release/*` | Short-lived branches that prepare a release. Merge into both `main` and `develop`. |
| `hotfix/*` | Short-lived branches for urgent fixes on `main`. Merge into both `main` and `develop`. |

## Standard Release Workflow

The standard release path goes from `develop` to `main` to a git tag to a GitHub Release.

### 1. Cut a Release Branch

A maintainer cuts a release branch from `develop`:

```bash
git checkout develop
git pull origin develop
git checkout -b release/vX.Y.Z
```

The version `X.Y.Z` is determined using the version bump rules at the end of this document.

### 2. Prepare the Release

On the release branch, update version artifacts:

1. Set the new version in `VERSION` (version string plus trailing newline only).
2. Add a new row to the Version History table in `VERSION.md`.
3. Add a new `## [X.Y.Z] - YYYY-MM-DD` section to `CHANGELOG.md` with Added, Changed, Fixed, and Removed subsections as applicable.
4. Commit with message `release: vX.Y.Z`.

Do not add new features on the release branch. Only version metadata, changelog, and release-specific documentation adjustments belong here.

### 3. Validate

Run the full quality gate on the release branch:

```bash
make validate
make doctor
make backup
```

All CI checks must be green on the release branch before proceeding. See `QUALITY_GATE.md` for the full gate definition.

### 4. Merge to main

Open a PR from `release/vX.Y.Z` targeting `main`. Title it `Release vX.Y.Z`. After review and approval, merge it.

### 5. Tag and Publish

After the merge to `main`, create and push an annotated tag:

```bash
git checkout main
git pull origin main
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

The pushed tag triggers the GitHub Release workflow automatically, producing a GitHub Release with release notes generated from `CHANGELOG.md`.

### 6. Back-merge to develop

Merge `main` back into `develop` so the version metadata and changelog land on the integration branch:

```bash
git checkout develop
git merge main
git push origin develop
git branch -d release/vX.Y.Z
```

### Standard Release Flow Diagram

```text
develop --> release/vX.Y.Z --> main --> tag vX.Y.Z --> GitHub Release
                                 |
                                 +----> back-merge --> develop
```

## Hotfix Workflow

Hotfixes address urgent issues on the current stable release. They branch from `main`, not `develop`.

### 1. Cut a Hotfix Branch

```bash
git checkout main
git pull origin main
git checkout -b hotfix/vX.Y.Z
```

The hotfix version is a **patch** bump from the current `main` version. For example, if `main` is at `v1.0.0`, the hotfix is `v1.0.1`.

### 2. Fix and Prepare

Apply the minimal fix on the hotfix branch. Then update version artifacts:

1. Bump `VERSION` to the patch version.
2. Add the hotfix row to the Version History table in `VERSION.md`.
3. Add a `## [X.Y.Z] - YYYY-MM-DD` section to `CHANGELOG.md` describing the fix under Fixed.
4. Commit with message `hotfix: vX.Y.Z`.

### 3. Validate

Run the full quality gate on the hotfix branch. All CI checks must be green.

### 4. Merge to main

Open a PR from `hotfix/vX.Y.Z` targeting `main`. After review and approval, merge it.

### 5. Tag and Publish

```bash
git checkout main
git pull origin main
git tag -a vX.Y.Z -m "Hotfix vX.Y.Z"
git push origin vX.Y.Z
```

The tag triggers the GitHub Release workflow.

### 6. Back-merge to develop

Merge `main` back into `develop` so the hotfix reaches the integration branch:

```bash
git checkout develop
git merge main
git push origin develop
git branch -d hotfix/vX.Y.Z
```

### Hotfix Flow Diagram

```text
main --> hotfix/vX.Y.Z --> main --> tag vX.Y.Z --> GitHub Release
                                 |
                                 +----> back-merge --> develop
```

## Pre-release Workflow

Pre-releases allow operators to test upcoming versions before the final release. Pre-release versions use SemVer pre-release identifiers: `alpha`, `beta`, and `rc`.

### Pre-release Identifier Progression

| Stage | Identifier | Purpose |
| --- | --- | --- |
| Alpha | `alpha.N` | Early internal testing. APIs and contracts may still change. Not for production use. |
| Beta | `beta.N` | Feature-complete. APIs and contracts are frozen pending final validation. Limited external testing. |
| Release Candidate | `rc.N` | Final candidate. No new features. Only blocking bug fixes before promotion to the final release. |

Pre-release precedence is `alpha` < `beta` < `rc` < final release, as defined by SemVer 2.0.0.

### 1. Cut a Pre-release Branch

A maintainer cuts a release branch from `develop`, same as the standard release workflow:

```bash
git checkout develop
git pull origin develop
git checkout -b release/vX.Y.Z
```

### 2. Prepare the Pre-release

On the release branch, set the pre-release version:

1. Set `VERSION` to `X.Y.Z-alpha.1` (or `beta.1`, `rc.1` as appropriate).
2. Add the pre-release row to the Version History table in `VERSION.md`.
3. Add a `## [X.Y.Z-alpha.1] - YYYY-MM-DD` section to `CHANGELOG.md`.
4. Commit with message `release: vX.Y.Z-alpha.1`.

### 3. Validate

Run the full quality gate on the release branch. All CI checks must be green.

### 4. Merge to main and Tag

Open a PR from `release/vX.Y.Z` targeting `main`. After approval, merge and tag:

```bash
git checkout main
git pull origin main
git tag -a vX.Y.Z-alpha.1 -m "Pre-release vX.Y.Z-alpha.1"
git push origin vX.Y.Z-alpha.1
```

### 5. Publish as a Pre-release

The GitHub Release workflow should mark the release as a **pre-release** (not latest). Pre-release releases are opt-in for operators.

### 6. Iterate

To publish the next pre-release stage, repeat the prepare and tag steps with the next identifier (`beta.1`, then `rc.1`, incrementing `N` for additional iterations within a stage):

```bash
git tag -a vX.Y.Z-beta.1 -m "Pre-release vX.Y.Z-beta.1"
git push origin vX.Y.Z-beta.1
```

### 7. Promote to Final Release

When a release candidate is validated, promote it to the final release:

1. Update `VERSION` to the plain `X.Y.Z` (drop the pre-release identifier).
2. Update the Version History table in `VERSION.md` with the final release row.
3. Update `CHANGELOG.md` with the final `## [X.Y.Z] - YYYY-MM-DD` section.
4. Commit with message `release: vX.Y.Z`.
5. Merge to `main`, tag `vX.Y.Z`, and publish the final GitHub Release as the latest.
6. Back-merge `main` into `develop`.

### Pre-release Flow Diagram

```text
develop --> release/vX.Y.Z
                 |
                 +-> vX.Y.Z-alpha.1 --> GitHub Release (pre-release)
                 +-> vX.Y.Z-beta.1  --> GitHub Release (pre-release)
                 +-> vX.Y.Z-rc.1    --> GitHub Release (pre-release)
                 +-> vX.Y.Z         --> GitHub Release (latest)
                          |
                          +-> back-merge --> develop
```

## Release Checklist

Every release, hotfix, and pre-release must satisfy this checklist before the tag is pushed.

### Version Artifacts

- [ ] `VERSION` file updated to the target version with a single trailing newline.
- [ ] `VERSION.md` Version History table has the new row.
- [ ] `CHANGELOG.md` has the new version section with appropriate subsections.

### Validation

- [ ] `make validate` passes on Ubuntu 24.04 LTS with Docker Compose V2.
- [ ] `make doctor` passes.
- [ ] `make backup` creates a valid restricted archive.
- [ ] `make restore` restores from a valid archive.
- [ ] All CI checks are green on the release branch.

### Compose Policy

- [ ] No `container_name` in any Compose file.
- [ ] No `latest` image tags.
- [ ] No deprecated `version` key in any Compose file.
- [ ] Health checks present for long-running services.
- [ ] Log rotation present for long-running services.
- [ ] All services and networks have `com.hermes.*` labels.

### Documentation

- [ ] Documentation matches implementation (no aspirational docs).
- [ ] `DECISIONS.md` updated if an architectural decision was made.
- [ ] ADR added or updated if a decision record changed.
- [ ] Diagrams in `docs/assets/` are current if architecture changed.

### Security

- [ ] No secrets committed.
- [ ] No `.env` committed.
- [ ] Docker socket proxy permissions remain minimal.
- [ ] No new attack surface introduced.

### Git

- [ ] Release or hotfix branch follows naming conventions.
- [ ] PR targets the correct base branch (`main` for release/hotfix).
- [ ] PR is reviewed and approved.
- [ ] Tag is annotated and named `vX.Y.Z` (or `vX.Y.Z-alpha.N` for pre-releases).
- [ ] Tag is pushed.
- [ ] `main` is back-merged into `develop`.
- [ ] Release or hotfix branch is deleted after merge.

## Version Bump Rules

The bump level is determined by the change set merged into `develop` since the last release.

### Major (X.0.0)

A major bump is required when the release contains a **breaking change**:

- Breaking change to the Compose module contract (renamed or removed modules, changed include paths).
- Breaking change to the network contract (renamed or restructured networks).
- Breaking change to a lifecycle script CLI (removed or renamed targets, changed argument semantics).
- Removal or rename of a required `.env` variable.
- Removal of a documented operator workflow without a replacement.

Major releases must be announced in advance, documented in `DECISIONS.md`, and accompanied by a migration guide.

### Minor (X.Y.0)

A minor bump is required when the release adds **backward-compatible functionality**:

- New Compose module added.
- New lifecycle script target added.
- New optional `.env` variable added.
- New service or infrastructure component added.
- New documentation section that does not change the operator contract.
- Deprecation notice added for a future major removal.

Minor releases never break existing operator workflows.

### Patch (X.Y.Z)

A patch bump is required when the release contains only **backward-compatible fixes**:

- Bug fix in a lifecycle script.
- Fix in a Compose file that does not change the documented contract.
- Documentation fix.
- Configuration fix.
- Dependency image pin update for a security fix.

### Decision Guidance

- When a release contains both new features and fixes, bump **minor**.
- When a release contains only fixes, bump **patch**.
- When a release contains any breaking change, bump **major** regardless of other changes.
- When in doubt, choose the lower bump and document the rationale in the release PR.
