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
{{- else }}
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
{{- end }}
{{- end }}

{{- define "metrics.daemonset.container.securityContext" }}
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
{{- end }}