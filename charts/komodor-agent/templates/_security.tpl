{{- define "komodorAgent.container.securityContext" -}}
{{- $root := .root -}}
{{- $securityContext := .securityContext | default dict -}}
{{- $globalSecurityContext := $root.Values.global.securityContext | default dict -}}
{{- $defaultSecurityContext := .defaultSecurityContext | default dict -}}
{{- if gt (len $securityContext) 0 }}
securityContext:
  {{- toYaml $securityContext | nindent 2 }}
{{- else if gt (len $globalSecurityContext) 0 }}
securityContext:
  {{- toYaml $globalSecurityContext | nindent 2 }}
{{- else if gt (len $defaultSecurityContext) 0 }}
securityContext:
  {{- toYaml $defaultSecurityContext | nindent 2 }}
{{- end }}
{{- end }}

{{- define "komodorAgent.podSecurityContext" -}}
{{- $root := .root -}}
{{- $podSecurityContext := .podSecurityContext | default dict -}}
{{- $deprecatedSecurityContext := .deprecatedSecurityContext | default dict -}}
{{- $globalPodSecurityContext := $root.Values.global.podSecurityContext | default dict -}}
{{- $defaultSecurityContext := .defaultSecurityContext | default dict -}}
{{- if gt (len $podSecurityContext) 0 }}
securityContext:
  {{- toYaml $podSecurityContext | nindent 2 }}
{{- else if gt (len $deprecatedSecurityContext) 0 }}
securityContext:
  {{- toYaml $deprecatedSecurityContext | nindent 2 }}
{{- else if gt (len $globalPodSecurityContext) 0 }}
securityContext:
  {{- toYaml $globalPodSecurityContext | nindent 2 }}
{{- else if gt (len $defaultSecurityContext) 0 }}
securityContext:
  {{- toYaml $defaultSecurityContext | nindent 2 }}
{{- end }}
{{- end }}
