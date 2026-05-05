{{- define "admissionController.pod.securityContext" }}
{{- if gt (len .Values.components.admissionController.podSecurityContext) 0 }}
securityContext:
  {{- toYaml .Values.components.admissionController.podSecurityContext | nindent 2 }}
{{- else if gt (len .Values.components.admissionController.securityContext) 0 }}
securityContext:
  {{- omit .Values.components.admissionController.securityContext "capabilities" "readOnlyRootFilesystem" "allowPrivilegeEscalation" | toYaml | nindent 2 }}
{{- end }}
{{- end }}

{{- define "admissionController.container.securityContext" }}
{{- if gt (len .Values.components.admissionController.containerSecurityContext) 0 }}
securityContext:
  {{- toYaml .Values.components.admissionController.containerSecurityContext | nindent 2 }}
{{- else if gt (len .Values.components.admissionController.securityContext) 0 }}
securityContext:
  {{- omit .Values.components.admissionController.securityContext "fsGroup" | toYaml | nindent 2 }}
{{- end }}
{{- end }}
