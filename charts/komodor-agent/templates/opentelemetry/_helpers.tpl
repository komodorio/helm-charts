{{- define "komodorAgent.openTelemetry.serviceName" -}}
{{- printf "%s-otel-collector" (include "komodorAgent.fullname" .) -}}
{{- end -}}

{{- define "komodorAgent.openTelemetry.serviceFqdn" -}}
{{- printf "http://%s.%s.svc.cluster.local:4318" (include "komodorAgent.openTelemetry.serviceName" .) .Release.Namespace -}}
{{- end -}}