# Releasea Helm Charts

Official Helm charts for installing the Releasea platform.

## Available Charts

| Chart | Description |
|-------|-------------|
| **releasea-platform** | Full platform install (API, Console, MongoDB, RabbitMQ, MinIO, Prometheus, Loki) |
| **releasea-worker** | Standalone worker agent for remote clusters and environments |

> For the full installation guide, see the [Platform Installation Guide](https://docs.releasea.io/?doc=installation).

## Quick Start

```bash
helm repo add releasea https://releasea.github.io/releasea-charts
helm repo update
helm upgrade --install releasea releasea/releasea-platform -n releasea-system --create-namespace
```

## releasea-platform Parameters

### Global

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageTag` | Image tag applied to all components | `latest` |
| `global.imagePullPolicy` | Image pull policy | `IfNotPresent` |

### API

| Parameter | Description | Default |
|-----------|-------------|---------|
| `api.enabled` | Enable the API server | `true` |
| `api.replicaCount` | Number of API replicas | `1` |
| `api.image.repository` | API image repository | `releasea/releasea-api` |
| `api.image.tag` | API image tag (overrides `global.imageTag`) | `""` |
| `api.service.type` | API service type | `ClusterIP` |
| `api.service.port` | API service port | `8070` |
| `api.env.PORT` | Port the API listens on | `"8070"` |
| `api.env.MONGO_URI` | MongoDB connection string | `mongodb://releasea-mongodb:27017/releasea` |
| `api.env.RABBITMQ_URL` | RabbitMQ connection string | `amqp://releasea:releasea@releasea-rabbitmq:5672/` |

### Console

| Parameter | Description | Default |
|-----------|-------------|---------|
| `console.enabled` | Enable the Console UI | `true` |
| `console.replicaCount` | Number of Console replicas | `1` |
| `console.image.repository` | Console image repository | `releasea/releasea-console` |
| `console.image.tag` | Console image tag (overrides `global.imageTag`) | `""` |
| `console.service.type` | Console service type | `ClusterIP` |
| `console.service.port` | Console service port | `8080` |
| `console.ingress.enabled` | Enable Ingress for the Console | `false` |
| `console.ingress.className` | Ingress class name | `""` |
| `console.ingress.host` | Ingress hostname | `""` |
| `console.ingress.path` | Ingress path | `/` |

### MongoDB

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mongodb.enabled` | Enable MongoDB | `true` |
| `mongodb.image` | MongoDB image | `mongo:7` |
| `mongodb.service.port` | MongoDB service port | `27017` |
| `mongodb.persistence.enabled` | Enable persistent storage | `true` |
| `mongodb.persistence.size` | PVC size | `8Gi` |

### RabbitMQ

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rabbitmq.enabled` | Enable RabbitMQ | `true` |
| `rabbitmq.image` | RabbitMQ image | `rabbitmq:3.13-management` |
| `rabbitmq.service.amqpPort` | AMQP port | `5672` |
| `rabbitmq.service.managementPort` | Management UI port | `15672` |
| `rabbitmq.auth.username` | RabbitMQ username | `releasea` |
| `rabbitmq.auth.password` | RabbitMQ password | `releasea` |

### MinIO

| Parameter | Description | Default |
|-----------|-------------|---------|
| `minio.enabled` | Enable MinIO | `true` |
| `minio.image` | MinIO image | `minio/minio:latest` |
| `minio.service.apiPort` | S3-compatible API port | `9000` |
| `minio.service.consolePort` | MinIO Console port | `9001` |
| `minio.accessKey` | MinIO access key | `releasea` |
| `minio.secretKey` | MinIO secret key | `releaseaadmin` |
| `minio.bucket` | Default bucket name | `releasea-static` |
| `minio.persistence.enabled` | Enable persistent storage | `true` |
| `minio.persistence.size` | PVC size | `10Gi` |

### Prometheus

| Parameter | Description | Default |
|-----------|-------------|---------|
| `prometheus.enabled` | Enable Prometheus | `true` |
| `prometheus.image` | Prometheus image | `prom/prometheus:v2.55.1` |
| `prometheus.retention` | Data retention period | `6h` |
| `prometheus.scrapeInterval` | Scrape interval | `30s` |
| `prometheus.evaluationInterval` | Rule evaluation interval | `30s` |
| `prometheus.service.port` | Prometheus service port | `9090` |
| `prometheus.resources` | CPU/memory resource limits | `{}` |

### Loki

| Parameter | Description | Default |
|-----------|-------------|---------|
| `loki.enabled` | Enable Loki | `true` |
| `loki.isDefault` | Set as default log store | `true` |
| `loki.image` | Loki image | `grafana/loki:3.1.1` |
| `loki.persistence.enabled` | Enable persistent storage | `false` |
| `loki.persistence.size` | PVC size | `10Gi` |
| `loki.service.port` | Loki service port | `3100` |
| `loki.promtail.enabled` | Enable Promtail log collector | `true` |
| `loki.promtail.image` | Promtail image | `grafana/promtail:3.1.1` |
| `loki.grafana.enabled` | Enable Grafana | `false` |
| `loki.resources` | CPU/memory resource limits | `{}` |

---

## releasea-worker Parameters

### Core

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of worker replicas | `1` |
| `image.repository` | Worker image repository | `releasea/releasea-worker` |
| `image.tag` | Worker image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `token` | Worker registration token | `""` |
| `environment` | Target environment | `prod` |
| `namespacePrefix` | Namespace prefix for app workloads | `releasea-apps` |
| `tags` | Comma-separated worker tags | `""` |
| `cluster` | Cluster identifier | `k3d-local` |

### Worker Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `worker.id` | Worker unique ID | `""` |
| `worker.name` | Worker display name | `releasea-worker` |
| `worker.environment` | Environment override | `""` |
| `worker.namespace` | Namespace override | `""` |
| `worker.token` | Token override | `""` |
| `worker.version` | Worker version label | `""` |
| `worker.heartbeatSeconds` | Heartbeat interval in seconds | `30` |
| `worker.queueName` | RabbitMQ queue name | `releasea.worker` |
| `worker.extraEnv` | Additional environment variables | `[]` |
| `worker.dockerBuildNetwork` | Docker build network mode | `host` |

### Connectivity

| Parameter | Description | Default |
|-----------|-------------|---------|
| `api.baseUrl` | Releasea API base URL | `http://host.k3d.internal:8070/api/v1` |
| `rabbitmq.url` | RabbitMQ connection string | `amqp://releasea:releasea@releasea-rabbitmq.releasea-system.svc.cluster.local:5672/` |

### Routing

| Parameter | Description | Default |
|-----------|-------------|---------|
| `routing.internalDomain` | Internal service domain | `releasea.internal` |
| `routing.externalDomain` | External service domain | `releasea.external` |
| `routing.internalGateway` | Istio internal gateway ref | `istio-system/releasea-internal-gateway` |
| `routing.externalGateway` | Istio external gateway ref | `istio-system/releasea-external-gateway` |

### MinIO (Static Site Builds)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `minio.endpoint` | MinIO endpoint | `releasea-minio.releasea-system.svc.cluster.local:9000` |
| `minio.accessKey` | MinIO access key | `releasea` |
| `minio.secretKey` | MinIO secret key | `releaseaadmin` |
| `minio.bucket` | Bucket for static site builds | `releasea-static` |
| `minio.secure` | Use HTTPS for MinIO | `false` |

### Static Site

| Parameter | Description | Default |
|-----------|-------------|---------|
| `staticSite.prefix` | Object key prefix for sites | `sites` |
| `staticSite.nginxService` | Static nginx service name | `releasea-static-nginx` |
| `staticSite.nginxNamespace` | Static nginx namespace | `releasea-system` |

### Infrastructure

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources` | CPU/memory resource limits | `{}` |
| `securityContext` | Pod security context | `{}` |
| `nodeSelector` | Node selector labels | `{}` |
| `tolerations` | Pod tolerations | `[]` |
| `affinity` | Pod affinity rules | `{}` |
| `hostAliases` | Host aliases for the pod | `[]` |
| `serviceAccount.create` | Create a service account | `true` |
| `serviceAccount.name` | Service account name | `""` |
| `rbac.create` | Create RBAC resources | `true` |
| `rbac.clusterAdmin` | Grant cluster-admin role | `true` |
| `rbac.rules` | Custom RBAC rules | `[]` |

### Docker-in-Docker Sidecar

| Parameter | Description | Default |
|-----------|-------------|---------|
| `dockerDinD.enabled` | Enable DinD sidecar for builds | `true` |
| `dockerDinD.image` | DinD image | `docker:28.2.2-dind` |
| `dockerDinD.pullPolicy` | Image pull policy | `IfNotPresent` |
| `dockerDinD.args` | Extra daemon arguments | See `values.yaml` |
| `dockerDinD.env` | Extra environment variables | See `values.yaml` |
| `dockerDinD.resources` | CPU/memory resource limits | `{}` |
| `dockerDinD.workerDockerHost` | Docker host URI for the worker | `tcp://localhost:2375` |

---

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
