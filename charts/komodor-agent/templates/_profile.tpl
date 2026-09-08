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

{{- $allowed := .Values.allowedResources -}}
{{/*
Kept on, and deliberately not pinned here: metrics — and customReadAPIGroups, which an operator
sets per cluster alongside the profile.

node is off, and the thing that makes that safe is not obvious: three ClusterRoles bind the
agent's single ServiceAccount, and the two metrics ones grant core nodes/pods/namespaces
get+list with no allowedResources gating at all - only capabilities.metrics, which this profile
keeps on. So turning node off stops the watcher's node informer while leaving the SA able to
read nodes. That matters because the agent lists one node at startup to learn its own region
and node labels, and because the backend resolves the cloud provider - and therefore the
enterprise discount - from those labels. Losing them would zero a customer's discount silently.
values_profile_test.py pins that read as a floor rather than leaving it to this comment.

customResourceDefinition has no entry in values.yaml but defaults true in the agent, and
allowedResources is dumped verbatim into the agent ConfigMap, so it has to be named
explicitly to take effect.

deployment, statefulSet, daemonSet and rollout are off even though the cost flows report on
them. Their pods carry the workload identity in the agent's own komodor_top_owner_ref tag,
and every one of those kinds is on the backend's owner_ref_verified allowlist, so that tag is
trusted and the service is never looked up. Cost and right-sizing keep working with no
informer at all.

job and cronjob are off too, and unlike the four above that is a real trade rather than a free
one. CronJob is NOT on the owner_ref_verified allowlist, so its pods only get a service
identity from a resources-api lookup, and that lookup is fed by these informers. Without them
their komodor_service_kind stays null, which drops them out of the service-level cost
breakdown and out of right-sizing. Their node capacity cost is still counted at the cluster
level; their allocated cost is not. Accepted deliberately: the backend has no komodor_service
data for a cost cluster to look up anyway, and for any account without the per-account
enrichment flag - off by default - this is already the behaviour today.

replicaSet is off for a different reason: it is not a source kind for any reconciler. The
ConfigMap is the whole effect there - the watcher ClusterRole keeps replicasets ungated so its
apps rule can never render an empty resources list.

argoWorkflows.workflows and argoWorkflows.cronWorkflows come off too. An earlier revision kept
them because Komodor asked every cluster for workflows.argoproj.io whenever the CRD was
installed, and a forbidden answer aborted the whole komodor_service batch so nothing was ever
marked deleted. That no longer happens: resources-api skips every reconciler for a cost-profile
cluster (komodorio/mono#30520). That makes this a deploy-order dependency the chart cannot
check for itself - the cost profile must not reach a backend predating that change.
workflowTemplates and clusterWorkflowTemplates were already off.
*/}}
{{- $off := list "allowReadAll" -}}
{{- $off = concat $off (list "deployment" "statefulSet" "daemonSet" "rollout" "job" "cronjob") -}}
{{- $off = concat $off (list "node") -}}
{{- $off = concat $off (list "pod" "namespace") -}}
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
{{- range $key := list "workflows" "cronWorkflows" "workflowTemplates" "clusterWorkflowTemplates" -}}
{{- $_ := set $allowed.argoWorkflows $key false -}}
{{- end -}}

{{- end -}}
{{- end -}}
