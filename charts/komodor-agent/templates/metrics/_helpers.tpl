{{- define "metrics.collector.endpoint" -}}
{{ .Values.communications.serverHost }}/metrics-collector/api/v1/collect
{{- end -}}


{{- define "metrics.shared.volume.name" -}}
shared-data
{{- end -}}
