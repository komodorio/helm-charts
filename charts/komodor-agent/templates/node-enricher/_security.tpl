{{- define "node_enricher.daemonset.container.securityContext" }}
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
{{- end }}