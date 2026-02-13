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

{{- define "custom-ca.trusted-telegraf-init-container.command" -}}
{{- if (.Values.customCa).enabled  }}
command:
  - /bin/sh
  - -c
  - cp /certs/* /etc/ssl/certs/ &&
    update-ca-certificates --fresh &&
    telegraf_init
{{- end }}
{{- end -}}

{{- define "custom-ca.trusted-otel-init-container.command" -}}
{{- if (.Values.customCa).enabled  }}
command:
  - /bin/sh
  - -c
  - cp /certs/* /etc/ssl/certs/ &&
    update-ca-certificates --fresh &&
    otel_init
{{- end }}
{{- end -}}