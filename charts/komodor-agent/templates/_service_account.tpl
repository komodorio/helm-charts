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

{{/*
Create the name of the daemon-metrics service account to use
*/}}
{{- define "komodorAgent.daemonMetrics.serviceAccountName" -}}
{{- printf "%s-daemon-metrics" (include "komodorAgent.fullname" .) }}
{{- end }}

{{/*
ClusterRole name for k8s-watcher container (read/watch permissions)
*/}}
{{- define "komodorAgent.clusterRole.k8sWatcher" -}}
{{- printf "%s-k8s-watcher" (include "komodorAgent.fullname" .) }}
{{- end }}

{{/*
ClusterRole name for metrics deployment container
*/}}
{{- define "komodorAgent.clusterRole.metricsDeployment" -}}
{{- printf "%s-metrics-deployment" (include "komodorAgent.fullname" .) }}
{{- end }}

{{/*
ClusterRole name for node-enricher container
*/}}
{{- define "komodorAgent.clusterRole.nodeEnricher" -}}
{{- printf "%s-node-enricher" (include "komodorAgent.fullname" .) }}
{{- end }}