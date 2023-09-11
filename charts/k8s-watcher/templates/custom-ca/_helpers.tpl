{{- define "custom-ca.lifecycle" -}}
{{- if ne (.Values.customCa).enabled false }}
lifecycle:
  postStart:
    exec:
      command:
        - sh
        - -c
        - cp /certs/* /etc/ssl/certs/ && update-ca-certificates --fresh
{{- end }}
{{- end }}

{{- define "custom-ca.volumeMounts" -}}
{{- if ne (.Values.customCa).enabled false }}
- name: custom-ca
  mountPath: "/certs/"
  readOnly: true
{{- end }}
{{- end }}

{{- define "custom-ca.volume" -}}
{{- if ne (.Values.customCa).enabled false }}
- name: custom-ca
  secret:
    secretName: {{ .Values.customCa.secretName }}
{{- end }}
{{- end }}

{{- define "custom-ca.trusted-volume" -}}
{{- if ne (.Values.customCa).enabled false }}
- name: trusted-ca
  emptyDir: {}
{{- end }}
{{- end }}

{{- define "custom-ca.trusted-volumeMounts" -}}
{{- if ne (.Values.customCa).enabled false }}
- name: trusted-ca
  mountPath: /etc/ssl/certs/
  readOnly: true
{{- end }}
