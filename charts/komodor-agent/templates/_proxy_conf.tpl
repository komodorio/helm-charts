{{- define "komodorAgent.proxy-conf" }}
- name: KOMOKW_HTTP_PROXY
  value: {{ .Values.proxy.http | default .Values.proxy.https | quote }}
{{- end }}