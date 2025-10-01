{{- define "opentelemetry.volume" }}
{{- if and .Values.capabilities.telemetry.enabled .Values.capabilities.telemetry.deployOtelCollector }}
- name: opentelemetry-varlogpods
  hostPath:
    path: {{ .Values.components.komodorDaemon.opentelemetry.volumes.varlogpods.hostPath.path }}
    type: {{ .Values.components.komodorDaemon.opentelemetry.volumes.varlogpods.hostPath.type }}
- name: opentelemetry-config
  configMap:
    name: {{ include "komodorAgent.fullname" . }}-opentelemetry-config
{{- end }}
{{- end }} 