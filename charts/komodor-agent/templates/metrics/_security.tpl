{{- define "metrics.komodorMetrics.securityContext" }}
{{- if gt (len .Values.components.komodorMetrics.podSecurityContext) 0 }}
securityContext:
  {{ omit .Values.components.komodorMetrics.podSecurityContext "capabilities" "readOnlyRootFilesystem" "allowPrivilegeEscalation" | toYaml | nindent 2 }}
{{- else if gt (len .Values.components.komodorMetrics.securityContext) 0 }}
securityContext:
  {{ omit .Values.components.komodorMetrics.securityContext "capabilities" "readOnlyRootFilesystem" "allowPrivilegeEscalation" | toYaml | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.komodorMetrics.container.securityContext" }}
{{- if gt (len .Values.components.komodorMetrics.metrics.securityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorMetrics.metrics.securityContext | nindent 2 }}
{{- else if gt (len .Values.components.komodorMetrics.securityContext) 0 }}
securityContext:
  {{ omit .Values.components.komodorMetrics.securityContext "fsGroup" | toYaml | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.komodorMetrics.metricsInit.securityContext" }}
{{- if gt (len .Values.components.komodorMetrics.metricsInit.securityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorMetrics.metricsInit.securityContext | nindent 2 }}
{{- else if gt (len .Values.components.komodorMetrics.securityContext) 0 }}
securityContext:
  {{ omit .Values.components.komodorMetrics.securityContext "fsGroup" | toYaml | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.komodorDaemon.securityContext" }}
{{- if gt (len .Values.components.komodorDaemon.podSecurityContext) 0 }}
securityContext:
  {{ omit .Values.components.komodorDaemon.podSecurityContext "capabilities" "readOnlyRootFilesystem" "allowPrivilegeEscalation" | toYaml | nindent 2 }}
{{- else if gt (len .Values.components.komodorDaemon.securityContext) 0 }}
securityContext:
  {{ omit .Values.components.komodorDaemon.securityContext "capabilities" "readOnlyRootFilesystem" "allowPrivilegeEscalation" | toYaml | nindent 2 }}
{{- end }}
{{- end }}

{{- define "metrics.daemonset.container.securityContext" }}
{{- if gt (len .Values.components.komodorDaemon.metrics.securityContext) 0 }}
securityContext:
  {{ toYaml .Values.components.komodorDaemon.metrics.securityContext | nindent 2 }}
{{- else if gt (len .Values.components.komodorDaemon.securityContext) 0 }}
securityContext:
  {{ omit .Values.components.komodorDaemon.securityContext "fsGroup" | toYaml | nindent 2 }}
{{- end }}
{{- end }}
