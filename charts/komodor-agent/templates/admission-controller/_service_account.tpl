{{/*
Create the name of the admission controller service account to use
*/}}
{{- define "komodorAgent.admissionController.serviceAccountName" -}}
{{- if .Values.components.admissionController.serviceAccount.create }}
{{- default (include "komodorAgent.admissionController.fullname" .) .Values.components.admissionController.serviceAccount.name }}
{{- else }}
{{- .Values.components.admissionController.serviceAccount.name }}
{{- end }}
{{- end }} 