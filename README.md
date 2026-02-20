# Releasea Helm Charts

Official Helm charts for installing the Releasea platform.

## Available Charts

- `releasea-platform`: full platform install (API, Console, Worker, Istio, MongoDB, RabbitMQ, MinIO, Prometheus, Loki) with feature flags.
- `releasea-worker`: standalone worker installation for remote environments.

## Quick Start

```bash
helm repo add releasea https://releasea.github.io/releasea-charts
helm repo update
helm upgrade --install releasea releasea/releasea-platform -n releasea-system --create-namespace
```

## Install with Feature Flags

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system \
  --create-namespace \
  --set istio.enabled=false \
  --set prometheus.enabled=false \
  --set loki.enabled=false
```

All components are enabled by default, including Istio, Prometheus, Loki, and Promtail.

Istio gateways start in HTTP mode by default. To enable HTTPS, use:

- `istio.https.enabled=true`
- `istio.https.secret.mode=existingSecret|selfSigned|inline`

For production, use `existingSecret` and create the TLS secret in `istio-system` before install/upgrade.

## Configure Image Tags

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system \
  --set global.imageTag=g1a2b3c4 \
  --set api.image.repository=releasea/releasea-api \
  --set console.image.repository=releasea/releasea-console \
  --set worker.image.repository=releasea/releasea-worker
```

## Standalone Worker

```bash
helm upgrade --install releasea-worker releasea/releasea-worker \
  -n releasea-system \
  --create-namespace \
  --set api.baseUrl=http://releasea-api.releasea-system.svc.cluster.local:8070/api/v1 \
  --set token=<worker-token>
```

## Automated Packaging

This repository includes `.github/workflows/release-charts.yml`.
On every push to `main`, it:

1. Builds chart dependencies.
2. Packages charts with `version=<semver without v>` and `appVersion=g<shortsha>`.
3. Creates or updates one GitHub Release containing all `.tgz` assets.
4. Generates/merges `index.yaml` at repository root (`main /`) pointing to release assets.

SemVer bump rules for chart releases (`vX.Y.Z`):

- First chart release starts at `v1.0.0`.
- `major`: commit with `BREAKING CHANGE`, `type(scope)!: ...`, or `[semver:major]`
- `minor`: commit with `feat: ...` or `[semver:minor]`
- `patch`: default for all other commits
