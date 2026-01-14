{{- define "metrics.komodorMetrics.securityContext" }}
{{- if gt (len .Values.components.komodorMetrics.securityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorMetrics.securityContext | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.komodorDaemon.securityContext" }}
{{- if .Values.components.komodorDaemon.securityContext }}
securityContext:
  runAsNonRoot: {{ .Values.components.komodorDaemon.securityContext.runAsNonRoot | default true }}
  {{- if .Values.components.komodorDaemon.securityContext.runAsUser }}
  runAsUser: {{ .Values.components.komodorDaemon.securityContext.runAsUser }}
  {{- end }}
  {{- if .Values.components.komodorDaemon.securityContext.runAsGroup }}
  runAsGroup: {{ .Values.components.komodorDaemon.securityContext.runAsGroup }}
  {{- end }}
  {{- if .Values.components.komodorDaemon.securityContext.fsGroup }}
  fsGroup: {{ .Values.components.komodorDaemon.securityContext.fsGroup }}
  {{- end }}
  {{- if .Values.components.komodorDaemon.securityContext.seccompProfile }}
  seccompProfile:
    {{- toYaml .Values.components.komodorDaemon.securityContext.seccompProfile | nindent 10 }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "metrics.daemonset.container.securityContext" }}
{{- with .Values.components.komodorDaemon.metrics.securityContext }}
securityContext:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}