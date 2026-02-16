{{- define "opentelemetry.volume" }}
{{- if and .Values.capabilities.telemetry.enabled .Values.capabilities.telemetry.deployOtelCollector }}
- name: opentelemetry-varlogpods
  hostPath:
    path: {{ .Values.components.komodorDaemon.opentelemetry.volumes.varlogpods.hostPath.path }}
    type: {{ .Values.components.komodorDaemon.opentelemetry.volumes.varlogpods.hostPath.type }}
- name: opentelemetry-varlib-docker-containers
  hostPath:
    path: {{ .Values.components.komodorDaemon.opentelemetry.volumes.varlibdockercontainers.hostPath.path }}
    type: {{ .Values.components.komodorDaemon.opentelemetry.volumes.varlibdockercontainers.hostPath.type }}
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
