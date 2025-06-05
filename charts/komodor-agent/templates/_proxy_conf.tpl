{{- define "komodorAgent.proxy-conf" -}}
{{- if .Values.proxy.enabled }}
{{- if .Values.proxy.http }}
- name: {{ .Values.proxy.komodorOnly | ternary "KOMOKW_HTTP_PROXY" "HTTP_PROXY" }}
  value: {{ .Values.proxy.http }}
{{- end }}
{{- if .Values.proxy.https }}
- name: {{ .Values.proxy.komodorOnly | ternary "KOMOKW_HTTPS_PROXY" "HTTPS_PROXY" }}
  value: {{ .Values.proxy.https }}
{{- end }}
{{- if .Values.proxy.no_proxy }}
- name: {{ .Values.proxy.komodorOnly | ternary "KOMOKW_NO_PROXY" "NO_PROXY" }}
  value: {{ .Values.proxy.no_proxy }}
{{- end }}
{{- end }}
{{- end }}

{{- define "komodorMetrics.proxy-conf" }}
{{- if and .Values.proxy.enabled .Values.proxy.komodorOnly }}
- name: USE_SYSTEM_PROXY
  value: "false"
- name: KOMODOR_HTTP_PROXY
  value: {{ if .Values.proxy.http }}{{ .Values.proxy.http }}{{ else if .Values.proxy.https }}{{ .Values.proxy.https }}{{ else }}""{{ end }}
{{- else }}
- name: USE_SYSTEM_PROXY
  value: "true"
{{- if .Values.proxy.http }}
- name: HTTP_PROXY
  value: {{ .Values.proxy.http }}	
{{- end }}
{{- if .Values.proxy.https }}
- name: HTTPS_PROXY
  value: {{ .Values.proxy.https }}
{{- end }}
{{- if .Values.proxy.no_proxy }}	
- name: NO_PROXY
  value: {{ .Values.proxy.no_proxy }}
{{- end }}
{{- end }}
{{- end }}
