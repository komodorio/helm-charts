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

