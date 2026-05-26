{{- define "komodorAgent.container.securityContext" -}}
{{- $root := .root -}}
{{- $securityContext := .securityContext | default dict -}}
{{- $globalSecurityContext := $root.Values.global.securityContext | default dict -}}
{{- $defaultSecurityContext := .defaultSecurityContext | default dict -}}
{{- $mergedSecurityContext := mergeOverwrite (deepCopy $defaultSecurityContext) (deepCopy $globalSecurityContext) (deepCopy $securityContext) -}}
{{- if gt (len $mergedSecurityContext) 0 }}
securityContext:
  {{- toYaml $mergedSecurityContext | nindent 2 }}
{{- end }}
{{- end }}

{{- define "komodorAgent.podSecurityContext" -}}
{{- $root := .root -}}
{{- $podSecurityContext := .podSecurityContext | default dict -}}
{{- $deprecatedSecurityContext := .deprecatedSecurityContext | default dict -}}
{{- $globalPodSecurityContext := $root.Values.global.podSecurityContext | default dict -}}
{{- $defaultSecurityContext := .defaultSecurityContext | default dict -}}
{{- $mergedSecurityContext := mergeOverwrite (deepCopy $defaultSecurityContext) (deepCopy $globalPodSecurityContext) (deepCopy $deprecatedSecurityContext) (deepCopy $podSecurityContext) -}}
{{- if gt (len $mergedSecurityContext) 0 }}
securityContext:
  {{- toYaml $mergedSecurityContext | nindent 2 }}
{{- end }}
{{- end }}
