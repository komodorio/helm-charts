
{{- define "network_mapper.container" -}}
{{- if (.Values.capabilities).networkMapper -}}
- name: network-mapper
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorAgent.networkMapper.image.name}}:{{ .Values.components.komodorAgent.networkMapper.image.tag }}
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
{{- if (.Values.capabilities).networkMapper -}}
- name: {{ template "network.sniffer.fullName" . }}
  image: {{ .Values.imageRepo }}/{{ .Values.components.komodorDaemon.networkSniffer.image.name}}:{{ .Values.components.komodorDaemon.networkSniffer.image.tag }}
  imagePullPolicy: {{ .Values.pullPolicy }}
  resources: {{ toYaml .Values.components.komodorDaemon.networkSniffer.resources | trim | nindent 4 }}
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