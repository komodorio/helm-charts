
{{- define "custom-ca.volumeMounts" -}}
{{- if (.Values.customCa).enabled  }}
- name: custom-ca
  mountPath: "/certs/"
  readOnly: true
{{- end }}
{{- end }}

{{- define "custom-ca.volume" -}}
{{- if (.Values.customCa).enabled  }}
- name: custom-ca
  secret:
    secretName: {{ .Values.customCa.secretName }}
{{- end }}
{{- end }}

{{- define "custom-ca.trusted-volume" -}}
{{- if (.Values.customCa).enabled  }}
- name: trusted-ca
  emptyDir: {}
{{- end }}
{{- end }}

{{- define "custom-ca.trusted-volumeMounts" -}}
{{- if (.Values.customCa).enabled  }}
- name: trusted-ca
  mountPath: /etc/ssl/certs/
  readOnly: true
{{- end }}
{{- end }}

{{- define "custom-ca.trusted-volumeMounts-init" -}}
{{- if (.Values.customCa).enabled  }}
- name: trusted-ca
  mountPath: /trusted-ca/
  readOnly: false
{{- end }}
{{- end }}
