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
