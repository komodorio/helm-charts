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
{{- end }}{{- end }}