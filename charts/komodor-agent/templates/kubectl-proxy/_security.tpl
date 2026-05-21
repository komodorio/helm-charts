{{- define "kubectlProxy.pod.securityContext" }}
{{- include "komodorAgent.podSecurityContext" (dict "root" $ "podSecurityContext" .Values.components.komodorKubectlProxy.podSecurityContext "deprecatedSecurityContext" .Values.components.komodorKubectlProxy.securityContext) }}
{{- end }}

{{- define "kubectlProxy.container.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorKubectlProxy.containerSecurityContext) }}
{{- end }}
