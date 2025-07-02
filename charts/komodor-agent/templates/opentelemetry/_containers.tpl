{{- define "opentelemetry.daemonset.container" }}
{{- if and .Values.capabilities.telemetry.enabled .Values.capabilities.telemetry.deployOtelCollector }}
- name: otel-collector
  image: {{ .Values.components.komodorDaemon.opentelemetry.image.name }}:{{ .Values.components.komodorDaemon.opentelemetry.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  command: ["/otelcol-komodor", "--config", "/etc/otelcol/config.yaml"]
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
  volumeMounts:
  - name: opentelemetry-config
    mountPath: /etc/otelcol
  - name: opentelemetry-varlogpods
    mountPath: /var/log/pods
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
  {{- if gt (len .Values.components.komodorDaemon.opentelemetry.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorDaemon.opentelemetry.extraEnvVars | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }} 