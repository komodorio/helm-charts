{{- define "opentelemetry.daemonset.container.securityContext" }}
securityContext:
  runAsUser: 0
  runAsGroup: 0
  runAsNonRoot: false
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
    add:
      - DAC_OVERRIDE
      - SYS_PTRACE
{{- end }}