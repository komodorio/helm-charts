{{- define "k8s-watcher.proxy-conf" -}}
{{- if .Values.proxy.enabled }}
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
{{- end }}{{- end }}