{{- define "metrics.collector.endpoint" -}}
{{ .Values.communications.serverHost }}/metrics-collector/api/v1/collect
{{- end -}}

{{- define "metrics.daemon.config.name" -}}
{{ include "komodorAgent.name" . }}-daemon-config
{{- end -}}

{{- define "metrics.daemon-windows.config.name" -}}
{{ include "komodorAgent.name" . }}-daemon-windows-config
{{- end -}}