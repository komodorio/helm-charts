{{/*
Create the name of the service account to use
*/}}
{{- define "komodorAgent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "komodorAgent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- .Values.serviceAccount.name }}
{{- end }}
{{- end }}