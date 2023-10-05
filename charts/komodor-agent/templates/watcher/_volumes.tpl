
{{- define "agent.deploy.volumes" }}
- name: agent-configuration
  configMap:
    name: {{ include "komodorAgent.name" . }}-config
    items:
      - key: komodor-k8s-watcher.yaml
        path: komodor-k8s-watcher.yaml
- name: tmp
  emptyDir:
    sizeLimit: 100Mi
- name: podinfo
  downwardAPI:
    items:
      - path: "mem_limit"
        resourceFieldRef:
          containerName: {{ .Chart.Name }}
          resource: limits.memory
          divisor: 1Mi
- name: helm-data
  emptyDir:
    sizeLimit: 256Mi
- name: kube-cache
  emptyDir:
    sizeLimit: 1Gi
{{- end }}