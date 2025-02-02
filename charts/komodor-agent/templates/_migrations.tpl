{{- define "migrateHelmValues" -}}
{{- if eq (typeOf .Values.capabilities.helm) "bool" -}}
  {{- $helmMap := dict "enabled" .Values.capabilities.helm "readonly" false -}}
  {{- $_ := set .Values.capabilities "helm" $helmMap -}}
{{- end -}}
{{- end -}}