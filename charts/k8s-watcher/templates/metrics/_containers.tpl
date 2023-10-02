{{- define "metrics.container" -}}
{{- if .Values.capabilities.metrics -}}
- name: metrics
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.metrics.image.name}}:{{ .Values.components.komodorAgent.metrics.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorAgent.metrics.resources | trim | nindent 4 }}
  volumeMounts:
  - name: {{ include "metrics.config.name" . }}
    mountPath: /etc/telegraf/telegraf.conf
    subPath: telegraf.conf
  {{- include "custom-ca.trusted-volumeMounts" . | indent 2 }}
  envFrom:
  - configMapRef:
      name:  "k8s-watcher-daemon-env-vars"
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 12 }}
  - name: CLUSTER_NAME
    value: {{ .Values.clusterName }}
{{- end }}
{{- end }}

{{- define "metrics.daemonset.container" }}
{{- if .Values.capabilities.metrics }}
- name: metrics
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.metrics.image.name}}:{{ .Values.components.komodorAgent.metrics.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorAgent.metrics.resources | trim | nindent 4 }}
  volumeMounts:
  - name: {{ include "metrics.daemon.config.name" . }}
    mountPath: /etc/telegraf/telegraf.conf
    subPath: telegraf.conf
  envFrom:
  - configMapRef:
      name:  "k8s-watcher-daemon-env-vars"
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 12 }}
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: NODE_IP
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
  - name: CLUSTER_NAME
    value: {{ .Values.clusterName }}
{{- end }}
{{- end }}

{{- define "metrics.daemonset.init.container" }}
{{- if .Values.capabilities.metrics }}
- name: init-daemon
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.metricsInit.image.name}}:{{ .Values.components.komodorDaemon.metricsInit.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorDaemon.metricsInit.resources | trim | nindent 4 }}
  {{- if .Values.customCa.enabled }}
  command:
    - /bin/sh
    - -c
    - cp /certs/* /etc/ssl/certs/ &&
      update-ca-certificates --fresh &&
      daemon
  {{- end }}
  volumeMounts:
  - name: configuration
    mountPath: /etc/komodor
  {{- include "custom-ca.volumeMounts" . | nindent 2 }}
  env:
  - name: NAMESPACE
    value: {{ .Release.Namespace }}
  - name: KOMOKW_API_KEY
    valueFrom:
      secretKeyRef:
        {{- if .Values.apiKeySecret }}
        name: {{ .Values.apiKeySecret | required "Existing secret name required!" }}
        key: apiKey
        {{- else }}
        name: {{ include "komodorAgent.name" . }}-secret
        key: apiKey
        {{- end }}
{{- end }}
{{- end }}
