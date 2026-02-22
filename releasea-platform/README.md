# releasea-platform

Umbrella chart to install Releasea API, Console, and platform peripherals.

By default, this chart enables all core components for a one-click installation. All peripherals can be toggled off via Helm values after initial setup.

> **Note:** Istio is **not** included in this chart. It must be installed separately as a cluster-level prerequisite. Worker deployment is also managed separately via the `releasea-worker` chart. See the [Platform Installation Guide](https://docs.releasea.io/?doc=installation) for the full setup flow.

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Istio** | Installed and operational (CRDs, istiod, gateway) |
| **Kubernetes** | Version 1.25+ |
| **Helm** | Version 3.14+ |

## Install

```bash
helm repo add releasea https://releasea.github.io/releasea-charts
helm repo update
helm upgrade --install releasea releasea/releasea-platform -n releasea-system --create-namespace
```

## Parameters

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

## Toggle Features

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system \
  --set prometheus.enabled=false \
  --set loki.enabled=false
```

## Istio HTTPS (Optional)

By default gateways are HTTP-only (`istio.https.enabled=false`). To enable HTTPS, choose one certificate mode:

### 1) Existing Secret (recommended for production)

```bash
kubectl create secret tls releasea-local-cert \
  -n istio-system \
  --cert=/path/to/tls.crt \
  --key=/path/to/tls.key

helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system \
  --set istio.https.enabled=true \
  --set istio.https.secret.mode=existingSecret \
  --set istio.https.credentialName=releasea-local-cert
```

### 2) Self-signed certificate (for local/dev)

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system \
  --set istio.https.enabled=true \
  --set istio.https.secret.mode=selfSigned
```

### 3) Inline certificate/key from values

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system \
  --set istio.https.enabled=true \
  --set istio.https.secret.mode=inline \
  --set-file istio.https.secret.inlineCrt=/path/to/tls.crt \
  --set-file istio.https.secret.inlineKey=/path/to/tls.key
```
