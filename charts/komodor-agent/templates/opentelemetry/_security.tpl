{{- define "opentelemetry.daemonset.container.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorDaemon.opentelemetry.securityContext) }}
{{- end }}
