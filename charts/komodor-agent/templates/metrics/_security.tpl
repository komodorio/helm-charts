{{- define "metrics.komodorMetrics.securityContext" }}
{{- include "komodorAgent.podSecurityContext" (dict "root" $ "podSecurityContext" .Values.components.komodorMetrics.podSecurityContext "deprecatedSecurityContext" .Values.components.komodorMetrics.securityContext) }}
{{- end }}

{{- define "metrics.komodorMetrics.container.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorMetrics.metrics.securityContext) }}
{{- end }}

{{- define "metrics.komodorMetrics.metricsInit.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorMetrics.metricsInit.securityContext) }}
{{- end }}

{{- define "metrics.komodorDaemon.securityContext" }}
{{- include "komodorAgent.podSecurityContext" (dict "root" $ "podSecurityContext" .Values.components.komodorDaemon.podSecurityContext "deprecatedSecurityContext" .Values.components.komodorDaemon.securityContext) }}
{{- end }}

{{- define "metrics.daemonset.container.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorDaemon.metrics.securityContext) }}
{{- end }}

{{- define "metrics.daemonsetWindows.container.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorDaemonWindows.metrics.securityContext) }}
{{- end }}

{{- define "metrics.daemonsetWindows.metricsInit.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorDaemonWindows.metricsInit.securityContext) }}
{{- end }}

{{- define "metrics.komodorDaemonWindows.securityContext" }}
{{- include "komodorAgent.podSecurityContext" (dict "root" $ "podSecurityContext" .Values.components.komodorDaemonWindows.podSecurityContext) }}
{{- end }}
