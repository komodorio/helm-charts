{{- define "opentelemetry.daemonset.container" }}
{{- if and .Values.capabilities.telemetry.enabled .Values.capabilities.telemetry.deployOtelCollector }}
- name: otel-collector
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.opentelemetry.image.name }}:{{ .Values.components.komodorDaemon.opentelemetry.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  {{- if .Values.components.komodorDaemon.opentelemetry.otelInit.enabled }}
  args: ["--config", "/etc/otel/{{ .Values.components.komodorDaemon.opentelemetry.otelInit.configFileName }}"]
  {{- end }}
  resources:
    {{ toYaml .Values.components.komodorDaemon.opentelemetry.resources | trim | nindent 4 }}
  ports:
  - name: otlp-http
    containerPort: 4318
    protocol: TCP
  - name: otlp-grpc
    containerPort: 4317
    protocol: TCP
  - name: health-check
    containerPort: 13133
    protocol: TCP
  - name: otel-prom
    containerPort: 8888
    protocol: TCP
  - name: local-prom
    containerPort: 9090
    protocol: TCP
  volumeMounts:
  {{- if .Values.components.komodorDaemon.opentelemetry.otelInit.enabled }}
  - name: {{ include "opentelemetry.shared.volume.name" . }}
    mountPath: /etc/otel
  {{- else }}
  - name: opentelemetry-config
    mountPath: /etc/otel
  {{- end }}
  - name: opentelemetry-varlogpods
    mountPath: {{ .Values.components.komodorDaemon.opentelemetry.volumes.varlogpods.mountPath }}
    readOnly: true
  - name: opentelemetry-varlib-docker-containers
    mountPath: {{ .Values.components.komodorDaemon.opentelemetry.volumes.varlibdockercontainers.mountPath }}
    readOnly: true
  livenessProbe:
    httpGet:
      path: /status/health
      port: 13133
    periodSeconds: 30
    initialDelaySeconds: 15
    failureThreshold: 3
    successThreshold: 1
  readinessProbe:
    httpGet:
      path: /status/health
      port: 13133
    initialDelaySeconds: 5
    periodSeconds: 5
    failureThreshold: 3
    successThreshold: 1
  env:
  {{- include "opentelemetry.proxy-conf" . | indent 2 }}
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: KOMO_API_KEY
    {{ include "komodorAgent.apiKeySecretRef" . | nindent 4 }}
  - name: KOMO_CLUSTER_NAME
    value: {{ .Values.clusterName }}
  - name: GOMEMLIMIT
    value: {{ .Values.components.komodorDaemon.opentelemetry.resources.limits.memory | replace "Ki" "KiB" | replace "Mi" "MiB" | replace "Gi" "GiB" | replace "Ti" "TiB" | quote }}
  - name: KOMODOR_SERVER_URL
    value: {{ include "communication.telemetryServerHost" . }}
  {{- include "komodorAgent.opentelemetry.healthEndpointsEnvironment" . | nindent 2 }}
  {{- if gt (len .Values.components.komodorDaemon.opentelemetry.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemon.opentelemetry.extraEnvVars | nindent 2 }}
  {{- end }}
  {{ include "opentelemetry.daemonset.container.securityContext" . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "opentelemetry.daemonset.sidecar.container" }}
{{- if and .Values.capabilities.telemetry.enabled .Values.capabilities.telemetry.deployOtelCollector .Values.components.komodorDaemon.opentelemetry.otelInit.enabled .Values.components.komodorDaemon.opentelemetry.otelInit.sidecar.enabled }}
- name: otel-init-sidecar
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.opentelemetry.otelInit.image.name }}:{{ .Values.components.komodorDaemon.opentelemetry.otelInit.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorDaemon.opentelemetry.otelInit.resources | trim | nindent 4 }}
  {{ include "opentelemetry.daemonset.container.securityContext" . | nindent 2 }}
  {{- if .Values.customCa.enabled }}
  {{ include "custom-ca.trusted-otel-init-container.command" . | indent 2 }}
  {{- else }}
  command: ["otel_init"]
  {{- end }}
  volumeMounts:
  - name: configuration
    mountPath: /etc/komodor
  - name: {{ include "opentelemetry.shared.volume.name" . }}
    mountPath: /etc/otel
  {{- include "custom-ca.volumeMounts" . | nindent 2 }}
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: KOMOKW_RUNTIME_MODE
    value: sidecar
  - name: KOMOKW_COMPONENT
    value: {{ .Chart.Name }}-opentelemetry
  - name: NAMESPACE
    value: {{ .Release.Namespace }}
  - name: KOMOKW_API_KEY
    {{ include "komodorAgent.apiKeySecretRef" . | nindent 4 }}
  - name: KOMOKW_POLLING_INTERVAL_SECONDS
    value: {{ .Values.components.komodorDaemon.opentelemetry.otelInit.sidecar.pollingIntervalSeconds | quote }}
  - name: OTEL_CONFIG_FILE_NAME
    value: {{ .Values.components.komodorDaemon.opentelemetry.otelInit.configFileName | quote }}
  {{- if gt (len .Values.components.komodorDaemon.opentelemetry.otelInit.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemon.opentelemetry.otelInit.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "opentelemetry.daemonset.init.container" }}
{{- if and .Values.capabilities.telemetry.enabled .Values.capabilities.telemetry.deployOtelCollector .Values.components.komodorDaemon.opentelemetry.otelInit.enabled }}
- name: otel-init
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.opentelemetry.otelInit.image.name }}:{{ .Values.components.komodorDaemon.opentelemetry.otelInit.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources:
    {{ toYaml .Values.components.komodorDaemon.opentelemetry.otelInit.resources | trim | nindent 4 }}
  {{- if .Values.customCa.enabled }}
  {{ include "custom-ca.trusted-otel-init-container.command" . | indent 2 }}
  {{- else }}
  command: ["otel_init"]
  {{- end }}
  volumeMounts:
  - name: configuration
    mountPath: /etc/komodor
  - name: {{ include "opentelemetry.shared.volume.name" . }}
    mountPath: /etc/otel
  {{- include "custom-ca.volumeMounts" . | nindent 2 }}
  env:
  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  - name: KOMOKW_RUNTIME_MODE
    value: init
  - name: KOMOKW_COMPONENT
    value: {{ .Chart.Name }}-opentelemetry
  - name: NAMESPACE
    value: {{ .Release.Namespace }}
  - name: KOMOKW_API_KEY
    {{ include "komodorAgent.apiKeySecretRef" . | nindent 4 }}
  - name: OTEL_CONFIG_FILE_NAME
    value: {{ .Values.components.komodorDaemon.opentelemetry.otelInit.configFileName | quote }}
  {{- if gt (len .Values.components.komodorDaemon.opentelemetry.otelInit.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemon.opentelemetry.otelInit.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}
