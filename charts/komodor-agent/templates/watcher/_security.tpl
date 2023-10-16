{{- define "komodorAgent.securityContext" }}
securityContext:
  readOnlyRootFilesystem: true
  runAsUser: 1000
  runAsGroup: 1000
  allowPrivilegeEscalation: false
{{- end }}