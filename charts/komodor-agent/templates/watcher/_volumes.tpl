
{{- define "agent.deploy.volumes" }}
- name: agent-configuration
  configMap:
    name: {{ include "komodorAgent.name" . }}-config
    items:
      - key: komodor-k8s-watcher.yaml
        path: komodor-k8s-watcher.yaml
      - key: installed-values.yaml
        path: installed-values.yaml
- name: tmp
  emptyDir:
    sizeLimit: 100Mi
- name: podinfo
  downwardAPI:
    items:
      - path: "mem_limit"
        resourceFieldRef:
          containerName: {{ include "watcher.container.name" . }}
          resource: limits.memory
          divisor: 1Mi
- name: helm-data
  emptyDir:
    sizeLimit: 256Mi
- name: kube-cache
  emptyDir:
    sizeLimit: 1Gi
{{- end }}