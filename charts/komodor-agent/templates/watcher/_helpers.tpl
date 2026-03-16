{{- define "komodorAgent.secret.name" -}}
{{ include "komodorAgent.name" . }}-secret
{{- end -}}

{{- define "watcher.container.name" -}}
{{- print "k8s-watcher" | quote }}
{{- end -}}

{{- define "komodorAgent.watcher.healthEndpoint" -}}
{{- printf "http://%s.%s.svc.cluster.local:%v/healthz" (include "komodorAgent.fullname" .) .Release.Namespace .Values.components.komodorAgent.watcher.ports.healthCheck -}}
{{- end -}}
