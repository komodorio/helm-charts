{{- define "proxy.no_proxy_value" -}}
{{- if .Values.proxy.no_proxy_local_addresses -}}
{{- list "localhost" "127.0.0.1" "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" ".cluster.local" ".svc" .Values.proxy.no_proxy | compact | join "," -}}
{{- else -}}
{{- .Values.proxy.no_proxy -}}
{{- end -}}
{{- end }}

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
{{- if or .Values.proxy.no_proxy .Values.proxy.no_proxy_local_addresses }}
- name: {{ .Values.proxy.komodorOnly | ternary "KOMOKW_NO_PROXY" "NO_PROXY" }}
  value: {{ include "proxy.no_proxy_value" . }}
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
{{- if or .Values.proxy.no_proxy .Values.proxy.no_proxy_local_addresses }}
- name: NO_PROXY
  value: {{ include "proxy.no_proxy_value" . }}
{{- end }}
{{- end }}
{{- end }}

{{- define "opentelemetry.proxy-conf" -}}
{{- if .Values.proxy.enabled }}
{{- if .Values.proxy.http }}
- name: "HTTP_PROXY"
  value: {{ .Values.proxy.http }}
{{- end }}
{{- if .Values.proxy.https }}
- name: "HTTPS_PROXY"
  value: {{ .Values.proxy.https }}
{{- end }}
{{- if or .Values.proxy.no_proxy .Values.proxy.no_proxy_local_addresses }}
- name: "NO_PROXY"
  value: {{ include "proxy.no_proxy_value" . }}
{{- end }}
{{- end }}
{{- end }}
