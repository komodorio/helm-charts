{{/*
Create the name of the service account to use
*/}}
{{- define "komodorAgent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "komodorAgent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the daemon/metrics service account to use
*/}}
{{- define "komodorAgent.daemonMetrics.serviceAccountName" -}}
{{- if .Values.serviceAccount.createDaemonMetrics }}
{{- default (printf "%s-daemon-metrics" (include "komodorAgent.fullname" .)) .Values.serviceAccount.daemonMetricsName }}
{{- else }}
{{- /* Fall back to main service account when dedicated daemon/metrics SA is disabled */}}
{{- include "komodorAgent.serviceAccountName" . }}
{{- end }}
{{- end }}