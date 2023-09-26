
{{- define "custom-ca.volumeMounts" -}}
{{- if ne (default false (.Values.customCa).enabled) false }}
- name: custom-ca
  mountPath: "/certs/"
  readOnly: true
{{- end }}
{{- end }}

{{- define "custom-ca.volume" -}}
{{- if ne (default false (.Values.customCa).enabled) false }}
- name: custom-ca
  secret:
    secretName: {{ .Values.customCa.secretName }}
{{- end }}
{{- end }}

{{- define "custom-ca.trusted-volume" -}}
{{- if ne (default false (.Values.customCa).enabled) false }}
- name: trusted-ca
  emptyDir: {}
{{- end }}
{{- end }}

{{- define "custom-ca.trusted-volumeMounts" -}}
{{- if ne (default false (.Values.customCa).enabled) false }}
- name: trusted-ca
  mountPath: /etc/ssl/certs/
  readOnly: true
{{- end }}
{{- end }}

{{- define "custom-ca.trusted-volumeMounts-init" -}}
{{- if ne (default false (.Values.customCa).enabled) false }}
- name: trusted-ca
  mountPath: /trusted-ca/
  readOnly: false
{{- end }}
{{- end }}
