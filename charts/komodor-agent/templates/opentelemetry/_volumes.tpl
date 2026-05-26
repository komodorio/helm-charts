{{- define "opentelemetry.volume" }}
{{- if and .Values.capabilities.telemetry.enabled .Values.capabilities.telemetry.deployOtelCollector }}
{{- $volumes := .Values.components.komodorDaemon.opentelemetry.volumes | default dict -}}
{{- $varlogpods := $volumes.varlogpods | default dict -}}
{{- $varlibdockercontainers := $volumes.varlibdockercontainers | default dict -}}
{{- with $varlogpods.hostPath }}
- name: opentelemetry-varlogpods
  hostPath:
    path: {{ .path }}
    type: {{ .type }}
{{- end }}
{{- with $varlibdockercontainers.hostPath }}
- name: opentelemetry-varlib-docker-containers
  hostPath:
    path: {{ .path }}
    type: {{ .type }}
{{- end }}
{{- if .Values.components.komodorDaemon.opentelemetry.otelInit.enabled }}
- name: {{ include "opentelemetry.shared.volume.name" . }}
  emptyDir: {}
{{- else }}
- name: opentelemetry-config
  configMap:
    name: {{ include "komodorAgent.fullname" . }}-opentelemetry-config
{{- end }}
{{- end }}
{{- end }}
