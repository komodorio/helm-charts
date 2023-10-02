
{{- define "watcher.container" -}}
- name: "k8s-watcher"
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.watcher.image.name}}:{{ .Values.components.komodorAgent.watcher.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
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
  {{- if ((.Values.capabilities).events).helm }}
  - name: helm-data
    mountPath: /opt/watcher/helm
  {{- end }}
  {{- if ((.Values.capabilities).events).enableRWCache }}
  - name: kube-cache
    mountPath: /.kube
  {{- end }}
  {{- include "custom-ca.trusted-volumeMounts" .  |  nindent 12 }}
  env:
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
  - name: KOMOKW_CLUSTER_NAME
    value: {{ .Values.clusterName }}
  {{- if not (empty .Values.tags) }}
  - name: KOMOKW_TAGS
    value: {{ .Values.tags | default "" | quote }}
  {{- end }}
  - name: HELM_CACHE_HOME
    value: /opt/watcher/helm/cache
  - name: HELM_CONFIG_HOME
    value: /opt/watcher/helm/config
  - name: HELM_DATA_HOME
    value: /opt/watcher/helm/data
  {{- include "komodorAgent.proxy-conf" . | indent 12 }}
  securityContext:
    readOnlyRootFilesystem: true
    runAsUser: 1000
    runAsGroup: 1000
    allowPrivilegeEscalation: false
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
  resources: {{ toYaml .Values.components.komodorAgent.watcher.resources | trim | nindent 4 }}
  volumeMounts:
    - name: agent-configuration
      mountPath: /etc/komodor
  env:
    - name: KOMOKW_CLUSTER_NAME
      value: {{ .Values.clusterName }}
    - name: KOMOKW_API_KEY
      valueFrom:
        secretKeyRef:
          {{- if .Values.apiKeySecret }}
          name: {{ .Values.apiKeySecret }}
          key: apiKey
          {{- else }}
          name: {{ include "komodorAgent.secret.name" . }}
          key: apiKey
          {{- end }}
    - name: KOMOKW_SERVERS_HEALTHCHECK_PORT
      value: {{ .Values.components.komodorAgent.supervisor.ports.healthCheck | quote }}
  {{- include "komodorAgent.proxy-conf" . | indent 12 }}
  securityContext:
    readOnlyRootFilesystem: true
    runAsUser: 1000
    runAsGroup: 1000
    allowPrivilegeEscalation: false
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