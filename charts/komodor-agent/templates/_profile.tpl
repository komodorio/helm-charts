{{/*
applyProfile resolves `--set profile=<name>` into concrete chart values.

Three rules govern what a profile is allowed to do:

  1. It only ever sets values. It never deletes a key and never writes null.
     `installed-values.yaml` below is a verbatim dump of .Values that is sent to Komodor, and
     the backend type-asserts on `capabilities.*` — a null there reads as "capability on" for
     every mutating action type and silently disables right-sizing.

  2. It only turns capabilities off. Anything a profile depends on staying on is left at its
     chart default rather than pinned here, so an operator can still shrink the install
     further. `values_profile_test.py` asserts the kept keys are actually on.

  3. Values written here WIN over `--set`, because they are applied during rendering. That is
     the one behaviour that differs from passing an equivalent `-f values-cost.yaml`.

Helm gives no render-order guarantee, so every template that reads a key written below must
include this helper before its first read. `values_profile_test.py` enforces that statically.
*/}}
{{- define "applyProfile" -}}
{{/*
Validate here rather than in validations.yaml. Helm renders templates deepest-path-first, so
validations.yaml is not first and a bad value would surface as a raw template error from this
file before its check ever ran. Comparing as a string also keeps `--set profile=false` from
being read as a bool: it is a value like any other, not a way to turn the preset off, and
silently installing a full agent because someone typed it is the worst outcome here.
*/}}
{{- $profile := "" -}}
{{- if not (kindIs "invalid" .Values.profile) -}}
{{- $profile = .Values.profile | toString -}}
{{- end -}}
{{- if not (has $profile (list "" "cost")) -}}
{{- fail (printf "profile must be \"cost\", or unset for a default install; got %q. profile is a string, so --set profile=false sets a profile named \"false\" rather than disabling the preset." $profile) -}}
{{- end -}}
{{- if eq $profile "cost" -}}

{{/* capabilities.helm may still be a bare bool at this point; set needs a map */}}
{{- include "migrateHelmValues" . -}}

{{- $caps := .Values.capabilities -}}
{{/* cluster mutation: the cost flows read, they do not act */}}
{{- $_ := set $caps "actions" false -}}
{{- $_ := set $caps "crActions" false -}}
{{- $_ := set $caps "rbac" false -}}
{{- $_ := set $caps "rbacTempTokens" false -}}
{{- $_ := set $caps.helm "enabled" false -}}
{{- $_ := set $caps.events "create" false -}}
{{/* collection subsystems no cost flow consumes */}}
{{- $_ := set $caps "nodeEnricher" false -}}
{{- $_ := set $caps.logs "enabled" false -}}
{{- $_ := set $caps.resourceInfo "enabled" false -}}
{{/* the agent's own observability; drops the otel collector daemonset sidecar */}}
{{- $_ := set $caps.telemetry "enabled" false -}}
{{- $_ := set $caps.telemetry "deployOtelCollector" false -}}
{{/* remote access paths */}}
{{- $_ := set $caps.tunnel "enabled" false -}}
{{- $_ := set $caps.tunnel.kubeapiserver "enabled" false -}}
{{- $_ := set $caps.kubectlProxy "enabled" false -}}
{{- $_ := set $caps.klaudiaIntegrationSync "enabled" false -}}

{{- $_ := set .Values.components.komodorDaemonWindows "enabled" false -}}

{{- $allowed := .Values.allowedResources -}}
{{/*
Kept on, and deliberately not pinned here: node, metrics, namespace, pod, deployment,
statefulSet, daemonSet, job, cronjob — the kinds the cost flows read — and
customReadAPIGroups, which an operator sets per cluster alongside the profile.

replicaSet is off even though the other workload kinds stay on: it is not a source kind for
any reconciler, and telegraf carries its own apps/replicasets read, so dropping it degrades
only a backend fallback telegraf does not use.

customResourceDefinition has no entry in values.yaml but defaults true in the agent, and
allowedResources is dumped verbatim into the agent ConfigMap, so it has to be named
explicitly to take effect.

rollout, argoWorkflows.workflows and argoWorkflows.cronWorkflows stay on, and that is load
bearing rather than an oversight. Komodor asks every cluster for rollouts.argoproj.io,
workflows.argoproj.io and cronworkflows.argoproj.io whenever the matching CRD is installed.
Without the RBAC the agent answers forbidden instead of "not supported", and a forbidden is
not tolerated the same way - the cluster's resource sync stops and nothing is ever marked
deleted. Rollout is also a right-sizable workload kind. workflowTemplates and
clusterWorkflowTemplates are gated separately in the ClusterRole and nothing requests them,
so those two do come off.
*/}}
{{- $off := list "allowReadAll" -}}
{{- $off = concat $off (list "replicaSet" "horizontalPodAutoscaler" "podDisruptionBudget" "priorityClass") -}}
{{- $off = concat $off (list "persistentVolume" "persistentVolumeClaim" "storageClass" "volumeAttachment") -}}
{{- $off = concat $off (list "csiDriver" "csiNode" "csiStorageCapacity") -}}
{{- $off = concat $off (list "limitRange" "resourceQuota" "event" "replicationController" "podTemplate") -}}
{{- $off = concat $off (list "controllerRevision" "runtimeClass" "lease" "certificateSigningRequest") -}}
{{- $off = concat $off (list "service" "endpoints" "endpointSlice" "ingress" "ingressClass" "networkPolicy") -}}
{{- $off = concat $off (list "secret" "configMap") -}}
{{- $off = concat $off (list "clusterRole" "clusterRoleBinding" "role" "roleBinding" "serviceAccount") -}}
{{- $off = concat $off (list "customResourceDefinition" "admissionRegistrationResources") -}}
{{- $off = concat $off (list "authorizationResources" "flowControlResources" "policyResources") -}}
{{- range $key := $off -}}
{{- $_ := set $allowed $key false -}}
{{- end -}}

{{- if not (kindIs "map" $allowed.argoWorkflows) -}}
{{- $_ := set $allowed "argoWorkflows" dict -}}
{{- end -}}
{{- range $key := list "workflowTemplates" "clusterWorkflowTemplates" -}}
{{- $_ := set $allowed.argoWorkflows $key false -}}
{{- end -}}

{{- end -}}
{{- end -}}
