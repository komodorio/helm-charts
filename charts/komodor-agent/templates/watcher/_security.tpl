{{- define "komodorAgent.watcher.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorAgent.watcher.securityContext "defaultSecurityContext" (dict "readOnlyRootFilesystem" true "runAsUser" 1000 "runAsGroup" 1000 "allowPrivilegeEscalation" false)) }}
{{- end }}

{{- define "komodorAgent.supervisor.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorAgent.supervisor.securityContext "defaultSecurityContext" (dict "readOnlyRootFilesystem" true "runAsUser" 1000 "runAsGroup" 1000 "allowPrivilegeEscalation" false)) }}
{{- end }}

{{- define "komodorAgent.pod.securityContext" }}
{{- include "komodorAgent.podSecurityContext" (dict "root" $ "podSecurityContext" .Values.components.komodorAgent.podSecurityContext "deprecatedSecurityContext" .Values.components.komodorAgent.securityContext "defaultSecurityContext" (dict "runAsUser" 0 "runAsGroup" 0)) }}
{{- end }}
