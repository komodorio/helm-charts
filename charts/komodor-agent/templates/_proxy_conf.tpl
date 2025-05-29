{{- define "komodorAgent.proxy-conf" }}
{{- if or .Values.proxy.http .Values.proxy.https }}
- name: KOMOKW_HTTP_PROXY
  value: {{ .Values.proxy.http | default .Values.proxy.https | quote }}
{{- end }}
{{- end }}