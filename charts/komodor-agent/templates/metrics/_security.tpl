{{- define "metrics.komodorMetrics.securityContext" }}
{{- if gt (len .Values.components.komodorMetrics.securityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorMetrics.securityContext | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.komodorDaemon.securityContext" }}
securityContext:
{{- with .Values.components.komodorDaemon.securityContext }}
  {{ toYaml . | nindent 2 }}
{{- else }}
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
{{- end }}
{{- end }}

{{- define "metrics.daemonset.container.securityContext" }}
{{- with .Values.components.komodorDaemon.metrics.securityContext }}
securityContext:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}
