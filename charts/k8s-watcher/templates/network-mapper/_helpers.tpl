{{- define "network.sniffer.fullName" -}}
network-sniffer-{{ .Values.watcher.clusterName }}
{{- end -}}
{{- define "network.mapper.fullName" -}}
network-mapper-{{ .Values.watcher.clusterName }}
{{- end -}}
{{- define "network.mapper.configMapName" -}}
network-mapper-store-{{ .Values.watcher.clusterName }}
{{- end -}}