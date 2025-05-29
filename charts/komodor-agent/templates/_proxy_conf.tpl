{{- define "komodorAgent.proxy-conf" }}
{{- if and .Values.proxy.enabled .Values.proxy.komodorOnly }}
- name: USE_SYSTEM_PROXY
  value: "false"
- name: KOMOKW_HTTP_PROXY
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
