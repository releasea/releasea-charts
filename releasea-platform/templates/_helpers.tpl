{{- define "releasea-platform.name" -}}
releasea-platform
{{- end -}}

{{- define "releasea-platform.fullname" -}}
{{- printf "%s" (include "releasea-platform.name" .) -}}
{{- end -}}

{{- define "releasea-platform.labels" -}}
app.kubernetes.io/name: {{ include "releasea-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "releasea-platform.imageTag" -}}
{{- $componentTag := index . 0 -}}
{{- $global := index . 1 -}}
{{- default $global $componentTag -}}
{{- end -}}

{{- define "releasea-platform.routing.mode" -}}
{{- $mode := default "auto" .Values.global.routing.mode | trim | lower -}}
{{- if and (ne $mode "auto") (ne $mode "explicit") -}}
{{- fail (printf "invalid global.routing.mode=%q, expected auto|explicit" $mode) -}}
{{- end -}}
{{- $mode -}}
{{- end -}}

{{- define "releasea-platform.routing.gatewayNamespace" -}}
{{- default "istio-system" .Values.global.routing.gatewayNamespace | trim -}}
{{- end -}}

{{- define "releasea-platform.routing.internalGatewayName" -}}
{{- default "releasea-internal-gateway" .Values.global.routing.internalGatewayName | trim -}}
{{- end -}}

{{- define "releasea-platform.routing.externalGatewayName" -}}
{{- default "releasea-external-gateway" .Values.global.routing.externalGatewayName | trim -}}
{{- end -}}

{{- define "releasea-platform.routing.normalizeHost" -}}
{{- $host := . | toString | trim -}}
{{- if hasPrefix "*." $host -}}
{{- trimPrefix "*." $host -}}
{{- else -}}
{{- $host -}}
{{- end -}}
{{- end -}}

{{- define "releasea-platform.routing.normalizeGatewayRef" -}}
{{- $ref := default "" (index . "ref") | toString | trim -}}
{{- $defaultNamespace := default "istio-system" (index . "defaultNamespace") | toString | trim -}}
{{- $defaultName := default "" (index . "defaultName") | toString | trim -}}
{{- if ne $ref "" -}}
  {{- if contains "/" $ref -}}
{{- $ref -}}
  {{- else -}}
{{- printf "%s/%s" $defaultNamespace $ref -}}
  {{- end -}}
{{- else -}}
{{- printf "%s/%s" $defaultNamespace $defaultName -}}
{{- end -}}
{{- end -}}

{{- define "releasea-platform.routing.gatewayFirstHost" -}}
{{- $namespace := index . "namespace" | toString | trim -}}
{{- $name := index . "name" | toString | trim -}}
{{- $gateway := lookup "networking.istio.io/v1beta1" "Gateway" $namespace $name -}}
{{- if empty $gateway -}}
{{- "" -}}
{{- else -}}
  {{- $spec := get $gateway "spec" -}}
  {{- $servers := get $spec "servers" -}}
  {{- $host := "" -}}
  {{- if kindIs "slice" $servers -}}
    {{- range $server := $servers -}}
      {{- if eq $host "" -}}
        {{- $hosts := get $server "hosts" -}}
        {{- if and (kindIs "slice" $hosts) (gt (len $hosts) 0) -}}
          {{- $host = include "releasea-platform.routing.normalizeHost" (index $hosts 0) | trim -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- $host -}}
{{- end -}}
{{- end -}}

{{- define "releasea-platform.routing.internalDomain" -}}
{{- $mode := include "releasea-platform.routing.mode" . | trim -}}
{{- $staticOverride := include "releasea-platform.routing.normalizeHost" (default "" .Values.staticNginx.internalDomain) | trim -}}
{{- if ne $staticOverride "" -}}
{{- $staticOverride -}}
{{- else -}}
  {{- $explicit := include "releasea-platform.routing.normalizeHost" (default "" .Values.global.routing.internalDomain) | trim -}}
  {{- if ne $explicit "" -}}
{{- $explicit -}}
  {{- else if eq $mode "explicit" -}}
{{- fail "global.routing.internalDomain is required when global.routing.mode=explicit" -}}
  {{- else -}}
    {{- $gatewayRef := include "releasea-platform.routing.internalGateway" . | trim -}}
    {{- $parts := splitList "/" $gatewayRef -}}
    {{- if ne (len $parts) 2 -}}
{{- fail (printf "invalid internal gateway reference %q; expected namespace/name" $gatewayRef) -}}
    {{- end -}}
    {{- $detected := include "releasea-platform.routing.gatewayFirstHost" (dict "namespace" (index $parts 0) "name" (index $parts 1)) | trim -}}
    {{- if eq $detected "" -}}
{{- fail (printf "unable to auto-discover internal domain from Istio Gateway %s; configure gateway hosts or set global.routing.internalDomain" $gatewayRef) -}}
    {{- end -}}
{{- $detected -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "releasea-platform.routing.externalDomain" -}}
{{- $mode := include "releasea-platform.routing.mode" . | trim -}}
{{- $staticOverride := include "releasea-platform.routing.normalizeHost" (default "" .Values.staticNginx.externalDomain) | trim -}}
{{- if ne $staticOverride "" -}}
{{- $staticOverride -}}
{{- else -}}
  {{- $explicit := include "releasea-platform.routing.normalizeHost" (default "" .Values.global.routing.externalDomain) | trim -}}
  {{- if ne $explicit "" -}}
{{- $explicit -}}
  {{- else if eq $mode "explicit" -}}
{{- fail "global.routing.externalDomain is required when global.routing.mode=explicit" -}}
  {{- else -}}
    {{- $gatewayRef := include "releasea-platform.routing.externalGateway" . | trim -}}
    {{- $parts := splitList "/" $gatewayRef -}}
    {{- if ne (len $parts) 2 -}}
{{- fail (printf "invalid external gateway reference %q; expected namespace/name" $gatewayRef) -}}
    {{- end -}}
    {{- $detected := include "releasea-platform.routing.gatewayFirstHost" (dict "namespace" (index $parts 0) "name" (index $parts 1)) | trim -}}
    {{- if eq $detected "" -}}
{{- fail (printf "unable to auto-discover external domain from Istio Gateway %s; configure gateway hosts or set global.routing.externalDomain" $gatewayRef) -}}
    {{- end -}}
{{- $detected -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "releasea-platform.routing.internalGateway" -}}
{{- $gatewayNamespace := include "releasea-platform.routing.gatewayNamespace" . | trim -}}
{{- $gatewayName := include "releasea-platform.routing.internalGatewayName" . | trim -}}
{{- include "releasea-platform.routing.normalizeGatewayRef" (dict
  "ref" .Values.global.routing.internalGateway
  "defaultNamespace" $gatewayNamespace
  "defaultName" $gatewayName
) -}}
{{- end -}}

{{- define "releasea-platform.routing.externalGateway" -}}
{{- $gatewayNamespace := include "releasea-platform.routing.gatewayNamespace" . | trim -}}
{{- $gatewayName := include "releasea-platform.routing.externalGatewayName" . | trim -}}
{{- include "releasea-platform.routing.normalizeGatewayRef" (dict
  "ref" .Values.global.routing.externalGateway
  "defaultNamespace" $gatewayNamespace
  "defaultName" $gatewayName
) -}}
{{- end -}}

{{- define "releasea-platform.bootstrapDevWorker.enabled" -}}
{{- ternary "true" "false" (default true .Values.bootstrapDevWorker.enabled) -}}
{{- end -}}

{{- define "releasea-platform.workerBootstrap.secretName" -}}
{{- default "releasea-worker-bootstrap" .Values.workerBootstrap.existingSecret.name -}}
{{- end -}}

{{- define "releasea-platform.bootstrapDevWorker.validate" -}}
{{- if (default true .Values.bootstrapDevWorker.enabled) -}}
  {{- if not .Values.workerBootstrap.enabled -}}
    {{- fail "bootstrapDevWorker.enabled=true requires workerBootstrap.enabled=true" -}}
  {{- end -}}
  {{- if and (not .Values.rabbitmq.enabled) (eq (trim (default "" .Values.rabbitmq.external.url)) "") (eq (trim (default "" .Values.rabbitmq.external.existingSecret.name)) "") (eq (trim (default "" .Values.workerBootstrap.existingSecret.name)) "") (eq (trim (default "" .Values.workerBootstrap.rabbitmqUrl)) "") -}}
    {{- fail "bootstrapDevWorker.enabled=true requires rabbitmq.enabled=true, rabbitmq.external.url, rabbitmq.external.existingSecret.name, workerBootstrap.existingSecret.name, or workerBootstrap.rabbitmqUrl" -}}
  {{- end -}}
  {{- if and (not .Values.api.enabled) (eq (trim (default "" .Values.workerBootstrap.apiBaseUrl)) "") -}}
    {{- fail "bootstrapDevWorker.enabled=true with api.enabled=false requires workerBootstrap.apiBaseUrl" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "releasea-platform.dependencies.validate" -}}
{{- $apiEnv := .Values.api.env | default dict -}}
{{- if and .Values.api.enabled (not .Values.mongodb.enabled) (eq (trim (coalesce (index $apiEnv "MONGO_URI") .Values.mongodb.external.uri .Values.mongodb.external.existingSecret.name "")) "") -}}
  {{- fail "api.enabled=true requires mongodb.enabled=true, mongodb.external.uri, mongodb.external.existingSecret.name, or api.env.MONGO_URI" -}}
{{- end -}}
{{- if and .Values.api.enabled (not .Values.rabbitmq.enabled) (eq (trim (coalesce (index $apiEnv "RABBITMQ_URL") .Values.rabbitmq.external.url .Values.rabbitmq.external.existingSecret.name .Values.workerBootstrap.existingSecret.name "")) "") -}}
  {{- fail "api.enabled=true requires rabbitmq.enabled=true, rabbitmq.external.url, rabbitmq.external.existingSecret.name, workerBootstrap.existingSecret.name, or api.env.RABBITMQ_URL" -}}
{{- end -}}
{{- if and .Values.staticNginx.enabled (not .Values.minio.enabled) (eq (trim (coalesce .Values.minio.external.endpoint .Values.workerBootstrap.minioEndpoint "")) "") -}}
  {{- fail "staticNginx.enabled=true requires minio.enabled=true, minio.external.endpoint, or workerBootstrap.minioEndpoint" -}}
{{- end -}}
{{- if and .Values.workerBootstrap.enabled (not .Values.rabbitmq.enabled) (eq (trim (coalesce .Values.workerBootstrap.rabbitmqUrl .Values.rabbitmq.external.url .Values.rabbitmq.external.existingSecret.name .Values.workerBootstrap.existingSecret.name "")) "") -}}
  {{- fail "workerBootstrap.enabled=true requires rabbitmq.enabled=true, rabbitmq.external.url, rabbitmq.external.existingSecret.name, workerBootstrap.existingSecret.name, or workerBootstrap.rabbitmqUrl" -}}
{{- end -}}
{{- end -}}

{{- define "releasea-platform.bootstrapDevWorker.fullname" -}}
{{- printf "%s-bootstrap-dev-worker" (include "releasea-platform.fullname" .) -}}
{{- end -}}

{{- define "releasea-platform.bootstrapDevWorker.serviceAccountName" -}}
{{- include "releasea-platform.bootstrapDevWorker.fullname" . -}}
{{- end -}}

{{- define "releasea-platform.bootstrapDevWorker.tokenSecretName" -}}
{{- "releasea-bootstrap-dev-worker-token" -}}
{{- end -}}

{{- define "releasea-platform.bootstrapDevWorker.tokenValue" -}}
{{- $secretName := include "releasea-platform.bootstrapDevWorker.tokenSecretName" . | trim -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if and $existing (hasKey $existing.data "token") -}}
{{- index $existing.data "token" | b64dec -}}
{{- else -}}
{{- printf "frg_reg_%s" (randAlphaNum 24 | lower) -}}
{{- end -}}
{{- end -}}
