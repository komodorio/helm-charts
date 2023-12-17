{{- define "node_enricher.daemonset.container" }}
{{- if .Values.capabilities.nodeEnricher }}
- name: node-enricher
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.nodeEnricher.image.name}}:{{ .Values.components.komodorDaemon.nodeEnricher.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  command: ["node_enricher"]
  resources:
    {{ toYaml .Values.components.komodorDaemon.nodeEnricher.resources | trim | nindent 4 }}
  volumeMounts:
  - name: configuration
    mountPath: /etc/komodor
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: KOMOKW_API_KEY
    valueFrom:
      secretKeyRef:
        {{- if .Values.apiKeySecret }}
        name: {{ .Values.apiKeySecret | required "Existing secret name required!" }}
        key: apiKey
        {{- else }}
        name: {{ include "komodorAgent.secret.name" . }}
        key: apiKey
        {{- end }}
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  {{- if gt (len .Values.components.komodorDaemon.nodeEnricher.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemon.nodeEnricher.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}
