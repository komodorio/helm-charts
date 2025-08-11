{{- include "migrateHelmValues" . -}}
{{- define "watcher.container" -}}
- name: {{ include "watcher.container.name" .}}
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.watcher.image.name}}:{{ .Values.components.komodorAgent.watcher.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  command: ["watcher"]
  resources:
    {{ toYaml .Values.components.komodorAgent.watcher.resources | trim | nindent 4 }}
  volumeMounts:
  - name: agent-configuration
    mountPath: /etc/komodor
  - name: tmp
    mountPath: /tmp
  {{- if ((.Values.capabilities).events).enableMemLimitChecks }}
  - name: podinfo
    mountPath: /etc/podinfo
  {{- end }}
  {{- if (.Values.capabilities).helm.enabled }}
  - name: helm-data
    mountPath: /opt/watcher/helm
  {{- end }}
  {{- if ((.Values.capabilities).events).enableRWCache }}
  - name: kube-cache
    mountPath: /.kube
  {{- end }}
  {{- include "custom-ca.trusted-volumeMounts" .  |  nindent 2 }}
  env:
  - name: KOMOKW_API_KEY
    {{ include "komodorAgent.apiKeySecretRef" . | nindent 4 }}
  - name: KOMOKW_CLUSTER_NAME
    value: {{ .Values.clusterName }}
  - name: HELM_CACHE_HOME
    value: /opt/watcher/helm/cache
  - name: HELM_CONFIG_HOME
    value: /opt/watcher/helm/config
  - name: HELM_DATA_HOME
    value: /opt/watcher/helm/data
  {{- if .Values.skipTlsVerify }}
  - name: SKIP_TLS_VERIFY
    value: "true"
  {{- end }}
  {{- if gt (len .Values.components.komodorAgent.watcher.extraEnvVars) 0 }}
  {{ toYaml .Values.components.komodorAgent.watcher.extraEnvVars | nindent 2 }}
  {{- end }}

  {{- include "komodorAgent.proxy-conf" . | indent 2 }}
  {{- include "komodorAgent.container.securityContext" . | nindent 2}}
  ports:
    - name: http-healthz
      containerPort: {{ .Values.components.komodorAgent.watcher.ports.healthCheck  }}
  livenessProbe:
    httpGet:
      path: /healthz
      port: http-healthz
    periodSeconds: 60
    initialDelaySeconds: 15
    failureThreshold: 10
    successThreshold: 1
  readinessProbe:
    httpGet:
      path: /healthz
      port: http-healthz
    initialDelaySeconds: 5
    periodSeconds: 5
    failureThreshold: 3
    successThreshold: 1
{{- end -}}

{{- define "supervisor.container" -}}
- name: "supervisor"
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.supervisor.image.name}}:{{ .Values.components.komodorAgent.supervisor.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorAgent.supervisor.resources | trim | nindent 4 }}
  command: ["supervisor"]
  volumeMounts:
    - name: agent-configuration
      mountPath: /etc/komodor
  env:
    - name: KOMOKW_CLUSTER_NAME
      value: {{ .Values.clusterName }}
    - name: KOMOKW_API_KEY
      {{ include "komodorAgent.apiKeySecretRef" . | nindent 6 }}
    - name: KOMOKW_SERVERS_HEALTHCHECK_PORT
      value: {{ .Values.components.komodorAgent.supervisor.ports.healthCheck | quote }}
    {{- if gt (len .Values.components.komodorAgent.supervisor.extraEnvVars) 0 }}
    {{ toYaml .Values.components.komodorAgent.supervisor.extraEnvVars | nindent 4 }}
    {{- end }}

  {{- include "komodorAgent.proxy-conf" . | indent 4 }}
  {{- include "komodorAgent.container.securityContext" . | nindent 2}}
  ports:
    - name: http-healthz
      containerPort: {{ .Values.components.komodorAgent.supervisor.ports.healthCheck }}
  livenessProbe:
    httpGet:
      path: /healthz
      port: http-healthz
    periodSeconds: 60
    initialDelaySeconds: 15
    failureThreshold: 10
    successThreshold: 1
  readinessProbe:
    httpGet:
      path: /healthz
      port: http-healthz
    initialDelaySeconds: 5
    periodSeconds: 5
    failureThreshold: 3
    successThreshold: 1
{{- end -}}

{{- define "ca-init.container" -}}
{{- if (.Values.customCa).enabled  }}
- name: init-cert
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.supervisor.image.name}}:{{ .Values.components.komodorAgent.supervisor.image.tag | default .Chart.AppVersion }}
  command:
    - sh
    - -c
    - cp /certs/* /etc/ssl/certs/ &&
      update-ca-certificates --fresh &&
      cp -r /etc/ssl/certs/* /trusted-ca/
  volumeMounts:
    {{- include "custom-ca.trusted-volumeMounts-init" .    | nindent 4 }}
    {{- include "custom-ca.volumeMounts" .                 | nindent 4 }}
  resources:
      {{ toYaml .Values.customCa.resources | trim | nindent 6 }}
{{- end }}
{{- end -}}
