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

{{- define "releasea-platform.routing.internalDomain" -}}
{{- default (default "releasea.internal" .Values.global.routing.internalDomain) .Values.staticNginx.internalDomain -}}
{{- end -}}

{{- define "releasea-platform.routing.externalDomain" -}}
{{- default (default "releasea.external" .Values.global.routing.externalDomain) .Values.staticNginx.externalDomain -}}
{{- end -}}

{{- define "releasea-platform.routing.internalGateway" -}}
{{- default "istio-system/releasea-internal-gateway" .Values.global.routing.internalGateway -}}
{{- end -}}

{{- define "releasea-platform.routing.externalGateway" -}}
{{- default "istio-system/releasea-external-gateway" .Values.global.routing.externalGateway -}}
{{- end -}}
