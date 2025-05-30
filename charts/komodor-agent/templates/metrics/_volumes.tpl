{{- define "metrics.agent.configuration"}}
- name: configuration
  configMap:
    name: {{ include "komodorAgent.name" . }}-config
    items:
      - key: komodor-k8s-watcher.yaml
        path: komodor-k8s-watcher.yaml
{{- end }}

{{- define "metrics.shared.volume" }}
{{ include "metrics.agent.configuration" . }}
- name: {{ include "metrics.shared.volume.name" . }}
  emptyDir: {}
{{- end }}

{{- define "metrics.gpuAccess.volumes" }}
{{- if .Values.components.komodorDaemon.gpuAccessContainer.enabled }}
- name: host-root
  hostPath:
    path: /
{{- end }}
{{- end }}

