{{/*This template file should be used for common helpers shared by all components*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "komodorAgent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "komodorAgent.fullname" -}}
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
{{- define "komodorAgent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}

{{- define "komodorAgent.commonLabels" -}}
helm.sh/chart: {{ include "komodorAgent.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.komodor.cluster-name: {{ .Values.clusterName }}
{{- end }}

{{- define "komodorAgent.labels" -}}
{{ include "komodorAgent.selectorLabels" .}}
{{ include "komodorAgent.commonLabels" . }}
{{- end }}

{{- define "komodorAgentDaemon.labels" -}}
{{ include "komodorAgentDaemon.selectorLabels" . }}
{{ include "komodorAgent.commonLabels" . }}
{{- end }}

{{- define "komodorAgentDaemonWindows.labels" -}}
{{ include "komodorAgentDaemonWindows.selectorLabels" . }}
{{ include "komodorAgent.commonLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "komodorAgent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "komodorAgent.name" . }}
app.kubernetes.io/instance: {{ include "komodor.truncatedReleaseName"  . }}
{{- end }}

{{- define "komodorAgent.watcher.selectorLabels" -}}
{{ include "komodorAgent.selectorLabels" . }}
app.kubernetes.io/component: watcher
{{- end }}

{{- define "komodorAgentDaemon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "komodorAgent.name" . }}-daemon
app.kubernetes.io/instance: {{ include "komodor.truncatedReleaseName"  . }}-daemon
{{- end }}

{{- define "komodorAgentDaemonWindows.selectorLabels" -}}
app.kubernetes.io/name: {{ include "komodorAgent.name" . }}-daemon-windows
app.kubernetes.io/instance: {{ include "komodor.truncatedReleaseName"  . }}-daemon-windows
{{- end }}

{{- define "KomodorDaemon.user.labels" -}}
{{- if not (empty (((.Values.components).komodorDaemon).labels)) }}
{{ toYaml .Values.components.komodorDaemon.labels }}
{{- end }}
{{- end}}

{{- define "gpuAccess.selectorLabels" -}}
app.kubernetes.io/name: {{ include "komodorAgent.name" . }}-gpu-access
app.kubernetes.io/instance: {{ include "komodor.truncatedReleaseName"  . }}-gpu-access
{{- end }}

{{- define "gpuAccess.user.labels" -}}
{{- if not (empty (((.Values.components).gpuAccess).labels)) }}
{{ toYaml .Values.components.gpuAccess.labels }}
{{- end }}
{{- end}}

{{- define "gpuAccess.labels" -}}
{{ include "gpuAccess.selectorLabels" . }}
{{ include "komodorAgent.commonLabels" . }}
{{- end }}

{{- define "komodorAgent.user.labels" -}}
{{- if not (empty (((.Values.components).komodorAgent).labels)) }}
{{ toYaml .Values.components.komodorAgent.labels }}
{{- end }}
{{- end}}

{{- define "komodorDaemonWindows.user.labels" -}}
{{- if not (empty (((.Values.components).komodorDaemonWindows).labels)) }}
{{ toYaml .Values.components.komodorDaemonWindows.labels }}
{{- end }}
{{- end}}


# Metrics definitions
{{- define "komodorMetrics.labels" -}}
{{ include "komodorMetrics.selectorLabels" .}}
{{ include "komodorAgent.commonLabels" . }}
{{- end }}

{{- define "komodorMetrics.selectorLabels" -}}
app.kubernetes.io/name: {{ include "komodorAgent.name" . }}-metrics
app.kubernetes.io/instance: {{ include "komodor.truncatedReleaseName"  . }}-metrics
{{- end }}

{{- define "KomodorMetrics.user.labels" -}}
{{- if not (empty (((.Values.components).komodorMetrics).labels)) }}
{{ toYaml .Values.components.komodorMetrics.labels }}
{{- end }}
{{- end}}

{{- define "komodor.truncatedReleaseName" -}}
{{- trunc 40 .Release.Name -}}
{{- end -}}

{{/*
API Key secret reference - returns the entire valueFrom block
*/}}
{{- define "komodorAgent.apiKeySecretRef" -}}
valueFrom:
  secretKeyRef:
    {{- if .Values.apiKeySecret }}
    name: {{ .Values.apiKeySecret | required "Existing secret name required!" }}
    key: apiKey
    {{- else }}
    name: {{ include "komodorAgent.secret.name" . }}
    key: apiKey
    {{- end }}
{{- end }}

{{/*
Public API Key secret name
*/}}
{{- define "komodorAgent.publicApiKey.secret.name" -}}
{{ include "komodorAgent.name" . }}-public-api-key-secret
{{- end -}}

{{/*
GOMEMLIMIT calculation — returns N% (default 90%) of a Kubernetes memory limit
in Go-runtime units (MiB). Falls back to plain unit conversion if ratio is empty
or input has no Ki/Mi/Gi/Ti suffix. Usage:
  {{ include "komodorAgent.goMemLimit" (dict "mem" .Values.x.resources.limits.memory) }}
  {{ include "komodorAgent.goMemLimit" (dict "mem" "8Gi" "ratio" "0.8") }}
*/}}
{{- define "komodorAgent.goMemLimit" -}}
{{- $mem := .mem | toString -}}
{{- $ratio := "0.9" -}}
{{- if hasKey . "ratio" -}}
{{- $ratio = .ratio | toString -}}
{{- end -}}
{{- if and (ne $ratio "") (ne $ratio "0") -}}
  {{- $memMiB := 0.0 -}}
  {{- if hasSuffix "Ti" $mem -}}
  {{- $memMiB = mulf ($mem | trimSuffix "Ti" | float64) 1048576.0 -}}
  {{- else if hasSuffix "Gi" $mem -}}
  {{- $memMiB = mulf ($mem | trimSuffix "Gi" | float64) 1024.0 -}}
  {{- else if hasSuffix "Mi" $mem -}}
  {{- $memMiB = $mem | trimSuffix "Mi" | float64 -}}
  {{- else if hasSuffix "Ki" $mem -}}
  {{- $memMiB = divf ($mem | trimSuffix "Ki" | float64) 1024.0 -}}
  {{- end -}}
  {{- if gt $memMiB 0.0 -}}
  {{- mulf $memMiB ($ratio | float64) | floor | printf "%.0fMiB" -}}
  {{- else -}}
  {{- $mem | replace "Ki" "KiB" | replace "Mi" "MiB" | replace "Gi" "GiB" | replace "Ti" "TiB" -}}
  {{- end -}}
{{- else -}}
  {{- $mem | replace "Ki" "KiB" | replace "Mi" "MiB" | replace "Gi" "GiB" | replace "Ti" "TiB" -}}
{{- end -}}
{{- end -}}

{{/*
Public API Key secret reference - returns the entire valueFrom block
*/}}
{{- define "komodorAgent.publicApiKeySecretRef" -}}
valueFrom:
  secretKeyRef:
    {{- if .Values.publicApiKeySecret }}
    name: {{ .Values.publicApiKeySecret | required "Existing secret name required!" }}
    key: {{ default "publicApiKey" .Values.publicApiKeySecretKey }}
    {{- else }}
    name: {{ include "komodorAgent.publicApiKey.secret.name" . }}
    key: {{ default "publicApiKey" .Values.publicApiKeySecretKey }}
    {{- end }}
{{- end }}
