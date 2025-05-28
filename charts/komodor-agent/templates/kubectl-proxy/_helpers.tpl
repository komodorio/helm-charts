# Proxy definitions
{{- define "komodorProxy.labels" -}}
{{ include "komodorProxy.selectorLabels" .}}
{{ include "komodorAgent.commonLabels" . }}
{{- end }}

{{- define "komodorProxy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "komodorAgent.name" . }}-proxy
app.kubernetes.io/instance: {{ include "komodor.truncatedReleaseName"  . }}-proxy
{{- end }}

{{- define "komodorProxy.user.labels" -}}
{{- if not (empty (((.Values.components).komodorKubectlProxy).labels)) }}
{{ toYaml .Values.components.komodorKubectlProxy.labels }}
{{- end }}
{{- end}}

{{/* Proxy pod annotations helper */}}
{{- define "komodorProxy.podAnnotations" -}}
{{- if not (empty (((.Values.components).komodorKubectlProxy).podAnnotations)) }}
{{ toYaml .Values.components.komodorKubectlProxy.podAnnotations | trim | nindent 8 }}
{{- end }}
{{- end }}

{{/* Proxy affinity helper */}}
{{- define "komodorProxy.affinity" -}}
{{- if .Values.components.komodorKubectlProxy.affinity }}
{{ toYaml .Values.components.komodorKubectlProxy.affinity | nindent 8 }}
{{- end }}
{{- end }}

{{/* Proxy nodeSelector helper */}}
{{- define "komodorProxy.nodeSelector" -}}
{{- if not (empty (((.Values.components).komodorKubectlProxy).nodeSelector)) }}
{{ toYaml .Values.components.komodorKubectlProxy.nodeSelector | nindent 8 }}
{{- end }}
{{- end }}

{{/* Proxy tolerations helper */}}
{{- define "komodorProxy.tolerations" -}}
{{- if .Values.components.komodorKubectlProxy.tolerations }}
{{ toYaml .Values.components.komodorKubectlProxy.tolerations | nindent 8 }}
{{- end }}
{{- end }}

{{/* Proxy resources helper */}}
{{- define "komodorProxy.resources" -}}
{{- if .Values.components.komodorKubectlProxy.resources }}
{{ toYaml .Values.components.komodorKubectlProxy.resources | trim | nindent 10 }}
{{- end }}
{{- end }}

{{/* Proxy securityContext helper */}}
{{- define "komodorProxy.securityContext" -}}
{{- if .Values.components.komodorKubectlProxy.securityContext }}
{{ toYaml .Values.components.komodorKubectlProxy.securityContext | nindent 8 }}
{{- end }}
{{- end }}