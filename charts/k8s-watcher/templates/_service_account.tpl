{{/*
Create the name of the service account to use
*/}}
{{- define "komodorAgent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "komodorAgent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- required "you must provide a serviceAccount.name when serviceAccount.create is not set to true " .Values.serviceAccount.name  }}
{{- end }}
{{- end }}