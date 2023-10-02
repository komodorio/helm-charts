{{- define "komodorAgent.secret.name" -}}
{{ include "komodorAgent.name" . }}-secret
{{- end -}}