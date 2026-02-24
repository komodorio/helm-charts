{{- define "opentelemetry.daemonset.container.securityContext" }}
{{- with .Values.components.komodorDaemon.opentelemetry.securityContext }}
securityContext:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}