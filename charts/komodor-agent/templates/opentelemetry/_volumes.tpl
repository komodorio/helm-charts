{{- define "opentelemetry.volume" }}
{{- if and .Values.capabilities.telemetry.enabled .Values.capabilities.telemetry.deployOtelCollector }}
- name: opentelemetry-config
  configMap:
    name: {{ include "komodorAgent.fullname" . }}-opentelemetry-config
{{- end }}
{{- end }} 