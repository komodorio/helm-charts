{{- define "kubectlProxy.pod.securityContext" }}
{{- if gt (len .Values.components.komodorKubectlProxy.podSecurityContext) 0 }}
securityContext:
  {{- toYaml .Values.components.komodorKubectlProxy.podSecurityContext | nindent 2 }}
{{- else if gt (len .Values.components.komodorKubectlProxy.securityContext) 0 }}
securityContext:
  {{- omit .Values.components.komodorKubectlProxy.securityContext "capabilities" "readOnlyRootFilesystem" "allowPrivilegeEscalation" | toYaml | nindent 2 }}
{{- end }}
{{- end }}

{{- define "kubectlProxy.container.securityContext" }}
{{- if gt (len .Values.components.komodorKubectlProxy.containerSecurityContext) 0 }}
securityContext:
  {{- toYaml .Values.components.komodorKubectlProxy.containerSecurityContext | nindent 2 }}
{{- else if gt (len .Values.components.komodorKubectlProxy.securityContext) 0 }}
securityContext:
  {{- omit .Values.components.komodorKubectlProxy.securityContext "fsGroup" | toYaml | nindent 2 }}
{{- end }}
{{- end }}
