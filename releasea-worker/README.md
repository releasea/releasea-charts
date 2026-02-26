# releasea-worker

Standalone Helm chart for deploying Releasea worker agents into target Kubernetes clusters.

Workers execute operations on behalf of the platform: deploys, rule publication, log collection, and metric aggregation. Each worker is registered to an environment and cluster.

> **Note:** This chart is deployed **separately** from `releasea-platform`. See [Environments & Workers](https://docs.releasea.io/?doc=environments-and-workers) for registration and management details.

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Kubernetes** | Version 1.25+ |
| **Helm** | Version 3.14+ |
| **Releasea API** | Reachable from the worker cluster |
| **RabbitMQ** | Reachable from the worker cluster |
| **Worker token** | Generated from the Releasea Console |

## Install

```bash
helm repo add releasea https://releasea.github.io/releasea-charts
helm repo update

helm upgrade --install releasea-worker releasea/releasea-worker \
  -n releasea-system \
  --create-namespace \
  --set api.baseUrl=http://releasea-api.releasea-system.svc.cluster.local:8070/api/v1 \
  --set token=<worker-token>
```

## Parameters

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

## License

Apache 2.0 - See [../LICENSE](../LICENSE) for details.
