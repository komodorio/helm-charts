{{- define "node_enricher.daemonset.container.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorDaemon.nodeEnricher.securityContext) }}
{{- end }}
