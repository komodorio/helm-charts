{{ define "communication.apiServerUrl"}}
{{- .Values.communications.apiServerUrl | default "https://kubernetes.default.svc.cluster.local" }}
{{- end }}

{{- define "communication.serverHost" }}
{{- .Values.communications.serverHost | default (ternary "https://app.eu.komodor.com" "https://app.komodor.com" (eq .Values.site "eu")) }}
{{- end }}

{{- define "communication.wsHost" }}
{{- .Values.communications.wsHost | default (ternary "wss://app.eu.komodor.com" "wss://app.komodor.com" (eq .Values.site "eu")) }}
{{- end }}

{{- define "communication.tasksV1ServerHost" }}
{{- .Values.communications.tasksV1ServerHost | default (include "communication.serverHost" .) }}
{{- end }}

{{- define "communication.tasksServerHost" }}
{{- .Values.communications.tasksServerHost | default (include "communication.serverHost" .) }}
{{- end }}

{{- define "communication.telemetryServerHost" }}
{{- .Values.communications.telemetryServerHost | default (ternary "https://telemetry.eu.komodor.com" "https://telemetry.komodor.com" (eq .Values.site "eu")) }}
{{- end }}

{{- define "communication.mgmtServerHost" }}
{{- .Values.communications.mgmtServerHost | default (include "communication.serverHost" .) }}
{{- end }}