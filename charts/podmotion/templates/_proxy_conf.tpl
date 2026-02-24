{{- define "podmotion.proxy-conf-env" -}}
{{- if .Values.proxy.enabled }}
{{- if .Values.proxy.http }}
- name: {{ .Values.proxy.komodorOnly | ternary "KOMO_HTTP_PROXY" "HTTP_PROXY" }}
  value: {{ .Values.proxy.http }}
{{- end }}
{{- if .Values.proxy.https }}
- name: {{ .Values.proxy.komodorOnly | ternary "KOMO_HTTPS_PROXY" "HTTPS_PROXY" }}
  value: {{ .Values.proxy.https }}
{{- end }}
{{- if .Values.proxy.no_proxy }}
- name: {{ .Values.proxy.komodorOnly | ternary "KOMO_NO_PROXY" "NO_PROXY" }}
  value: {{ .Values.proxy.no_proxy }}
{{- end }}
{{- end }}
{{- end }}
