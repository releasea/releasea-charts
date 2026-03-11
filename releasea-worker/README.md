# Worker Chart Setup

Deploy Releasea workers in target clusters with `releasea-worker`.
Workers execute deploy and operations jobs for a specific environment.

> **Note:** This chart is deployed **separately** from `releasea-platform`. See [Environments & Workers](https://docs.releasea.io/?doc=environments-and-workers) for registration and management details.

## Requirements

| Requirement | Details |
|-------------|---------|
| **Kubernetes** | Version 1.25+ |
| **Helm** | Version 3.14+ |
| **Releasea API** | Reachable from the worker cluster |
| **RabbitMQ** | Reachable from the worker cluster |
| **Worker token** | Generated from the Releasea Console |

## Base Setup (Required)

### 1. Register a worker in Releasea Console

1. Go to `Workers -> Register Worker`.
2. Fill worker name, environment, tags, cluster, and namespace prefix.
3. Copy the generated token.

### 2. Install chart in target cluster

```bash
helm repo add releasea https://releasea.github.io/releasea-charts
helm repo update

helm upgrade --install releasea-worker releasea/releasea-worker \
  --set token=<worker-token> \
  --set environment=prod \
  --set tags=prod,build \
  --set worker.name=prod-worker
```

### 3. Advanced mode (remote/custom cluster only)

Use explicit overrides only when worker cannot read shared bootstrap config from the platform namespace:

```bash
helm upgrade --install releasea-worker releasea/releasea-worker \
  --set token=<worker-token> \
  --set environment=prod \
  --set tags=prod,build \
  --set worker.name=prod-worker \
  --set bootstrap.mode=external \
  --set-string install.namespace=releasea-system \
  --set namespacePrefix=releasea-apps \
  --set-string api.baseUrl=http://releasea-api.releasea-system.svc.cluster.local:8070/api/v1 \
  --set-string rabbitmq.url=amqp://releasea:releasea@releasea-rabbitmq.releasea-system.svc.cluster.local:5672/ \
  --set-string global.routing.internalDomain=internal.mycompany.com \
  --set-string global.routing.externalDomain=apps.mycompany.com \
  --set-string global.routing.internalGateway=istio-system/releasea-internal-gateway \
  --set-string global.routing.externalGateway=istio-system/releasea-external-gateway
```

> **Base setup complete:** worker is registered with the short command. The chart defaults to shared bootstrap profile (`releasea-worker-bootstrap`) in `releasea-system`.

## Parameters

### Core

| Parameter | Description | Default |
|-----------|-------------|---------|
| `install.namespace` | Namespace where worker resources are created | `releasea-system` |
| `install.createNamespace` | Create install namespace if missing | `true` |
| `replicaCount` | Number of worker replicas | `1` |
| `image.repository` | Worker image repository | `releasea/releasea-worker` |
| `image.tag` | Worker image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `token` | Worker registration token | `""` |
| `environment` | Target environment | `prod` |
| `namespacePrefix` | Namespace prefix for app workloads (`same-cluster` reads from shared profile) | `""` |
| `tags` | Comma-separated worker tags | `""` |
| `cluster` | Cluster identifier | `k3d-local` |

### Bootstrap Profile

| Parameter | Description | Default |
|-----------|-------------|---------|
| `bootstrap.mode` | `same-cluster` uses shared ConfigMap/Secret, `external` uses explicit values | `same-cluster` |
| `bootstrap.profileVersion` | Bootstrap profile version reported in heartbeat (`same-cluster` reads from shared profile) | `""` |
| `bootstrap.sharedConfig.configMapName` | Shared ConfigMap name | `releasea-worker-bootstrap` |
| `bootstrap.sharedConfig.secretName` | Shared Secret name | `releasea-worker-bootstrap` |
| `bootstrap.sharedConfig.optional` | Allow missing shared profile objects | `true` |

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
| `api.baseUrl` | Releasea API base URL (used when `bootstrap.mode=external`) | `""` |
| `rabbitmq.url` | RabbitMQ connection string (used when `bootstrap.mode=external`) | `""` |

### Routing

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.routing.internalDomain` | Preferred internal domain source (falls back to `routing.internalDomain`) | `""` |
| `global.routing.externalDomain` | Preferred external domain source (falls back to `routing.externalDomain`) | `""` |
| `global.routing.internalGateway` | Preferred internal gateway source (falls back to `routing.internalGateway`) | `""` |
| `global.routing.externalGateway` | Preferred external gateway source (falls back to `routing.externalGateway`) | `""` |
| `routing.internalDomain` | Internal service domain fallback | `""` |
| `routing.externalDomain` | External service domain fallback | `""` |
| `routing.internalGateway` | Istio internal gateway ref fallback | `""` |
| `routing.externalGateway` | Istio external gateway ref fallback | `""` |

### MinIO (Static Site Builds)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `minio.endpoint` | MinIO endpoint (used when `bootstrap.mode=external`) | `""` |
| `minio.accessKey` | MinIO access key (used when `bootstrap.mode=external`) | `""` |
| `minio.secretKey` | MinIO secret key (used when `bootstrap.mode=external`) | `""` |
| `minio.bucket` | Bucket for static site builds (used when `bootstrap.mode=external`) | `""` |
| `minio.secure` | Use HTTPS for MinIO | `false` |

### Static Site

| Parameter | Description | Default |
|-----------|-------------|---------|
| `staticSite.prefix` | Object key prefix for sites | `sites` |
| `staticSite.nginxService` | Static nginx service name (used when `bootstrap.mode=external`) | `""` |
| `staticSite.nginxNamespace` | Static nginx namespace (used when `bootstrap.mode=external`) | `""` |

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
