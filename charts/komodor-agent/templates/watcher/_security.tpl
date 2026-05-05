{{- define "komodorAgent.watcher.securityContext" }}
securityContext:
{{- if gt (len .Values.components.komodorAgent.watcher.securityContext) 0 }}
  {{- omit .Values.components.komodorAgent.watcher.securityContext "fsGroup" | toYaml | nindent 2 }}
{{- else }}
  readOnlyRootFilesystem: true
  runAsUser: 1000
  runAsGroup: 1000
  allowPrivilegeEscalation: false
{{- end }}
{{- end }}

{{- define "komodorAgent.supervisor.securityContext" }}
securityContext:
{{- if gt (len .Values.components.komodorAgent.supervisor.securityContext) 0 }}
  {{- omit .Values.components.komodorAgent.supervisor.securityContext "fsGroup" | toYaml | nindent 2 }}
{{- else }}
  readOnlyRootFilesystem: true
  runAsUser: 1000
  runAsGroup: 1000
  allowPrivilegeEscalation: false
{{- end }}
{{- end }}

{{- define "komodorAgent.pod.securityContext" }}
{{- if gt (len .Values.components.komodorAgent.podSecurityContext) 0 }}
securityContext:
  {{- omit .Values.components.komodorAgent.podSecurityContext "capabilities" "readOnlyRootFilesystem" "allowPrivilegeEscalation" | toYaml | nindent 2 }}
{{- else if gt (len .Values.components.komodorAgent.securityContext) 0 }}
securityContext:
  {{- omit .Values.components.komodorAgent.securityContext "capabilities" "readOnlyRootFilesystem" "allowPrivilegeEscalation" | toYaml | nindent 2 }}
{{- end }}
{{- end }}
