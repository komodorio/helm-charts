{{- define "metrics.daemonset.volumes" }}
{{- if .Values.capabilities.metrics }}
- name: {{ include "metrics.daemon.config.name" . }}
  configMap:
    name: {{ include "metrics.daemon.config.name" . }}
- name: configuration
  configMap:
    name: {{ include "komodorAgent.name" . }}-config
    items:
      - key: komodor-k8s-watcher.yaml
        path: komodor-k8s-watcher.yaml
{{- end }}
{{- end }}
