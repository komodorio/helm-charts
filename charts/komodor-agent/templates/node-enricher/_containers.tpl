{{- define "node_enricher.daemonset.container" }}
{{- if .Values.capabilities.nodeEnricher }}
- name: node-enricher
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.nodeEnricher.image.name}}:{{ .Values.components.komodorDaemon.nodeEnricher.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorDaemon.nodeEnricher.resources | trim | nindent 4 }}
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: API_KEY
    value: {{ .Values.apiKey }}
  - name: CLUSTER_NAME
    value: {{ .Values.clusterName }}
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: SERVER_HOST
    value: {{ .Values.communications.serverHost }}
  {{- if gt (len .Values.components.komodorDaemon.nodeEnricher.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemon.nodeEnricher.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}
