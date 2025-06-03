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
  livenessProbe:
    httpGet:
      path: /healthz
      port: 8090
    periodSeconds: 60
    initialDelaySeconds: 15
    failureThreshold: 10
    successThreshold: 1
  readinessProbe:
    httpGet:
      path: /healthz
      port: 8090
    initialDelaySeconds: 5
    periodSeconds: 5
    failureThreshold: 3
    successThreshold: 1
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: KOMOKW_API_KEY
    {{ include "komodorAgent.apiKeySecretRef" . | nindent 4 }}
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  {{- if gt (len .Values.components.komodorDaemon.nodeEnricher.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemon.nodeEnricher.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}
