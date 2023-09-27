{{- define "network_mapper.daemonset.network" }}
{{- if .Values.capabilities.networkMapper }}
hostNetwork: true
dnsPolicy: ClusterFirstWithHostNet
{{- end }}
{{- end }}