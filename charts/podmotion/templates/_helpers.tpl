{{/*
Expand the name of the chart.
*/}}
{{- define "podmotion.name" -}}
{{- default "komodor-podmotion" .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "podmotion.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- default "komodor-podmotion" .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "podmotion.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "podmotion.labels" -}}
helm.sh/chart: {{ include "podmotion.chart" . }}
{{ include "podmotion.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "podmotion.selectorLabels" -}}
app.kubernetes.io/name: {{ include "podmotion.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "podmotion.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default "komodor-podmotion-node" .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the namespace name
*/}}
{{- define "podmotion.namespace" -}}
{{- .Release.Namespace }}
{{- end }}

{{/*
Create image registry prefix
*/}}
{{- define "podmotion.imageRegistry" -}}
{{- if .Values.global.imageRegistry }}
{{- printf "%s/" .Values.global.imageRegistry }}
{{- end }}
{{- end }}

{{/*
Create installer image name
*/}}
{{- define "podmotion.installerImage" -}}
{{- printf "%s%s:%s" (include "podmotion.imageRegistry" .) .Values.images.installer.repository .Values.images.installer.tag }}
{{- end }}

{{/*
Create manager image name
*/}}
{{- define "podmotion.managerImage" -}}
{{- printf "%s%s:%s" (include "podmotion.imageRegistry" .) .Values.images.manager.repository .Values.images.manager.tag }}
{{- end }}

{{/*
Create alpine image name
*/}}
{{- define "podmotion.alpineImage" -}}
{{- printf "%s%s:%s" (include "podmotion.imageRegistry" .) .Values.images.alpine.repository .Values.images.alpine.tag }}
{{- end }}

{{/*
Create CRIU image name
*/}}
{{- define "podmotion.criuImage" -}}
{{- printf "%s%s:%s" (include "podmotion.imageRegistry" .) .Values.images.criu.repository .Values.images.criu.tag }}
{{- end }}

{{/*
Create node selector labels for daemonset
*/}}
{{- define "podmotion.nodeSelector" -}}
app.kubernetes.io/name: {{ include "podmotion.name" . }}
{{- end }}

{{/*
Create common pod labels
*/}}
{{- define "podmotion.podLabels" -}}
{{ include "podmotion.nodeSelector" . }}
{{- with .Values.podLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Component version environment variables
*/}}
{{- define "podmotion.versionEnvVars" -}}
- name: PODMOTION_INSTALLER_VERSION
  value: {{ .Values.images.installer.tag | quote }}
- name: PODMOTION_MANAGER_VERSION
  value: {{ .Values.images.manager.tag | quote }}
- name: PODMOTION_CRIU_VERSION
  value: {{ .Values.images.criu.tag | quote }}
- name: PODMOTION_CHART_VERSION
  value: {{ .Chart.Version | quote }}
{{- end }}
