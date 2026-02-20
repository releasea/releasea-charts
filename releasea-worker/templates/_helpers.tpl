{{- define "releasea-worker.name" -}}
releasea-worker
{{- end }}

{{- define "releasea-worker.fullname" -}}
{{- printf "%s" (include "releasea-worker.name" .) -}}
{{- end }}

{{- define "releasea-worker.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- include "releasea-worker.fullname" . -}}
{{- end -}}
{{- else -}}
{{- .Values.serviceAccount.name -}}
{{- end -}}
{{- end }}
