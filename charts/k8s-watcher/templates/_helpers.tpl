{{/* vim: set filetype=mustache: */}}

# -----


{{/*
Expand the name of the chart.
*/}}
{{- define "k8s-watcher.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}



{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "k8s-watcher.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "k8s-watcher.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "k8s-watcher.labels" -}}
helm.sh/chart: {{ include "k8s-watcher.chart" . }}
{{ include "k8s-watcher.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "k8s-watcher.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8s-watcher.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common daemon labels
*/}}
{{- define "daemon.labels" -}}
helm.sh/chart: {{ include "k8s-watcher.chart" . }}
{{ include "daemon.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector daemon labels
*/}}
{{- define "daemon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8s-watcher.name" . }}-daemon
app.kubernetes.io/instance: {{ .Release.Name }}-daemon
{{- end }}

{{/*
Selector daemon server host
*/}}
{{- define "daemon.serverHost" -}}
{{- default "https://app.komodor.com" .Values.watcher.serverHost }}
{{- end }}

{{/*
Api server url
*/}}
{{- define "daemon.apiServerUrl" -}}
{{- default "https://kubernetes.default.svc.cluster.local" ((.Values).daemon).apiServerUrl }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "k8s-watcher.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "k8s-watcher.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "watcher.values" -}}
{{- $daemonEnabledValues := dict "daemon" (dict "enabled" ((.Values.metrics).enabled | default false)) }}
{{- mergeOverwrite .Values.watcher $daemonEnabledValues  | toYaml  }}
{{- end }}

{{- define "watcher.container" -}}
- name: "k8s-watcher"
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.watcher.image.name}}/{{ .Values.components.komodorAgent.watcher.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorAgent.watcher.resources | trim | nindent 2 }}
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
      {{- if .Values.existingSecret }}
      name: {{ .Values.existingSecret | required "Existing secret name required!" }}
      key: apiKey
      {{- else }}
      name: {{ include "k8s-watcher.name" . }}-secret
      key: apiKey
      {{- end }}
  {{- if not (empty .Values.watcher.tags) }}
  - name: KOMOKW_TAGS
    value: {{ .Values.tags | default "" | quote }}
  {{- end }}
  - name: HELM_CACHE_HOME
    value: /opt/watcher/helm/cache
  - name: HELM_CONFIG_HOME
    value: /opt/watcher/helm/config
  - name: HELM_DATA_HOME
    value: /opt/watcher/helm/data
  {{- include "k8s-watcher.proxy-conf" . | indent 12 }}
  securityContext:
    readOnlyRootFilesystem: true
    runAsUser: 1000
    runAsGroup: 1000
    allowPrivilegeEscalation: false
  ports:
    - name: http-healthz
      containerPort: {{ .Values.components.komodorAgent.watcher.ports.healthCheck }}
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
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.supervisor.image.name}}/{{ .Values.components.komodorAgent.supervisor.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorAgent.watcher.resources | trim | nindent 2 }}
  volumeMounts:
    - name: agent-configuration
      mountPath: /etc/komodor
  env:
    - name: KOMOKW_API_KEY
      valueFrom:
        secretKeyRef:
          {{- if .Values.existingSecret }}
          name: {{ .Values.existingSecret }}
          key: apiKey
          {{- else }}
          name: {{ include "k8s-watcher.name" . }}-secret
          key: apiKey
          {{- end }}
    - name: KOMOKW_SERVERS_HEALTHCHECK_PORT
      value: {{ .Values.components.komodorAgent.supervisor.ports.healthCheck }}
  {{- include "k8s-watcher.proxy-conf" . | indent 12 }}
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

{{- define "network_mapper.container" -}}
{{- if ne (default true (.Values.capabilities).networkMapper) false -}}
- name: network-mapper
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.networkMapper.image.name}}/{{ .Values.components.komodorAgent.networkMapper.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorAgent.networkMapper.resources | trim | nindent 4 }}
  env:
  - name: OTTERIZE_DEBUG
    value: {{ (.Values.network_mapper).debug | default "false" | quote }}
  {{ if (((.Values.network_mapper).global).otterizeCloud).apiAddress }}
  - name: OTTERIZE_API_ADDRESS
    value: "{{ .Values.network_mapper.global.otterizeCloud.apiAddress }}"
  {{ end }}
  {{ if ((((.Values.network_mapper).global).otterizeCloud).credentials).clientId }}
  - name: OTTERIZE_CLIENT_ID
    value: "{{ .Values.network_mapper.global.otterizeCloud.credentials.clientId }}"
  {{ end }}
  {{ if ((((.Values.network_mapper).global).otterizeCloud).credentials).clientSecret }}
  - name: OTTERIZE_CLIENT_SECRET
    value: "{{ .Values.network_mapper.global.otterizeCloud.credentials.clientSecret }}"
  {{ end }}
  - name: OTTERIZE_UPLOAD_INTERVAL_SECONDS
    value: {{ ((.Values.network_mapper).mapper).uploadIntervalSeconds | default "60" | quote }}
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - "ALL"
{{- end -}}
{{- end -}}

