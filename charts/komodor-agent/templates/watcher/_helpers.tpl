{{- define "komodorAgent.secret.name" -}}
{{ include "komodorAgent.name" . }}-secret
{{- end -}}

{{- define "watcher.container.name" -}}
{{- print "k8s-watcher" | quote }}
{{- end -}}
