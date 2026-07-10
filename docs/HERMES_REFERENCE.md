<!--
Hermes Enterprise Stack (HES)
File: docs/HERMES_REFERENCE.md
Purpose: Verified Hermes upstream reference for Sprint 2.5 discovery.
-->

# Hermes Reference

## Discovery Status

This document records verified discovery findings for the Hermes implementation that HES must support later. It does not implement Hermes and does not authorize creating `compose/hermes.yml` yet.

## Existing HES References

The current HES repository references Hermes as a future service family, but it does not fully identify the upstream implementation.

Verified local findings:

- `README.md` describes HES as infrastructure for future Hermes services.
- `ARCHITECTURE.md` reserves future modules such as `compose/hermes-api.yml` and `compose/hermes-worker.yml`.
- `ROADMAP.md` places the Core Hermes Service Plane in a later milestone.
- ADR documents explicitly keep Hermes application services out of the current infrastructure phase.
- No current Compose file, environment file, script, or documentation pins an official Hermes repository, registry, image tag, or runtime contract.

## Project Name

- Official project name: Hermes Agent
- Package name: `hermes-agent`
- Vendor/owner: Nous Research
- Description: The agent that grows with you

## Official Repository

- GitHub repository: [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
- Default branch: `main`
- Repository status at discovery time: active, public, not archived, not a fork
- Repository topics include `hermes`, `hermes-agent`, `ai-agent`, `openai`, `codex`, and `nous-research`.

## Official Documentation

- Documentation site: [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com)
- Documentation index: [hermes-agent.nousresearch.com/docs](https://hermes-agent.nousresearch.com/docs)
- PyPI package: [pypi.org/project/hermes-agent](https://pypi.org/project/hermes-agent/)
- Installation entrypoint documented upstream: `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash`

## Official Docker Images

For the `nous-hermes` provider, the official upstream Docker workflow publishes to Docker Hub with the image name `nousresearch/hermes-agent`.

Verified image source:

- Upstream workflow: `.github/workflows/docker.yml`
- Workflow variable: `IMAGE_NAME: nousresearch/hermes-agent`
- Registry login: Docker Hub via `docker/login-action`
- Push trigger: `main` branch pushes and GitHub releases

## Container Registry

- Official registry: Docker Hub
- Official registry path: [hub.docker.com/r/nousresearch/hermes-agent](https://hub.docker.com/r/nousresearch/hermes-agent)
- No official GHCR image was verified during Sprint 2.5 discovery.

## Supported Images

These image findings apply to the `nous-hermes` provider only. HES architecture must still select a provider through the provider layer before implementation.

| Purpose | Official image | Status |
| --- | --- | --- |
| Hermes Agent runtime | `nousresearch/hermes-agent` | Verified official image |
| Hermes gateway | `nousresearch/hermes-agent` with gateway command | Verified from upstream Compose |
| Hermes dashboard | `nousresearch/hermes-agent` with dashboard command | Verified from upstream Compose |
| Separate Hermes WebUI image | Not verified | Do not use without new discovery |
| Third-party WebUI projects | Not official for HES | Do not pin in HES |

The upstream repository includes a `docker-compose.yml` that builds or uses a local `hermes-agent` image and starts `gateway` and `dashboard` services. That Compose file is not directly HES-compliant because it uses `container_name` and `network_mode: host`, which conflict with HES Compose standards. Future implementation must adapt the upstream runtime contract into HES standards instead of copying the upstream Compose file verbatim.

## Tags

Verified Docker Hub tags at discovery time include:

- `latest`
- `main`
- `v2026.7.7.2`
- `v2026.7.7`
- `v2026.7.1`
- `v2026.6.19`
- `v2026.6.5`
- Earlier CalVer release tags

Recommended production tag for a future `nous-hermes` implementation:

- `nousresearch/hermes-agent:v2026.7.7.2`

Verified multi-arch digest for `v2026.7.7.2` at discovery time:

```text
nousresearch/hermes-agent:v2026.7.7.2@sha256:9c841866021c54c4596849f6135717e8a4d52ba510b7f52c50aef1de1a283973
```

Platform digests observed for `v2026.7.7.2`:

| Platform | Digest |
| --- | --- |
| `linux/amd64` | `sha256:3db34ce19adfa080736a2a3feb0316dbcccc588faa9afe7fd8ae1c03b4f1a53a` |
| `linux/arm64` | `sha256:47d4bd4cc420b70e40ed75efdade373e45b86b7382d4013a054208982bb6ba08` |

## Version Strategy

Sprint 3.0 supersedes any global fixed-image assumption with a provider layer. The version strategy below applies to the `nous-hermes` provider metadata unless another provider is selected.

Hermes Agent uses two parallel version identifiers:

- Package SemVer: `0.18.2` in `pyproject.toml` and PyPI.
- Release CalVer tags: `vYYYY.M.D` with numeric suffixes for same-day patch releases, such as `v2026.7.7.2`.

HES must pin provider versions by immutable release tag or equivalent provider version at minimum. Digest pinning should be used for production container providers once the implementation sprint begins.

## Release Policy

Verified upstream release mechanics:

- Releases are generated by `scripts/release.py`.
- The script creates GitHub releases with CalVer tags.
- The script can bump SemVer components: `major`, `minor`, or `patch`.
- The Docker workflow publishes `main` and `latest` tags on main branch pushes.
- The Docker workflow publishes release tags on GitHub release events.
- PyPI publishing is triggered for CalVer tag pushes matching `v20*`.

Latest stable release discovered:

| Field | Value |
| --- | --- |
| GitHub release | Hermes Agent v0.18.2 (2026.7.7.2) |
| Git tag | `v2026.7.7.2` |
| PyPI version | `0.18.2` |
| Published | 2026-07-08 |

Long-term support status:

- No official LTS channel or LTS version was verified.
- HES must not invent an LTS tag or support window.

## Breaking Changes

No formal upstream breaking-change policy was verified during Sprint 2.5. Treat all upstream major or minor SemVer bumps, Dockerfile supervision changes, command changes, network behavior changes, and dashboard exposure changes as potentially breaking until reviewed.

Future HES upgrade reviews must inspect:

- GitHub release notes.
- Docker workflow changes.
- `Dockerfile` entrypoint and user/volume behavior.
- `docker-compose.yml` command and environment changes.
- `pyproject.toml` version and Python compatibility.
- Security advisories and upstream `SECURITY.md`.

## Known Limitations

- The official upstream Compose file is not directly HES-compliant.
- The official dashboard defaults to localhost-only exposure and warns against unauthenticated remote access.
- A separate official WebUI image was not verified.
- The official image is large and includes multiple runtime dependencies.
- HES has not implemented Hermes services yet; this file is reference-only.
- Any third-party `hermes-webui`, `hermes-dashboard`, or suite image must be treated as untrusted until explicitly approved by a future discovery sprint.
