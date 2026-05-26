{{- define "komodorAgent.watcher.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorAgent.watcher.securityContext "defaultSecurityContext" (dict "readOnlyRootFilesystem" true "runAsUser" 1000 "runAsGroup" 1000 "allowPrivilegeEscalation" false)) }}
{{- end }}

{{- define "komodorAgent.supervisor.securityContext" }}
{{- include "komodorAgent.container.securityContext" (dict "root" $ "securityContext" .Values.components.komodorAgent.supervisor.securityContext "defaultSecurityContext" (dict "readOnlyRootFilesystem" true "runAsUser" 1000 "runAsGroup" 1000 "allowPrivilegeEscalation" false)) }}
{{- end }}

{{- define "komodorAgent.customCaInit.securityContext" }}
securityContext:
{{- if gt (len .Values.customCa.securityContext) 0 }}
  {{- toYaml .Values.customCa.securityContext | nindent 2 }}
{{- else }}
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  allowPrivilegeEscalation: false
{{- end }}
{{- end }}

{{- define "komodorAgent.pod.securityContext" }}
{{- include "komodorAgent.podSecurityContext" (dict "root" $ "podSecurityContext" .Values.components.komodorAgent.podSecurityContext "deprecatedSecurityContext" .Values.components.komodorAgent.securityContext "defaultSecurityContext" (dict "runAsUser" 0 "runAsGroup" 0)) }}
{{- end }}
