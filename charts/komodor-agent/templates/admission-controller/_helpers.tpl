{{/*
Admission Controller name
*/}}
{{- define "komodorAgent.admissionController.name" -}}
{{- printf "%s-admission-controller" (include "komodorAgent.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Admission Controller fullname
*/}}
{{- define "komodorAgent.admissionController.fullname" -}}
{{- printf "%s-admission-controller" (include "komodorAgent.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Admission Controller common labels
*/}}
{{- define "komodorAgent.admissionController.labels" -}}
{{ include "komodorAgent.admissionController.selectorLabels" . }}
helm.sh/chart: {{ include "komodorAgent.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Values.components.admissionController.image.tag }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Admission Controller selector labels
*/}}
{{- define "komodorAgent.admissionController.selectorLabels" -}}
app.kubernetes.io/name: {{ include "komodorAgent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: admission-controller
{{- end }}

{{/*
Admission Controller service name
*/}}
{{- define "komodorAgent.admissionController.serviceName" -}}
{{- if .Values.capabilities.admissionController.webhookServer.serviceName }}
{{- .Values.capabilities.admissionController.webhookServer.serviceName }}
{{- else }}
{{- include "komodorAgent.admissionController.fullname" . }}
{{- end }}
{{- end }}

{{/*
Admission Controller service port
*/}}
{{- define "komodorAgent.admissionController.servicePort" -}}
{{- .Values.capabilities.admissionController.webhookServer.port | default 8443 }}
{{- end }}

{{/*
Admission Controller webhook configuration name
*/}}
{{- define "komodorAgent.admissionController.webhookName" -}}
{{- printf "binpacking-pod-discovery" }}
{{- end }}

{{/*
Admission Controller certificates
*/}}
{{- define "komodorAgent.admissionController.certificates" -}}
{{- $ca := genCA "komodor-admission-controller-ca" 3650 -}}
{{- $altNames := list (printf "%s.%s.svc" (include "komodorAgent.admissionController.serviceName" .) .Release.Namespace) (printf "%s.%s.svc.cluster.local" (include "komodorAgent.admissionController.serviceName" .) .Release.Namespace) -}}
{{- $cert := genSignedCert (include "komodorAgent.admissionController.serviceName" .) nil $altNames 3650 $ca -}}
ca: {{ $ca.Cert | b64enc }}
cert: {{ $cert.Cert | b64enc }}
key: {{ $cert.Key | b64enc }}
{{- end -}}

{{/*
Admission Controller CA certificate
*/}}
{{- define "komodorAgent.admissionController.ca" -}}
{{- $certificates := include "komodorAgent.admissionController.certificates" . | fromYaml -}}
{{- $certificates.ca -}}
{{- end -}}

{{/*
Admission Controller certificate
*/}}
{{- define "komodorAgent.admissionController.cert" -}}
{{- $certificates := include "komodorAgent.admissionController.certificates" . | fromYaml -}}
{{- $certificates.cert -}}
{{- end -}}

{{/*
Admission Controller certificate key
*/}}
{{- define "komodorAgent.admissionController.key" -}}
{{- $certificates := include "komodorAgent.admissionController.certificates" . | fromYaml -}}
{{- $certificates.key -}}
{{- end -}}

{{/*
Admission Controller CA bundle for webhook configuration
*/}}
{{- define "komodorAgent.admissionController.caBundle" -}}
{{- $certificates := include "komodorAgent.admissionController.certificates" . | fromYaml -}}
{{- $certificates.ca -}}
{{- end -}}
