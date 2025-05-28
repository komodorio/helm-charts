{{- define "metrics.komodorMetrics.securityContext" }}
{{- if gt (len .Values.components.komodorMetrics.securityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorMetrics.securityContext | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.komodorDaemon.securityContext" }}
{{- if gt (len .Values.components.komodorDaemon.securityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorDaemon.securityContext | nindent 2 }}
{{- end }}
{{- end }}

