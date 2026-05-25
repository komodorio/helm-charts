{{- define "gpuAccess.pod.securityContext" }}
{{- include "komodorAgent.podSecurityContext" (dict "root" $ "podSecurityContext" .Values.components.gpuAccess.podSecurityContext) }}
{{- end }}

{{- define "gpuAccess.container.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.gpuAccess.containerSecurityContext "defaultSecurityContext" (dict "privileged" .Values.components.gpuAccess.enabled)) }}
{{- end }}
