{{- define "metrics.daemonset.container" }}
{{- if .Values.capabilities.metrics }}
- name: metrics
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.metrics.image.name}}:{{ .Values.components.komodorDaemon.metrics.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorDaemon.metrics.resources | trim | nindent 4 }}
  volumeMounts:
  - name: {{ include "metrics.shared.volume.name" . }}
    mountPath: /etc/telegraf
  {{- include "custom-ca.trusted-volumeMounts" . | indent 2 }}
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: OS_TYPE
    value: linux
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
    mountPath: /etc/telegraf
  {{- include "custom-ca.trusted-volumeMounts" . | indent 2 }}
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: OS_TYPE
    value: windows
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
  {{- if gt (len .Values.components.komodorDaemonWindows.metrics.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemonWindows.metrics.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}
