{{- define "metrics.daemonset.container" }}
{{- if .Values.capabilities.metrics }}
- name: metrics
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.metrics.image.name}}:{{ .Values.components.komodorDaemon.metrics.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorDaemon.metrics.resources | trim | nindent 4 }}
  volumeMounts:
  - name: {{ include "metrics.daemon.config.name" . }}
    mountPath: /etc/telegraf/telegraf.conf
    subPath: telegraf.conf
  - name: {{ include "metrics.daemon.config.name" . }}
    mountPath: /etc/telegraf/plugin.conf
    subPath: plugin.conf
  {{- include "custom-ca.trusted-volumeMounts" . | indent 2 }}
  envFrom:
  - configMapRef:
      name:  "k8s-watcher-daemon-env-vars"
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: OS_TYPE
    value: linux
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
  {{- if gt (len .Values.components.komodorDaemon.metrics.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemon.metrics.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "metrics.daemonsetWindows.container" }}
{{- if .Values.capabilities.metrics }}
- name: metrics
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemonWindows.metrics.image.name}}:{{ .Values.components.komodorDaemonWindows.metrics.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorDaemonWindows.metrics.resources | trim | nindent 4 }}
  volumeMounts:
  - name: {{ include "metrics.daemon-windows.config.name" . }}
    mountPath: C:/telegraf/telegraf.conf
    subPath: telegraf.conf
  - name: {{ include "metrics.daemon-windows.config.name" . }}
    mountPath: C:/telegraf/plugin.conf
    subPath: plugin.conf
  {{- include "custom-ca.trusted-volumeMounts" . | indent 2 }}
  envFrom:
  - configMapRef:
      name:  "k8s-watcher-daemon-env-vars"
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: OS_TYPE
    value: windows
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
  {{- if gt (len .Values.components.komodorDaemonWindows.metrics.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemonWindows.metrics.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "metrics.daemonset.init.container" }}
{{- if .Values.capabilities.metrics }}
- name: init-daemon
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.metricsInit.image.name}}:{{ .Values.components.komodorDaemon.metricsInit.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  command: ["daemon"]
  resources:
    {{ toYaml .Values.components.komodorDaemon.metricsInit.resources | trim | nindent 4 }}
  {{ include "custom-ca.trusted-init-container.command" . | indent 2 }}
  volumeMounts:
  - name: configuration
    mountPath: /etc/komodor
  {{- include "custom-ca.volumeMounts" . | nindent 2 }}
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: COMPONENT
    value: {{ include "komodorAgent.fullname" . }}-daemon
  - name: NAMESPACE
    value: {{ .Release.Namespace }}
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
  {{- if gt (len .Values.components.komodorDaemon.metricsInit.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemon.metricsInit.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}
