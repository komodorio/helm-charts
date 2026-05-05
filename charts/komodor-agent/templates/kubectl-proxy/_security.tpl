{{- define "kubectlProxy.pod.securityContext" }}
{{- if gt (len .Values.components.komodorKubectlProxy.podSecurityContext) 0 }}
securityContext:
  {{- toYaml .Values.components.komodorKubectlProxy.podSecurityContext | nindent 2 }}
{{- else if gt (len .Values.components.komodorKubectlProxy.securityContext) 0 }}
securityContext:
  {{- toYaml .Values.components.komodorKubectlProxy.securityContext | nindent 2 }}
{{- end }}
{{- end }}

{{- define "kubectlProxy.container.securityContext" }}
{{- with .Values.components.komodorKubectlProxy.containerSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
