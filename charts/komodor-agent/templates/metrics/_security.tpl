{{- define "metrics.komodorMetrics.securityContext" }}
{{- if gt (len .Values.components.komodorMetrics.securityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorMetrics.securityContext | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.komodorDaemon.securityContext" }}
{{- with .Values.components.komodorDaemon.securityContext}}
securityContext:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.daemonset.container.securityContext" }}
{{- with .Values.components.komodorDaemon.metrics.securityContext }}
securityContext:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}