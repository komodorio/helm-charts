{{/*
Create the name of the admission controller service account to use
*/}}
{{- define "komodorAgent.admissionController.serviceAccountName" -}}
{{- if .Values.components.admissionController.serviceAccount.create }}
{{- default (include "komodorAgent.admissionController.fullname" .) .Values.components.admissionController.serviceAccount.name }}
{{- else }}
{{- required "you must provide a components.admissionController.serviceAccount.name when components.admissionController.serviceAccount.create is not set to true" .Values.components.admissionController.serviceAccount.name }}
{{- end }}
{{- end }} 