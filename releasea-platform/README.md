# releasea-platform

Umbrella chart to install Releasea API, Console, Worker, Istio, and platform peripherals.

By default, this chart enables all core components for a one-click installation:

- Istio (`base`, `istiod`, `gateway`)
- MongoDB
- RabbitMQ
- MinIO
- Prometheus
- Loki + Promtail

Istio gateways are created with HTTP enabled by default. HTTPS is optional and controlled by `istio.https.enabled`.

Observability defaults follow the same baseline used in platform tests:

- Prometheus retention: `6h`
- Prometheus scrape/evaluation interval: `30s`
- Loki as default log store (`isDefault: true`)
- Loki persistence disabled
- Promtail enabled

## Install

```bash
helm repo add releasea https://releasea.github.io/releasea-charts
helm repo update
helm upgrade --install releasea releasea/releasea-platform -n releasea-system --create-namespace
```

## Toggle Features (Optional)

```bash
helm upgrade --install releasea releasea/releasea-platform \
  -n releasea-system \
  --set istio.enabled=false \
  --set prometheus.enabled=false \
  --set loki.enabled=false
```

## Istio HTTPS (Optional)

By default:

- `istio.https.enabled=false` (HTTP only)

To enable HTTPS, choose one certificate mode:

### 1) Existing Secret (recommended for production)

Create the TLS secret first:

```bash
kubectl create secret tls releasea-local-cert \
  -n istio-system \
  --cert=/path/to/tls.crt \
  --key=/path/to/tls.key
```

Then enable HTTPS:

```bash
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
