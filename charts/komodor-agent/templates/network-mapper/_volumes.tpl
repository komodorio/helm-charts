{{- define "network_mapper.daemonset.volumes" }}
{{- if .Values.capabilities.networkMapper }}
- hostPath:
    path: /proc
    type: ""
  name: proc
{{- end }}
{{- end }}