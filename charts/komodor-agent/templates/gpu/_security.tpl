{{- define "gpuAccess.pod.securityContext" }}
{{- with .Values.components.gpuAccess.podSecurityContext }}
securityContext:
  {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "gpuAccess.container.securityContext" }}
securityContext:
{{- if gt (len .Values.components.gpuAccess.containerSecurityContext) 0 }}
  {{- toYaml .Values.components.gpuAccess.containerSecurityContext | nindent 2 }}
{{- else }}
  privileged: {{ .Values.components.gpuAccess.enabled }}
{{- end }}
{{- end }}
