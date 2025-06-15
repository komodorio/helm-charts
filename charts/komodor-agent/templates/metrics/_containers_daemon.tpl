{{- define "metrics.daemonset.container" }}
{{- if .Values.capabilities.metrics }}
- name: metrics
  command: ["telegraf"]
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.metrics.image.name}}:{{ .Values.components.komodorDaemon.metrics.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorDaemon.metrics.resources | trim | nindent 4 }}
  volumeMounts:
  - name: {{ include "metrics.shared.volume.name" . }}
    mountPath: /etc/telegraf

  {{- include "custom-ca.trusted-volumeMounts" . | indent 2 }}
  env:
  {{- include "komodorMetrics.proxy-conf" . | indent 2 }}
  - name: OS_TYPE
    value: linux
  - name: KOMOKW_API_KEY
    {{ include "komodorAgent.apiKeySecretRef" . | nindent 4 }}
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: NODE_IP
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
  - name: QUIET
    value: {{ .Values.components.komodorDaemon.metrics.quiet | default false | quote }}
  - name: KOMODOR_SERVER_URL
    value: {{ .Values.communications.serverHost | quote }}
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
  - name: {{ include "metrics.shared.volume.name" . }}
    mountPath: C:/telegraf/telegraf.conf
    subPath: telegraf.conf
  - name: {{ include "metrics.shared.volume.name" . }}
    mountPath: C:/telegraf/plugin.conf
    subPath: plugin.conf
  {{- include "custom-ca.trusted-volumeMounts" . | indent 2 }}
  env:
  {{- include "komodorMetrics.proxy-conf" . | indent 2 }}
  - name: OS_TYPE
    value: windows
  - name: KOMOKW_API_KEY
    {{ include "komodorAgent.apiKeySecretRef" . | nindent 4 }}
  - name: QUIET
    value: {{ .Values.components.komodorDaemonWindows.metrics.quiet | default false | quote }}
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: NODE_IP
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
  - name: KOMODOR_SERVER_URL
    value: {{ .Values.communications.serverHost | quote }}
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
  resources:
    {{ toYaml .Values.components.komodorDaemon.metricsInit.resources | trim | nindent 4 }}
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
    value: {{ .Chart.Name  }}-daemon
  - name: NAMESPACE
    value: {{ .Release.Namespace }}
  - name: KOMOKW_API_KEY
    {{ include "komodorAgent.apiKeySecretRef" . | nindent 4 }}
  {{- if gt (len .Values.components.komodorDaemon.metricsInit.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemon.metricsInit.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "metrics.gpuAccess.container" }}
{{- if .Values.components.komodorDaemon.gpuAccessContainer.enabled }}
- name: gpu-access
  image: {{ .Values.components.komodorDaemon.gpuAccessContainer.image }}
  imagePullPolicy: {{ .Values.components.komodorDaemon.gpuAccessContainer.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorDaemon.gpuAccessContainer.resources | trim | nindent 4 }}
  command: ["sleep", "infinity"]
  securityContext:
    privileged: true
  volumeMounts:
    - name: host-root
      mountPath: /host
      readOnly: true
{{- end }}
{{- end }}


{{- define "metrics.daemonset.init.windows.container" }}
{{- if .Values.capabilities.metrics }}
- name: init-daemon
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemonWindows.metricsInit.image.name}}:{{ .Values.components.komodorDaemonWindows.metricsInit.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorDaemonWindows.metricsInit.resources | trim | nindent 4 }}
  command: ["telegraf_init"]
  volumeMounts:
  - name: configuration
    mountPath: /etc/komodor
  - name: {{ include "metrics.shared.volume.name" . }}
    mountPath: /etc/telegraf
  {{- include "custom-ca.volumeMounts" . | nindent 2 }}
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: KOMOKW_COMPONENT
    value: {{ .Chart.Name  }}-daemon-windows
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
  {{- if gt (len .Values.components.komodorDaemonWindows.metricsInit.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemonWindows.metricsInit.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}