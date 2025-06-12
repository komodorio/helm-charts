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
Admission Controller container name
*/}}
{{- define "komodorAgent.admissionController.containername" -}}
{{- print "admission-controller" }}
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
Admission Controller PriorityClass Name
*/}}
{{- define "komodorAgent.admissionController.priorityClassName" -}}
{{- printf "%s-%s" (include "komodor.truncatedReleaseName" .) "admission-high-priority" -}}
{{- end }}


{{/*
Generate certificates for aggregated api server

We need to put all resources that need certificate or CA Bundle together,
so the template is executed just once. Otherwise the private/public/CA keys will NOT MATCH since every time we use 'include' it is executed in a new context.

Because a template can only represent a string, we append them using a delimiter: `$`.
In a SPECIFIC ORDER. TLS.CRT is first, then TLS.KEY, and finally CA.CRT.
*/}}

{{- define "komodorAgent.admissionController.generatedSelfSignedCerts" -}}
    {{- $tlsSecretName := printf "%s-tls" (include "komodorAgent.admissionController.serviceName" .) -}}
    {{- $caSecretName := printf "%s-ca" (include "komodorAgent.admissionController.serviceName" .) -}}
    {{- $tlsSecret := lookup "v1" "Secret" .Release.Namespace $tlsSecretName -}}
    {{- $caSecret := lookup "v1" "Secret" .Release.Namespace $caSecretName -}}

    {{- if and .Values.capabilities.admissionController.webhookServer.reuseGeneratedTlsSecret (and (not (empty $tlsSecret)) (not (empty $caSecret))) -}}
        {{- printf "%s$%s$%s" (index $tlsSecret.data "tls.crt") (index $tlsSecret.data "tls.key") (index $caSecret.data "tls.crt") -}}
    {{- else -}}
        {{- $ca := genCA (print "*." .Release.Namespace ".svc") 3650 -}}
        {{- $cn := print (include "komodorAgent.admissionController.serviceName" .) "." .Release.Namespace ".svc" -}}
        {{- $san := list $cn (print (include "komodorAgent.admissionController.serviceName" .) "." .Release.Namespace ".svc.cluster.local") -}}
        {{- $cert := genSignedCert $cn nil $san 3650 $ca -}}
        {{- printf "%s$%s$%s" ($cert.Cert | b64enc) ($cert.Key | b64enc) ($ca.Cert | b64enc) -}}
    {{- end -}}
{{- end -}}
