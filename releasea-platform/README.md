# Platform Chart Setup

Deploy the full Releasea platform in one namespace with `releasea-platform`.
This chart includes API, Console, MongoDB, RabbitMQ, MinIO, Static Nginx, Prometheus, Loki + Promtail, a shared worker bootstrap profile, and the managed quickstart Development worker.

> **Note:** The default quickstart install includes a managed `Development` worker. Additional workers for staging, production, or extra clusters are installed separately with the [releasea-worker](../releasea-worker/) chart.
>
> See:
> - [Installation](https://docs.releasea.io/?doc=installation)
> - [Installation Modes](https://docs.releasea.io/?doc=installation-modes)
> - [Quickstart Validation](https://docs.releasea.io/?doc=smoke-checks)
> - [Production Profile](https://docs.releasea.io/?doc=production-profile)
> - [Production Runbooks](https://docs.releasea.io/?doc=production-runbooks)
> - [Environments & Workers](https://docs.releasea.io/?doc=environments-and-workers)

## Requirements

| Requirement | Details |
|-------------|---------|
| **Kubernetes** | Version 1.25+ (any conformant cluster) |
| **kubectl** | Configured for your target cluster |
| **Helm** | Version 3.14+ |
| **Istio** | Installed separately before the platform chart when using default routing discovery |

## Base Setup (Required)

### 1. Install Istio

Istio minimum version: 1.20+.

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

Verify Istio is running:

```bash
kubectl -n istio-system get pods -l app=istiod
kubectl get crd gateways.networking.istio.io
```

### 2. Create or confirm routing Gateways

By default, the chart uses `global.routing.mode=auto` and discovers domains from these Gateway objects:

- `istio-system/releasea-internal-gateway`
- `istio-system/releasea-external-gateway`

Create them with your real domains in `hosts`:

```bash
kubectl apply -f - <<'EOF_GATEWAYS'
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
EOF_GATEWAYS
```

If your Gateway names differ, override them during install:

```bash
--set-string global.routing.gatewayNamespace=istio-system \
--set-string global.routing.internalGatewayName=custom-internal-gateway \
--set-string global.routing.externalGatewayName=custom-external-gateway
```

If you prefer not to depend on discovery, switch to explicit routing values:

```bash
--set-string global.routing.mode=explicit \
--set-string global.routing.internalDomain=internal.mycompany.com \
--set-string global.routing.externalDomain=apps.mycompany.com
```

> `global.routing.mode=auto` depends on Gateway host discovery. `global.routing.mode=explicit` is the fallback when discovery is not available.

### 3. Enable Istio sidecar injection for the platform namespace

```bash
kubectl create namespace releasea-system --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace releasea-system istio-injection=enabled --overwrite
```

### 4. Install the platform

```bash
helm repo add releasea https://releasea.github.io/releasea-charts
helm repo update releasea
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system --create-namespace
```

The default install includes the managed quickstart worker for the `Development` environment. Disable it only when you intentionally want a platform install without that worker:

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system --create-namespace \
  --set bootstrapDevWorker.enabled=false
```

All major platform components are enabled by default. Disable any with `--set <component>.enabled=false`:

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system --create-namespace \
  --set api.enabled=false \
  --set console.enabled=false \
  --set mongodb.enabled=false
```

### 5. Validate the install and verify the Development worker

```bash
kubectl -n releasea-system get pods
kubectl -n releasea-system get deploy
kubectl -n releasea-system get configmap releasea-worker-bootstrap
kubectl -n releasea-system get secret releasea-worker-bootstrap
```

You should see:

- the platform workloads in `Running`
- the shared bootstrap objects named `releasea-worker-bootstrap`
- the deployment `releasea-platform-bootstrap-dev-worker`

### 6. Access the Console

**Port-forward (quickest):**

```bash
kubectl -n releasea-system port-forward svc/releasea-console 8080:8080
```

Then open `http://localhost:8080`.

Sign in with bootstrap credentials:

| Credential | Value |
|------------|-------|
| **Admin email** | `admin@releasea.io` |
| **Admin password** | `releasea` |

Change the default password immediately after first login.

From the Console, confirm the **Workers** page already shows the managed `Development` worker. If you disabled `bootstrapDevWorker.enabled`, register workers manually with the `releasea-worker` chart.

## Smoke Validation

After the platform is reachable, run the official smoke path in [Quickstart Validation](https://docs.releasea.io/?doc=smoke-checks).

That validation confirms:

- platform pods are healthy
- `releasea-worker-bootstrap` exists
- the managed `Development` worker is online
- Console login works
- a real deploy can complete in `Development`

## Production Profile

The chart now ships two opinionated production-oriented baseline files:

- `values-production.yaml`: hardened install using the bundled internal stateful services
- `values-production-external.yaml`: hardened install using external MongoDB, RabbitMQ, MinIO, Prometheus, and Loki

Use it when you want a more durable and operationally predictable install than the quickstart path. The bundled production profile:

- disables the managed quickstart Development worker
- scales API and Console to `2` replicas
- enables `PodDisruptionBudget` resources for API and Console
- enables PVC-backed storage for MongoDB, RabbitMQ, MinIO, Prometheus, and Loki
- adds resource requests and limits for the main services

Example:

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system --create-namespace \
  -f values-production.yaml \
  --set-string global.routing.internalDomain=internal.mycompany.com \
  --set-string global.routing.externalDomain=apps.mycompany.com
```

Example with external managed dependencies:

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system --create-namespace \
  -f values-production-external.yaml \
  --set-string global.routing.internalDomain=internal.mycompany.com \
  --set-string global.routing.externalDomain=apps.mycompany.com
```

For the secure production path, create Kubernetes Secrets first and let the chart reuse them through `existingSecret` references. The exact secret layout and runbook steps are in [Production Runbooks](https://docs.releasea.io/?doc=production-runbooks).

Use the bundled file as a starting point, then review at minimum:

- routing domains
- storage classes
- image tags
- MinIO and RabbitMQ credentials
- Console ingress or external access path

Important boundary:

- API and Console gain basic HA posture through multiple replicas.
- Stateful dependencies remain single-instance in the bundled chart.
- PVC-backed storage improves durability, but it does not replace replicated data services.

If you need stronger uptime or recovery guarantees, treat this file as a baseline and move stateful services to a customized or managed topology. See [Production Profile](https://docs.releasea.io/?doc=production-profile) for the full rollout guidance.

**Ingress (cloud environments):**

If you use an AWS ALB, Nginx Ingress, or similar controller, enable the Console ingress:

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system \
  --set console.ingress.enabled=true \
  --set console.ingress.className=alb \
  --set console.ingress.host=console.your-domain.com
```

Adjust `className` and `host` to match your environment (`nginx`, `alb`, `traefik`, etc.).

## Installation Modes

Releasea exposes three public installation modes:

- **Quickstart platform**: install `releasea-platform` with the managed `Development` worker enabled
- **Platform-only / customized platform**: install `releasea-platform` with selected components, explicit routing, or external observability choices
- **Standalone worker**: install `releasea-worker` for additional environments or remote clusters

See the full comparison in [Installation Modes](https://docs.releasea.io/?doc=installation-modes).

## Worker Bootstrap

This chart publishes a shared worker bootstrap profile named `releasea-worker-bootstrap` in the platform namespace.

It is composed of:

- a `ConfigMap` with non-sensitive worker bootstrap values
- a `Secret` with sensitive worker bootstrap values

The profile is consumed by workers running in `same-cluster` mode and supplies:

- API base URL
- RabbitMQ URL
- internal and external domains
- internal and external gateway references
- MinIO endpoint and bucket defaults
- static site service endpoints
- namespace prefix for generated workloads

This shared profile is what makes the short `releasea-worker` Helm command work for same-cluster installs.

## Advanced Options

- Default mode: `global.routing.mode=auto` (discover domains from Istio Gateway hosts).
- Explicit mode: set `global.routing.mode=explicit` and provide `global.routing.internalDomain` + `global.routing.externalDomain`.
- Gateway reference overrides are available through:
  `global.routing.gatewayNamespace`, `global.routing.internalGatewayName`, `global.routing.externalGatewayName`,
  or full refs in `global.routing.internalGateway` / `global.routing.externalGateway`.

## Production Tuning Knobs

The chart now exposes the core scheduling and durability knobs needed by the bundled production profile:

- `api.resources`, `api.nodeSelector`, `api.tolerations`, `api.affinity`, `api.topologySpreadConstraints`
- `api.podDisruptionBudget.enabled`, `api.podDisruptionBudget.minAvailable`
- `console.resources`, `console.nodeSelector`, `console.tolerations`, `console.affinity`, `console.topologySpreadConstraints`
- `console.podDisruptionBudget.enabled`, `console.podDisruptionBudget.minAvailable`
- `mongodb.resources`, `mongodb.persistence.storageClassName`
- `mongodb.external.uri`
- `rabbitmq.resources`, `rabbitmq.persistence.enabled`, `rabbitmq.persistence.size`, `rabbitmq.persistence.storageClassName`, `rabbitmq.external.url`
- `minio.resources`, `minio.persistence.storageClassName`, `minio.external.endpoint`, `minio.external.accessKey`, `minio.external.secretKey`, `minio.external.bucket`, `minio.external.secure`
- `prometheus.persistence.enabled`, `prometheus.persistence.size`, `prometheus.persistence.storageClassName`, `prometheus.external.url`
- `loki.persistence.storageClassName`, `loki.external.url`

## Parameters

### Global

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageTag` | Default image tag for API and Console | `latest` |
| `global.imagePullPolicy` | Image pull policy | `IfNotPresent` |
| `global.routing.mode` | Routing resolution mode (`auto` discovers from Istio Gateway hosts, `explicit` requires domains) | `auto` |
| `global.routing.gatewayNamespace` | Namespace where routing gateways are searched | `istio-system` |
| `global.routing.internalGatewayName` | Internal gateway name used for auto mode | `releasea-internal-gateway` |
| `global.routing.externalGatewayName` | External gateway name used for auto mode | `releasea-external-gateway` |
| `global.routing.internalDomain` | Internal domain override (`explicit` mode required) | `""` |
| `global.routing.externalDomain` | External domain override (`explicit` mode required) | `""` |
| `global.routing.internalGateway` | Full internal gateway ref override (`namespace/name`) | `""` |
| `global.routing.externalGateway` | Full external gateway ref override (`namespace/name`) | `""` |

### Worker Bootstrap

| Parameter | Description | Default |
|-----------|-------------|---------|
| `workerBootstrap.enabled` | Publish shared worker bootstrap ConfigMap/Secret | `true` |
| `workerBootstrap.mode` | Bootstrap mode consumed by workers | `same-cluster` |
| `workerBootstrap.version` | Bootstrap profile version | `1` |
| `workerBootstrap.platformNamespace` | Namespace used in generated worker endpoints (empty = release namespace) | `""` |
| `workerBootstrap.namespacePrefix` | Default namespace prefix for worker payloads | `releasea-apps` |
| `workerBootstrap` shared ConfigMap name | Fixed shared ConfigMap | `releasea-worker-bootstrap` |
| `workerBootstrap` shared Secret name | Fixed shared Secret | `releasea-worker-bootstrap` |
| `workerBootstrap.apiBaseUrl` | Worker API URL override (empty = generated) | `""` |
| `workerBootstrap.rabbitmqUrl` | Worker RabbitMQ URL override (empty = generated) | `""` |
| `workerBootstrap.minioEndpoint` | Worker MinIO endpoint override (empty = generated) | `""` |
| `workerBootstrap.minioBucket` | Worker MinIO bucket override (empty = inherited from `minio.bucket`) | `""` |
| `workerBootstrap.minioSecure` | Worker MinIO TLS override (null = inherited from `minio.secure`) | `null` |
| `workerBootstrap.staticNginxService` | Worker static nginx service name | `releasea-static-nginx` |
| `workerBootstrap.staticNginxNamespace` | Worker static nginx namespace (empty = platform namespace) | `""` |

### Bootstrap Dev Worker

| Parameter | Description | Default |
|-----------|-------------|---------|
| `bootstrapDevWorker.enabled` | Deploy the managed Development worker with the platform quickstart profile | `true` |

### API

| Parameter | Description | Default |
|-----------|-------------|---------|
| `api.enabled` | Deploy the API server | `true` |
| `api.replicaCount` | Number of replicas | `1` |
| `api.image.repository` | API image repository | `releasea/releasea-api` |
| `api.image.tag` | API image tag (overrides global) | `""` |
| `api.service.type` | Service type | `ClusterIP` |
| `api.service.port` | Service port | `8070` |
| `api.env` | Environment variables (key-value map). Routing and core dependency envs (`RELEASEA_*_DOMAIN`, `RELEASEA_*_GATEWAY`, `MONGO_URI`, `RABBITMQ_URL`, `PROMETHEUS_URL`, `LOKI_URL`) are computed by the chart unless explicitly overridden here. | See `values.yaml` |

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
| `mongodb.external.uri` | External MongoDB URI used when internal MongoDB is disabled | `""` |

### RabbitMQ

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rabbitmq.enabled` | Deploy RabbitMQ | `true` |
| `rabbitmq.image` | RabbitMQ image | `rabbitmq:3.13-management` |
| `rabbitmq.service.amqpPort` | AMQP port | `5672` |
| `rabbitmq.service.managementPort` | Management UI port | `15672` |
| `rabbitmq.auth.username` | Default username | `releasea` |
| `rabbitmq.auth.password` | Default password | `releasea` |
| `rabbitmq.persistence.enabled` | Enable persistent volume | `false` |
| `rabbitmq.persistence.size` | PVC size | `8Gi` |
| `rabbitmq.external.url` | External RabbitMQ AMQP URL used when internal RabbitMQ is disabled | `""` |

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
| `minio.external.endpoint` | External MinIO or S3-compatible endpoint without scheme | `""` |
| `minio.external.accessKey` | External MinIO access key | `""` |
| `minio.external.secretKey` | External MinIO secret key | `""` |
| `minio.external.bucket` | External bucket override | `""` |
| `minio.external.secure` | External MinIO TLS toggle | `null` |

### Static Nginx

| Parameter | Description | Default |
|-----------|-------------|---------|
| `staticNginx.enabled` | Deploy static site reverse proxy | `true` |
| `staticNginx.image` | Nginx image | `nginx:1.27-alpine` |
| `staticNginx.dnsResolver` | Cluster DNS resolver IP | `10.43.0.10` |
| `staticNginx.internalDomain` | Internal domain suffix override (empty = inherit from `global.routing.internalDomain`) | `""` |
| `staticNginx.externalDomain` | External domain suffix override (empty = inherit from `global.routing.externalDomain`) | `""` |
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
| `prometheus.external.url` | External Prometheus base URL used when built-in Prometheus is disabled | `""` |

### Loki

| Parameter | Description | Default |
|-----------|-------------|---------|
| `loki.enabled` | Deploy Loki | `true` |
| `loki.isDefault` | Mark Loki as default log backend for the platform | `true` |
| `loki.image` | Loki image | `grafana/loki:3.1.1` |
| `loki.persistence.enabled` | Enable persistent volume | `false` |
| `loki.persistence.size` | PVC size | `10Gi` |
| `loki.service.port` | Service port | `3100` |
| `loki.promtail.enabled` | Deploy Promtail DaemonSet | `true` |
| `loki.promtail.image` | Promtail image | `grafana/promtail:3.1.1` |
| `loki.grafana.enabled` | Deploy Grafana alongside Loki | `false` |
| `loki.resources` | CPU/memory resource limits | `{}` |
| `loki.external.url` | External Loki base URL used when built-in Loki is disabled | `""` |

## Observability

The chart includes standalone Prometheus and Loki that work out of the box:

- **Prometheus** scrapes kubelet and cAdvisor metrics, Istio Envoy sidecars, and annotated pods
- **Loki + Promtail** collects logs from pods across namespaces
- the API connects automatically through `PROMETHEUS_URL` and `LOKI_URL`

To use external monitoring stacks instead, disable the built-in ones and set the dedicated external URLs:

```bash
helm upgrade --install releasea releasea/releasea-platform -n releasea-system \
  --set prometheus.enabled=false \
  --set loki.enabled=false \
  --set-string prometheus.external.url=http://your-prometheus:9090 \
  --set-string loki.external.url=http://your-loki:3100
```

The same pattern exists for the other internal dependencies:

- `mongodb.external.uri`
- `rabbitmq.external.url`
- `minio.external.*`

## Service Names

These service names are referenced by the shared worker bootstrap profile and by standalone workers in external mode:

| Service | Port | Referenced By |
|---------|------|---------------|
| `releasea-api` | 8070 | Worker (`api.baseUrl`) |
| `releasea-rabbitmq` | 5672 | Worker (`rabbitmq.url`), API |
| `releasea-minio` | 9000 | Worker (`minio.endpoint`) |
| `releasea-static-nginx` | 80 | Worker (`staticSite.nginxService`) |
| `releasea-prometheus` | 9090 | API (`PROMETHEUS_URL`) |
| `releasea-loki` | 3100 | API (`LOKI_URL`) |

When you disable internal dependencies and use `*.external.*` values instead, these service names are no longer part of the active topology for that dependency. The chart publishes the external URLs into the API and worker bootstrap profile automatically.

## Port Forwarding

| Service | Command |
|---------|---------|
| **Console** | `kubectl -n releasea-system port-forward svc/releasea-console 8080:8080` |
| **API** | `kubectl -n releasea-system port-forward svc/releasea-api 8070:8070` |
| **RabbitMQ UI** | `kubectl -n releasea-system port-forward svc/releasea-rabbitmq 15672:15672` |
| **Prometheus** | `kubectl -n releasea-system port-forward svc/releasea-prometheus 9090:9090` |
| **Loki** | `kubectl -n releasea-system port-forward svc/releasea-loki 3100:3100` |
| **MinIO Console** | `kubectl -n releasea-system port-forward svc/releasea-minio 9001:9001` |

## Upgrades

```bash
helm repo update releasea
helm upgrade releasea releasea/releasea-platform -n releasea-system
```

## Uninstall

```bash
helm uninstall releasea -n releasea-system
kubectl -n istio-system delete gateway releasea-internal-gateway releasea-external-gateway
kubectl delete namespace releasea-system
```

> Uninstalling the platform chart does not uninstall Istio. Manage Istio separately.

## Troubleshooting

| Problem | Likely Cause | Solution |
|---------|-------------|----------|
| Platform install fails before resources are created | Istio Gateways are missing or routing domains cannot be auto-discovered | Create the Gateways first or switch to `global.routing.mode=explicit` |
| Bootstrap Development worker is missing | `bootstrapDevWorker.enabled=false` or deployment failed | Check the chart values and inspect `releasea-platform-bootstrap-dev-worker` |
| Pods pending | Insufficient resources or missing storage class | Check node capacity and PVC status |
| API unhealthy | MongoDB or RabbitMQ not reachable | Check pod status of dependent services |
| Sidecar not injecting | Namespace not labeled | Re-run the namespace label step |
| No metrics data | Prometheus RBAC or wrong URL | Check `PROMETHEUS_URL` and Prometheus logs |
| No log data | Promtail not running or Loki unreachable | Check Promtail DaemonSet pods and Loki readiness |
| Additional worker cannot connect | Invalid API URL, wrong bootstrap mode, or expired token | Verify `releasea-worker-bootstrap`, `bootstrap.mode`, and worker token |

## Documentation

- Platform install guide: [docs.releasea.io/?doc=installation](https://docs.releasea.io/?doc=installation)
- Installation modes: [docs.releasea.io/?doc=installation-modes](https://docs.releasea.io/?doc=installation-modes)
- Quickstart validation: [docs.releasea.io/?doc=smoke-checks](https://docs.releasea.io/?doc=smoke-checks)
- Environments and workers: [docs.releasea.io/?doc=environments-and-workers](https://docs.releasea.io/?doc=environments-and-workers)
- Public components: [docs.releasea.io/?doc=public-components](https://docs.releasea.io/?doc=public-components)

## License

Apache 2.0 - See [../LICENSE](../LICENSE) for details.
