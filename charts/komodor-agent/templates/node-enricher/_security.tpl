{{- define "node_enricher.daemonset.container.securityContext" }}
{{- with .Values.components.komodorDaemon.nodeEnricher.securityContext }}
securityContext:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}