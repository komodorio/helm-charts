{{- define "metrics.komodorMetrics.securityContext" }}
{{- if gt (len .Values.components.komodorMetrics.podSecurityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorMetrics.podSecurityContext | nindent 2 }}
{{- else if gt (len .Values.components.komodorMetrics.securityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorMetrics.securityContext | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.komodorMetrics.container.securityContext" }}
{{- with .Values.components.komodorMetrics.metrics.securityContext }}
securityContext:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.komodorMetrics.metricsInit.securityContext" }}
{{- with .Values.components.komodorMetrics.metricsInit.securityContext }}
securityContext:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.komodorDaemon.securityContext" }}
{{- if gt (len .Values.components.komodorDaemon.podSecurityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorDaemon.podSecurityContext | nindent 2 }}
{{- else if gt (len .Values.components.komodorDaemon.securityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorDaemon.securityContext | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.daemonset.container.securityContext" }}
{{- with .Values.components.komodorDaemon.metrics.securityContext }}
securityContext:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}
