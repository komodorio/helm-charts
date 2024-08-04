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
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "komodorAgentDaemon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "komodorAgent.name" . }}-daemon
app.kubernetes.io/instance: {{ .Release.Name }}-daemon
{{- end }}

{{- define "komodorAgentDaemonWindows.selectorLabels" -}}
app.kubernetes.io/name: {{ include "komodorAgent.name" . }}-daemon-windows
app.kubernetes.io/instance: {{ .Release.Name }}-daemon-windows
{{- end }}

{{- define "KomodorDaemon.user.labels" -}}
{{- if not (empty (((.Values.components).komodorDaemon).labels)) }}
{{ toYaml .Values.components.komodorDaemon.labels }}
{{- end }}
{{- end}}

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
app.kubernetes.io/instance: {{ .Release.Name }}-metrics
{{- end }}

{{- define "KomodorMetrics.user.labels" -}}
{{- if not (empty (((.Values.components).komodorMetrics).labels)) }}
{{ toYaml .Values.components.komodorMetrics.labels }}
{{- end }}
{{- end}}
