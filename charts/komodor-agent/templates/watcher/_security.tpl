{{- define "komodorAgent.container.securityContext" }}
securityContext:
{{- if gt (len .Values.components.komodorAgent.securityContext) 0 }}
  {{toYaml .Values.components.komodorAgent.securityContext | nindent 2}}
{{- else}}
  readOnlyRootFilesystem: true
  runAsUser: 1000
  runAsGroup: 1000
  allowPrivilegeEscalation: false
{{- end }}
{{- end }}

{{- define "komodorAgent.pod.securityContext" }}
{{- if gt (len .Values.components.komodorAgent.securityContext) 0 }}
securityContext:
  {{- toYaml .Values.components.komodorAgent.securityContext | nindent 2 }}
{{- else }}
securityContext:
  runAsUser: 0
  runAsGroup: 0
{{- end }}
{{- end }}