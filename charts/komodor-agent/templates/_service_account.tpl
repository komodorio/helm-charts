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

{{/*
Role name for Klaudia integration sync (namespaced RBAC)
*/}}
{{- define "komodorAgent.role.klaudiaIntegrationSync" -}}
{{- printf "%s-klaudia-integration-sync" (include "komodorAgent.fullname" .) }}
{{- end }}

{{/*
ClusterRole name for impersonation (users + pinned group)
*/}}
{{- define "komodorAgent.clusterRole.impersonation" -}}
{{- printf "%s-impersonation" (include "komodorAgent.fullname" .) }}
{{- end }}

{{/*
The group the agent impersonates to carry k8s-watcher permissions.
Must match exactly what the agent code passes as --as-group.
*/}}
{{- define "komodorAgent.impersonationGroup" -}}
komodor:agent-actions
{{- end }}