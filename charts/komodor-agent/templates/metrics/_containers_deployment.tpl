{{- define "metrics.deployment.container" }}
- name: metrics
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorMetrics.metrics.image.name}}:{{ .Values.components.komodorMetrics.metrics.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorMetrics.metrics.resources | trim | nindent 4 }}
  volumeMounts:
  - name: {{ include "metrics.shared.volume.name" . }}
    mountPath: /etc/telegraf
  {{- include "custom-ca.trusted-volumeMounts" . | indent 2 }}
  env:
  {{- include "komodorMetrics.proxy-conf" . | indent 2 }}
  - name: OS_TYPE
    value: linux
  - name: KOMOKW_API_KEY
    {{ include "komodorAgent.apiKeySecretRef" . | indent 4 }}
  - name: KOMODOR_SERVER_URL
    value: {{ .Values.communications.serverHost | quote }}
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: NODE_IP
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
  {{- if gt (len .Values.components.komodorMetrics.metrics.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorMetrics.metrics.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "metrics.deployment.init.container" }}
- name: telegraf-init
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorMetrics.metricsInit.image.name}}:{{ .Values.components.komodorMetrics.metricsInit.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorMetrics.metricsInit.resources | trim | nindent 4 }}
  {{- if .Values.customCa.enabled }}
  {{ include "custom-ca.trusted-telegraf-init-container.command" . | indent 2 }}
  {{- else }}
  command: ["telegraf_init"]
  {{- end }}
  volumeMounts:
  - name: configuration
    mountPath: /etc/komodor
  - name: {{ include "metrics.shared.volume.name" . }}
    mountPath: /etc/telegraf
  {{- include "custom-ca.volumeMounts" . | nindent 2 }}
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: KOMOKW_COMPONENT
    value: {{ .Chart.Name  }}-metrics
  - name: NAMESPACE
    value: {{ .Release.Namespace }}
  - name: KOMOKW_API_KEY
    {{ include "komodorAgent.apiKeySecretRef" . | indent 4 }}
  {{- if gt (len .Values.components.komodorMetrics.metricsInit.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorMetrics.metricsInit.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
