{{- define "admissionController.pod.securityContext" }}
{{- if gt (len .Values.components.admissionController.podSecurityContext) 0 }}
securityContext:
  {{- toYaml .Values.components.admissionController.podSecurityContext | nindent 2 }}
{{- else if gt (len .Values.components.admissionController.securityContext) 0 }}
securityContext:
  {{- toYaml .Values.components.admissionController.securityContext | nindent 2 }}
{{- end }}
{{- end }}

{{- define "admissionController.container.securityContext" }}
{{- with .Values.components.admissionController.containerSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
