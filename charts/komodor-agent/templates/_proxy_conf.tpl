{{- define "komodorAgent.proxy-conf" -}}
- name: "KOMOKW_HTTP_PROXY"
  value: {{- if .Values.proxy.http }}{{ .Values.proxy.http }}{{- else if .Values.proxy.https }}{{ .Values.proxy.https }}{{- else }}""{{- end }}
{{- end }}