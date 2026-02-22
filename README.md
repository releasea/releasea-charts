# Releasea Helm Charts

Official Helm charts for installing the Releasea platform.

## Available Charts

| Chart | Description | Docs |
|-------|-------------|------|
| [**releasea-platform**](./releasea-platform/) | API, Console, MongoDB, RabbitMQ, MinIO, Prometheus, Loki | [README](./releasea-platform/README.md) |
| [**releasea-worker**](./releasea-worker/) | Standalone worker agent for remote clusters | [README](./releasea-worker/README.md) |

> **Important:** These are **independent charts**. The platform chart does **not** include the worker. Workers are deployed separately into each target cluster using `releasea-worker`.

> For the full installation guide, see the [Platform Installation Guide](https://docs.releasea.io/?doc=installation).

## Quick Start

### Platform

```bash
helm repo add releasea https://releasea.github.io/releasea-charts
helm repo update

helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system --create-namespace
```

All components are enabled by default. See [releasea-platform/README.md](./releasea-platform/README.md) for the full list of supported parameters.

### Worker

```bash
helm upgrade --install releasea-worker releasea/releasea-worker \
  -n releasea-system --create-namespace \
  --set api.baseUrl=http://releasea-api.releasea-system.svc.cluster.local:8070/api/v1 \
  --set token=<worker-token>
```

See [releasea-worker/README.md](./releasea-worker/README.md) for the full list of supported parameters.

## Prerequisites

| Requirement | Applies To | Details |
|-------------|------------|---------|
| **Kubernetes** | Both charts | Version 1.25+ |
| **Helm** | Both charts | Version 3.14+ |
| **Istio** | Platform only | Installed separately as cluster-level prerequisite |
| **Releasea API** | Worker only | Reachable from the worker cluster |
| **Worker token** | Worker only | Generated from the Releasea Console |

## Automated Packaging

This repository includes `.github/workflows/release-charts.yml`.
On every push to `main`, it:

1. Builds chart dependencies.
2. Packages charts with `version=<semver without v>` and `appVersion=g<shortsha>`.
3. Creates or updates one GitHub Release containing all `.tgz` assets.
4. Generates/merges `index.yaml` at repository root (`main /`) pointing to release assets.

SemVer bump rules for chart releases (`vX.Y.Z`):

| Bump | Trigger |
|------|---------|
| `major` | Commit with `BREAKING CHANGE`, `type(scope)!: ...`, or `[semver:major]` |
| `minor` | Commit with `feat: ...` or `[semver:minor]` |
| `patch` | Default for all other commits |

First chart release starts at `v1.0.0`.
