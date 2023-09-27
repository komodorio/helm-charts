{{- define "network.sniffer.fullName" -}}
network-sniffer-{{ .Values.clusterName }}
{{- end -}}
{{- define "network.mapper.fullName" -}}
network-mapper-{{ .Values.clusterName }}
{{- end -}}
{{- define "network.mapper.configMapName" -}}
network-mapper-store-{{ .Values.clusterName }}
{{- end -}}