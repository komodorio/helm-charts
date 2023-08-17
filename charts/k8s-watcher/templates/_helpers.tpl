{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "k8s-watcher.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "k8s-watcher.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "k8s-watcher.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "k8s-watcher.labels" -}}
helm.sh/chart: {{ include "k8s-watcher.chart" . }}
{{ include "k8s-watcher.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "k8s-watcher.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8s-watcher.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common daemon labels
*/}}
{{- define "daemon.labels" -}}
helm.sh/chart: {{ include "k8s-watcher.chart" . }}
{{ include "daemon.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector daemon labels
*/}}
{{- define "daemon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8s-watcher.name" . }}-daemon
app.kubernetes.io/instance: {{ .Release.Name }}-daemon
{{- end }}

{{/*
Selector daemon server host
*/}}
{{- define "daemon.serverHost" -}}
{{- default "https://app.komodor.com" .Values.watcher.serverHost }}
{{- end }}

{{/*
Api server url
*/}}
{{- define "daemon.apiServerUrl" -}}
{{- default "https://kubernetes.default.svc.cluster.local" .Values.watcher.serverHost }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "k8s-watcher.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "k8s-watcher.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "watcher.values" -}}
{{- $daemonEnabledValues := dict "daemon" (dict "enabled" ((.Values.metrics).enabled | default false)) }}
{{- mergeOverwrite .Values.watcher $daemonEnabledValues  | toYaml  }}
{{- end }}