{{- define "network_mapper.daemonset.container" }}
{{- if ne (default true (.Values.capabilities).networkMapper) false -}}
- name: {{ template "network.sniffer.fullName" . }}
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.networkSniffer.image.name}}/{{ .Values.components.komodorDaemon.networkSniffer.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorDaemon.networkSniffer.resources | trim | nindent 2 }}
  env:
    - name: OTTERIZE_MAPPER_API_URL
      value: http://{{ template "network.mapper.fullName" . }}:9090/query
    - name: OTTERIZE_DEBUG
      value: {{ (.Values.network_mapper).debug | default "false" | quote }}
  volumeMounts:
    - mountPath: /hostproc
      name: proc
      readOnly: true
  securityContext:
    capabilities:
      add:
        - SYS_PTRACE
{{- end }}
{{- end }}

{{- define "metrics.container" -}}
{{- if ne (default true (.Values.capabilities).metrics) false -}}
- name: metrics
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.metrics.image.name}}/{{ .Values.components.komodorAgent.metrics.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorAgent.metrics.resources | trim | nindent 4 }}
  volumeMounts:
  - name: {{ include "k8s-watcher.name" . }}-metrics-config
    mountPath: /etc/telegraf/telegraf.conf
    subPath: telegraf.conf
  {{- include "custom-ca.trusted-volumeMounts" . | indent 2 }}
  envFrom:
  - configMapRef:
      name:  "k8s-watcher-daemon-env-vars"
  env:
  {{- include "k8s-watcher.proxy-conf" . | indent 12 }}
  - name: CLUSTER_NAME
    value: {{ .Values.clusterName }}
{{- end }}
{{- end }}

{{- define "metrics.daemonset.container" }}
{{- if ne (default true (.Values.capabilities).metrics) false}}
- name: metrics
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.metrics.image.name}}/{{ .Values.components.komodorAgent.metrics.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorAgent.metrics.resources | trim | nindent 4 }}
  volumeMounts:
  - name: {{ include "k8s-watcher.name" . }}-daemon-config
    mountPath: /etc/telegraf/telegraf.conf
    subPath: telegraf.conf
  envFrom:
  - configMapRef:
      name:  "k8s-watcher-daemon-env-vars"
  env:
  {{- include "k8s-watcher.proxy-conf" . | indent 12 }}
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
{{- if ne (default true (.Values.capabilities).metrics) false }}
- name: init-daemon
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.metricsInit.image.name}}/{{ .Values.components.komodorDaemon.metricsInit.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorDaemon.metricsInit.resources | trim | nindent 4 }}
  {{- if ne (default false (.Values.customCa).enabled) false }}
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
        {{- if .Values.existingSecret }}
        name: {{ .Values.existingSecret | required "Existing secret name required!" }}
        key: apiKey
        {{- else }}
        name: {{ include "k8s-watcher.name" . }}-secret
        key: apiKey
        {{- end }}
{{- end }}
{{- end }}


# -----Volumes helpers---
{{- define "metrics.daemonset.volumes" }}
{{- if ne (default true (.Values.capabilities).metrics) false}}
- name: {{ include "k8s-watcher.name" . }}-daemon-config
  configMap:
    name: {{ include "k8s-watcher.name" . }}-daemon-config
- name: configuration
  configMap:
    name: {{ include "k8s-watcher.name" . }}-config
    items:
      - key: komodor-k8s-watcher.yaml
        path: komodor-k8s-watcher.yaml
{{- end }}
{{- end }}

{{- define "metrics.deploy.volumes" }}
{{- if ne (default true (.Values.capabilities).metrics) false }}
- name: {{ include "k8s-watcher.name" . }}-metrics-config
  configMap:
    name: {{ include "k8s-watcher.name" . }}-metrics-config
{{- end }}
{{- end }}


{{- define "agent.deploy.volumes" }}
- name: agent-configuration
  configMap:
    name: {{ include "k8s-watcher.name" . }}-config
    items:
      - key: komodor-k8s-watcher.yaml
        path: komodor-k8s-watcher.yaml
- name: tmp
  emptyDir:
    sizeLimit: 100Mi
- name: podinfo
  downwardAPI:
    items:
      - path: "mem_limit"
        resourceFieldRef:
          containerName: {{ .Chart.Name }}
          resource: limits.memory
          divisor: 1Mi
- name: helm-data
  emptyDir:
    sizeLimit: 256Mi
- name: kube-cache
  emptyDir:
    sizeLimit: 1Gi
{{- end }}

{{- define "network_mapper.daemonset.volumes" }}
{{- if ne (default true (.Values.watcher.networkMapper).enable) false }}
- hostPath:
    path: /proc
    type: ""
  name: proc
{{- end }}
{{- end }}


# tolerrations
{{- define "daemon.tolerations" }}
{{- if not (empty .Values.components.komodorAgent.tolerations) }}
{{- toYaml .Values.components.komodorAgent.tolerations }}
{{- else }}
- operator: "Exists"
{{- end }}
{{- end }}


# network
{{- define "network_mapper.daemonset.network" }}
{{- if ne (.Values.watcher.networkMapper).enable false }}
hostNetwork: true
dnsPolicy: ClusterFirstWithHostNet
{{- end }}
{{- end }}
