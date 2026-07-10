<!--
Hermes Enterprise Stack (HES)
File: ProviderGuide.md
Purpose: Operator guide for selecting Hermes providers without implementing Hermes.
-->

# Provider Guide

## Overview

HES supports a provider layer so future Hermes deployments are not tied to one fixed Docker image. Sprint 3.0 prepares provider selection only; it does not deploy Hermes.

## Provider Variables

Add these values to `.env` when provider selection is needed:

```dotenv
HERMES_PROVIDER=nous-hermes
HERMES_REGISTRY=
HERMES_IMAGE=
HERMES_VERSION=
```

Empty registry, image, and version values allow the selected provider manifest to define defaults. Explicit values override provider metadata.

## Supported Provider IDs

| Provider | Status | Notes |
| --- | --- | --- |
| `nous-hermes` | Supported reference | Official Nous Hermes Agent metadata. |
| `future-hermes` | Reserved | Requires future discovery before use. |
| `custom-hermes` | Operator-defined | Requires explicit registry, image, and version. |

## Validate Provider Selection

Run:

```bash
runtime/provider-loader.sh --validate
```

Print the resolved provider metadata:

```bash
runtime/provider-loader.sh --print
```

## Rules

- Do not use `latest` or `main` for `HERMES_VERSION`.
- Do not create provider containers in discovery or architecture sprints.
- Do not use third-party providers without explicit verification.
- Do not expose dashboard or WebUI routes until a future implementation sprint approves them.
