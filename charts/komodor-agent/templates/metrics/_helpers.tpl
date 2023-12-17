{{- define "metrics.collector.endpoint" -}}
{{ .Values.communications.serverHost }}/metrics-collector/api/v1/collect
{{- end -}}

{{- define "metrics.daemon.config.name" -}}
{{ include "komodorAgent.name" . }}-daemon-config
{{- end -}}