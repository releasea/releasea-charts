# releasea-platform

Helm chart for deploying the Releasea platform infrastructure into a single Kubernetes namespace.

Installs API, Console, MongoDB, RabbitMQ, MinIO, Static Nginx, Prometheus, and Loki + Promtail. All components are feature-flagged and can be individually enabled or disabled.

> **Note:** Workers are deployed **separately** using the [releasea-worker](../releasea-worker/) chart. See [Environments & Workers](https://docs.releasea.io/?doc=environments-and-workers) for details.

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Kubernetes** | Version 1.25+ |
| **Helm** | Version 3.14+ |
| **Istio** | Installed separately (see below) |

## Install

### 1. Install Istio

```bash
istioctl install -y --set profile=default
```

Or via Helm:

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm upgrade --install istio-base istio/base -n istio-system --create-namespace --wait
helm upgrade --install istiod istio/istiod -n istio-system --wait
helm upgrade --install istio-ingress istio/gateway -n istio-system --wait
```

### 2. Install the platform

```bash
helm upgrade --install releasea ./releasea-platform \
  -n releasea-system --create-namespace
```

Infrastructure only (no API, Console, or MongoDB):

```bash
helm upgrade --install releasea ./releasea-platform \
  -n releasea-system --create-namespace \
  --set api.enabled=false \
  --set console.enabled=false \
  --set mongodb.enabled=false
```

### 3. Enable Istio sidecar injection

```bash
kubectl label namespace releasea-system istio-injection=enabled --overwrite
```

### 4. Create Istio Gateways

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: releasea-internal-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingress
  servers:
    - port: { number: 80, name: http-internal, protocol: HTTP }
      hosts: ["*.releasea.internal"]
    - port: { number: 443, name: https-internal, protocol: HTTPS }
      tls: { mode: SIMPLE, credentialName: releasea-local-cert }
      hosts: ["*.releasea.internal"]
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: releasea-external-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingress
  servers:
    - port: { number: 80, name: http-external, protocol: HTTP }
      hosts: ["*.releasea.external"]
    - port: { number: 443, name: https-external, protocol: HTTPS }
      tls: { mode: SIMPLE, credentialName: releasea-local-cert }
      hosts: ["*.releasea.external"]
EOF
```

### 5. (Optional) TLS Certificates

Local development with [mkcert](https://github.com/FiloSottile/mkcert):

```bash
mkcert -install
mkcert -cert-file releasea.pem -key-file releasea-key.pem \
  "*.releasea.internal" "*.releasea.external"
kubectl -n istio-system create secret tls releasea-local-cert \
  --cert=releasea.pem --key=releasea-key.pem
```

Production: use [cert-manager](https://cert-manager.io/) or your CA to provide the `releasea-local-cert` secret.

### 6. Install Workers

```bash
helm upgrade --install releasea-worker ./releasea-worker \
  -n releasea-system \
  --set-string token=<worker-token>
```

See the [releasea-worker](../releasea-worker/) chart for full configuration.

## Parameters

### Global

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageTag` | Default image tag for API and Console | `latest` |
| `global.imagePullPolicy` | Image pull policy | `IfNotPresent` |

### API

| Parameter | Description | Default |
|-----------|-------------|---------|
| `api.enabled` | Deploy the API server | `true` |
| `api.replicaCount` | Number of replicas | `1` |
| `api.image.repository` | API image repository | `releasea/releasea-api` |
| `api.image.tag` | API image tag (overrides global) | `""` |
| `api.service.type` | Service type | `ClusterIP` |
| `api.service.port` | Service port | `8070` |
| `api.env` | Environment variables (key-value map) | See `values.yaml` |

### Console

| Parameter | Description | Default |
|-----------|-------------|---------|
| `console.enabled` | Deploy the Console UI | `true` |
| `console.replicaCount` | Number of replicas | `1` |
| `console.image.repository` | Console image repository | `releasea/releasea-console` |
| `console.image.tag` | Console image tag (overrides global) | `""` |
| `console.service.type` | Service type | `ClusterIP` |
| `console.service.port` | Service port | `8080` |
| `console.ingress.enabled` | Create Ingress resource | `false` |
| `console.ingress.className` | Ingress class name | `""` |
| `console.ingress.host` | Ingress hostname | `""` |
| `console.ingress.path` | Ingress path | `/` |

### MongoDB

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mongodb.enabled` | Deploy MongoDB | `true` |
| `mongodb.image` | MongoDB image | `mongo:7` |
| `mongodb.service.port` | Service port | `27017` |
| `mongodb.persistence.enabled` | Enable persistent volume | `false` |
| `mongodb.persistence.size` | PVC size | `8Gi` |

### RabbitMQ

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rabbitmq.enabled` | Deploy RabbitMQ | `true` |
| `rabbitmq.image` | RabbitMQ image | `rabbitmq:3.13-management` |
| `rabbitmq.service.amqpPort` | AMQP port | `5672` |
| `rabbitmq.service.managementPort` | Management UI port | `15672` |
| `rabbitmq.auth.username` | Default username | `releasea` |
| `rabbitmq.auth.password` | Default password | `releasea` |

### MinIO

| Parameter | Description | Default |
|-----------|-------------|---------|
| `minio.enabled` | Deploy MinIO | `true` |
| `minio.image` | MinIO image | `minio/minio:latest` |
| `minio.service.apiPort` | S3 API port | `9000` |
| `minio.service.consolePort` | Web console port | `9001` |
| `minio.accessKey` | Root username | `releasea` |
| `minio.secretKey` | Root password | `releaseaadmin` |
| `minio.bucket` | Default bucket name | `releasea-static` |
| `minio.persistence.enabled` | Enable persistent volume | `false` |
| `minio.persistence.size` | PVC size | `10Gi` |

### Static Nginx

| Parameter | Description | Default |
|-----------|-------------|---------|
| `staticNginx.enabled` | Deploy static site reverse proxy | `true` |
| `staticNginx.image` | Nginx image | `nginx:1.27-alpine` |
| `staticNginx.dnsResolver` | Cluster DNS resolver IP | `10.43.0.10` |
| `staticNginx.internalDomain` | Internal domain suffix | `releasea.internal` |
| `staticNginx.externalDomain` | External domain suffix | `releasea.external` |
| `staticNginx.sitePrefix` | MinIO path prefix for sites | `sites` |
| `staticNginx.resources` | CPU/memory resource limits | `{}` |

### Prometheus

| Parameter | Description | Default |
|-----------|-------------|---------|
| `prometheus.enabled` | Deploy standalone Prometheus | `true` |
| `prometheus.image` | Prometheus image | `prom/prometheus:v2.55.1` |
| `prometheus.retention` | Data retention period | `6h` |
| `prometheus.scrapeInterval` | Scrape interval | `30s` |
| `prometheus.evaluationInterval` | Rule evaluation interval | `30s` |
| `prometheus.service.port` | Service port | `9090` |
| `prometheus.resources` | CPU/memory resource limits | `{}` |

### Loki

| Parameter | Description | Default |
|-----------|-------------|---------|
| `loki.enabled` | Deploy standalone Loki | `true` |
| `loki.isDefault` | Mark as default log store | `true` |
| `loki.image` | Loki image | `grafana/loki:3.1.1` |
| `loki.service.port` | Service port | `3100` |
| `loki.persistence.enabled` | Enable persistent volume | `false` |
| `loki.persistence.size` | PVC size | `10Gi` |
| `loki.promtail.enabled` | Deploy Promtail DaemonSet | `true` |
| `loki.promtail.image` | Promtail image | `grafana/promtail:3.1.1` |
| `loki.resources` | CPU/memory resource limits | `{}` |

## Observability

The chart includes standalone Prometheus and Loki that work out of the box:

- **Prometheus** scrapes kubelet/cAdvisor (CPU/memory), Istio Envoy sidecars (requests/latency), and annotated pods
- **Loki + Promtail** collects logs from all pods across all namespaces via DaemonSet
- The API connects automatically via `PROMETHEUS_URL` and `LOKI_URL` environment variables

To use external monitoring stacks instead, disable the built-in ones and point the API to your endpoints:

```bash
helm upgrade --install releasea ./releasea-platform -n releasea-system \
  --set prometheus.enabled=false \
  --set loki.enabled=false \
  --set "api.env.PROMETHEUS_URL=http://your-prometheus:9090" \
  --set "api.env.LOKI_URL=http://your-loki:3100"
```

## Service Names

These names are referenced by the [releasea-worker](../releasea-worker/) chart and must not change:

| Service | Port | Referenced By |
|---------|------|---------------|
| `releasea-api` | 8070 | Worker (`api.baseUrl`) |
| `releasea-rabbitmq` | 5672 | Worker (`rabbitmq.url`), API |
| `releasea-minio` | 9000 | Worker (`minio.endpoint`) |
| `releasea-static-nginx` | 80 | Worker (`staticSite.nginxService`) |
| `releasea-prometheus` | 9090 | API (`PROMETHEUS_URL`) |
| `releasea-loki` | 3100 | API (`LOKI_URL`) |

## Uninstall

```bash
helm uninstall releasea -n releasea-system
kubectl -n istio-system delete gateway releasea-internal-gateway releasea-external-gateway
kubectl delete namespace releasea-system
```
