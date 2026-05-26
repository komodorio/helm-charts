{{- define "admissionController.pod.securityContext" }}
{{- include "komodorAgent.podSecurityContext" (dict "root" $ "podSecurityContext" .Values.components.admissionController.podSecurityContext "deprecatedSecurityContext" .Values.components.admissionController.securityContext) }}
{{- end }}

{{- define "admissionController.container.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.admissionController.containerSecurityContext) }}
{{- end }}
