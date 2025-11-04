# komodor-agent

Watches and sends kubernetes resource-related events

![AppVersion: 0.2.171](https://img.shields.io/badge/AppVersion-0.2.171-informational?style=flat-square)

## TL;DR;

```bash
helm repo add komodorio https://helm-charts.komodor.io
helm repo update
helm upgrade --install komodor-agent komodorio/komodor-agent \
  --set apiKey=<YOUR_API_KEY_HERE> \
  --set clusterName=<CLUSTER_NAME> \
  --wait \
  --timeout=90s
```

In case of error try contact us for assistance via the Komodor Help Center at: https://help.komodor.com
Or run:

1. Logs of komodor-agent

```bash
kubectl logs --tail=10 deployment/komodor-agent
```

2. Helm status

```bash
helm status komodor-agent
```

3. Reinstall

```bash
helm uninstall komodor-agent
```

## Introduction

This chart bootstraps a Kubernetes Resources/Event Watcher deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

### Supported architectures

- :white_check_mark: linux/amd64
- :white_check_mark: linux/arm64

## Prerequisites

- Kubernetes 1.19+ (older versions not officially supported)
- Helm 2/3

## Memory Planning (Recommended)

Before installing the Komodor agent, we recommend running our memory checker utility to analyze your cluster's resource requirements and determine appropriate memory limits. This helps prevent out-of-memory issues and ensures optimal performance.

### Quick Memory Analysis

```bash
# Clone or download and apply the memory planning utility resources - They will be installed in the 'komodor-precheck' namespace
kubectl apply -f https://raw.githubusercontent.com/komodorio/helm-charts/master/charts/komodor-agent/utilities/memory-planning/01-namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/komodorio/helm-charts/master/charts/komodor-agent/utilities/memory-planning/02-configmap.yaml
kubectl apply -f https://raw.githubusercontent.com/komodorio/helm-charts/master/charts/komodor-agent/utilities/memory-planning/03-serviceaccount.yaml
kubectl apply -f https://raw.githubusercontent.com/komodorio/helm-charts/master/charts/komodor-agent/utilities/memory-planning/04-clusterrole.yaml
kubectl apply -f https://raw.githubusercontent.com/komodorio/helm-charts/master/charts/komodor-agent/utilities/memory-planning/05-clusterrolebinding.yaml
kubectl apply -f https://raw.githubusercontent.com/komodorio/helm-charts/master/charts/komodor-agent/utilities/memory-planning/06-job.yaml

# Monitor the analysis
kubectl logs -f job/komodor-memory-checker -n komodor-precheck

# View results and recommendations
kubectl logs job/komodor-memory-checker -n komodor-precheck | grep -A 10 "MEMORY RECOMMENDATIONS"

# Clean up after analysis
kubectl delete namespace komodor-precheck
```

### Using the Results

Apply the memory recommendations to your Helm installation:

```bash
helm upgrade --install komodor-agent komodorio/komodor-agent \
  --set apiKey=<YOUR_API_KEY_HERE> \
  --set clusterName=<CLUSTER_NAME> \
  --set components.komodorAgent.watcher.resources.requests.memory=<RECOMMENDED_REQUEST> \
  --set components.komodorAgent.watcher.resources.limits.memory=<RECOMMENDED_LIMIT>
```

For detailed instructions and configuration options, see the [Memory Planning Utility Documentation](utilities/memory-planning/README.md).

## Installing the Chart

To install the chart with the release name `komodor-agent`:

```bash
helm upgrade --install komodor-agent komodorio/komodor-agent \
  --set apiKey=<YOUR_API_KEY_HERE> \
  --set clusterName=<CLUSTER_NAME>
```

The command deploys the komodor-agent on the Kubernetes cluster with default configuration. The [configuration](#Values) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Api Key

The Komodor kubernetes api key can be provided in the helm upgrade command, in the `values.yaml` file or can be taken from an existing kubernetes secret resource.
When using an existing kubernetes secret resource, specify the secret name in `apiKeySecret` and store the api key under the name 'apiKey'.

## Uninstalling the Chart

To uninstall/delete the `komodor-agent` deployment:

Helm 3:

```bash
helm uninstall komodor-agent
```

Helm 2:

```bash
helm delete --purge komodor-agent
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| apiKey | guid | `nil` | **(*required*)** To be obtained from komodor app during onboarding |
| apiKeySecret | string | `nil` | Secret name containing Komodor agent api key |
| createNamespace | bool | `true` | Creates the namespace |
| tags | dict | `{}` | Tags the agent in order to identify it based on `key:value` properties separated by semicolon (`;`) example: `--set tags.env=staging,tags.team=payments` --- Can also be set in the values under `tags` as a dictionary of key:value strings |
| clusterName | string | `nil` | **(*required*)** Name to be displayed in the Komodor web application |
| createRbac | bool | `true` | Creates the necessary RBAC resources for the agent - use with caution! |
| telegrafImageVersion | string | `"v2.0.12-alpine"` | Telegraf version to be used |
| telegrafWindowsImageVersion | string | `"v2.0.12"` | Telegraf version to be used for windows |
| serviceAccount | object | See sub-values | Configure service account for the agent |
| serviceAccount.create | bool | `true` | Creates a service account for the agent |
| serviceAccount.name | string | `nil` | Name of the service account, Required if `serviceAccount.create` is false |
| serviceAccount.annotations | object | `{}` | Add annotations to the service account |
| proxy.enabled | bool | `false` | Enable proxy for the agent |
| proxy.komodorOnly | bool | `true` | Configure proxy to be applied only on communication to Komodor servers (comms. to K8S API remains without proxy) |
| proxy.http | string | `nil` | Configure Proxy setting (HTTP_PROXY) `eg. http://proxy.com:8080` |
| proxy.https | string | `nil` | Configure Proxy setting (HTTPS_PROXY) `eg. https://proxy.com:8080` |
| proxy.no_proxy | string | `nil` | Specify specific domains to ignore proxy for. eg. `komodor.com,google.com` |
| customCa | object | See sub-values | Configure custom CA for the agent (Not supported for windows) |
| customCa.enabled | bool | `false` | Enable custom CA certificate for the agent |
| customCa.secretName | string | `nil` | Name of the secret containing the CA |
| customCa.resources | dict | `{"limits":{"cpu":"10m","memory":"100Mi"},"requests":{"cpu":"1m","memory":"10Mi"}}` | Set custom resources to the custom CA container |
| imageRepo | string | `"public.ecr.aws/komodor-public"` | Override the komodor agent image repository. |
| pullPolicy | string | `"IfNotPresent"` | Default Image pull policy for the komodor agent image acceptable values <ifNotPresent\Always\Never>. |
| imagePullSecret | string | `nil` | Set the image pull secret for the komodor agent |
| capabilities | object | See sub-values | Configure the agent capabilities |
| capabilities.komodorCRD | bool | `true` | Native komodor custom resources |
| capabilities.metrics | bool | `true` | Fetch workload metrics and send them to komodor backend |
| capabilities.nodeEnricher | bool | `true` | Enable node enricher capabilities by the komodor agent |
| capabilities.actions | bool | `true` | Allow users to perform actions on the cluster, granular access control is defined in the application<boolean> |
| capabilities.helm | object | `{"enabled":true,"readonly":false}` | Enable helm capabilities by the komodor agent |
| capabilities.helm.enabled | bool | `true` | Enable helm capabilities by the komodor agent |
| capabilities.helm.readonly | bool | `false` | Allow komodor to read helm resources only (remove create/update/delete permissions from secrets) |
| capabilities.rbac | bool | `true` | Allow komodor to create and manage serviceaccounts, roles and bindings in cluster |
| capabilities.rbacClusterSyncParams | object | See sub-values | Configure the agent cluster sync capabilities |
| capabilities.rbacClusterSyncParams.enabled | bool | `false` | Enable cluster sync configuration from helm chart |
| capabilities.rbacClusterSyncParams.clusterURL | string | `nil` | URL of the cluster to sync with |
| capabilities.rbacClusterSyncParams.ingressCertConfiguration | dict | See sub-values | Configuration for the ingress certificate |
| capabilities.rbacClusterSyncParams.ingressCertConfiguration.namespace | string | `nil` | Namespace of the resource containing the certificate |
| capabilities.rbacClusterSyncParams.ingressCertConfiguration.kind | string | `nil` | Kind of the resource containing the certificate (Secret/ConfigMap) |
| capabilities.rbacClusterSyncParams.ingressCertConfiguration.name | string | `nil` | Name of the resource containing the certificate |
| capabilities.rbacClusterSyncParams.ingressCertConfiguration.dataPath | string | `nil` | Path to the certificate data in the resource (crt.ca) |
| capabilities.events | object | See sub-values | Configure the agent events capabilities |
| capabilities.events.watchNamespace | string | all | Watch a specific namespace, or all namespaces ("", "all") |
| capabilities.events.namespacesDenylist | array of strings | `[]` | Do not watch events from these namespaces. eg. `["kube-system", "kube-public"]` |
| capabilities.events.redact | list | `[]` | Redact workload names from the komodor events. eg. `["password", "token"]` |
| capabilities.events.enableRWCache | bool | `true` | Mounts a ReadWrite cache volume for the kubernetes api cache |
| capabilities.events.create | bool | `true` | allow create kubernetes events for enrichment |
| capabilities.logs | object | See sub-values | Configure the agent logs capabilities |
| capabilities.logs.enabled | bool | `true` | Fetch pod logs from komodor backend |
| capabilities.logs.logsNamespacesDenylist | list | `[]` | Do not fetch logs from these namespaces. eg. `["kube-system", "kube-public"]` |
| capabilities.logs.logsNamespacesAllowlist | list | `[]` | Only fetch logs from these namespaces. eg. `["kube-system", "kube-public"]` |
| capabilities.logs.nameDenylist | list | `[]` | Do not fetch logs from these workloads. eg. `["supersecret-workload", "password-manager"]` |
| capabilities.logs.redact | list | `[]` | Redact logs from the komodor logs. eg. `["password", "token"]` |
| capabilities.redaction | object | See sub-values | Configure the agent data redaction capabilities |
| capabilities.redaction.secret | object | `{"enable":true,"keepOnlyHelmReleases":false}` | Configuration for the "Secret" resource type |
| capabilities.redaction.secret.enable | bool | `true` | Enable redaction for the "Secret" resource type |
| capabilities.redaction.secret.keepOnlyHelmReleases | bool | `false` | Determine if only helm releases should be collected, if true - wipe and redact all other secrets data |
| capabilities.telemetry | object | See sub-values | Configure the agent telemetry capabilities |
| capabilities.telemetry.enabled | bool | `true` | Enable telemetry capabilities by the komodor agent |
| capabilities.telemetry.collectApiServerMetrics | bool | `false` | Collect metrics from the api server (Should only be used for debugging purposes) |
| capabilities.telemetry.deployOtelCollector | bool | `true` | Deploys OpenTelemetry collector daemonset sidecar |
| capabilities.kubectlProxy | object | See sub-values | Configure the komodor kubectl proxy capabilities |
| capabilities.kubectlProxy.enabled | bool | `false` | Enable the komodor kubectl proxy |
| capabilities.tasks | object | See sub-values | Configure the agent task capabilities |
| capabilities.tasks.httpRequests | object | See sub-values | Configure HTTP request capabilities |
| capabilities.tasks.httpRequests.skipTlsVerify | bool | `false` | Skip TLS certificate verification for HTTP requests (sets HTTP_REQUESTS_SKIP_TLS_VERIFY environment variable) |
| capabilities.admissionController | object | See sub-values | Configure the komodor admission controller capabilities |
| capabilities.admissionController.enabled | bool | `false` | Enable the komodor admission controller |
| capabilities.admissionController.logLevel | string | `"info"` | Log level for the admission controller |
| capabilities.admissionController.logFormat | string | `"json"` | Log format for the admission controller |
| capabilities.admissionController.webhookServer | object | See sub-values | Configure the webhook server for the admission controller |
| capabilities.admissionController.webhookServer.serviceName | string | `"komodor-admission-controller"` | Name of the service for the webhook server |
| capabilities.admissionController.webhookServer.port | int | `8443` | Port of the webhook server |
| capabilities.admissionController.webhookServer.tlsCertFile | string | /etc/komodor/admission/tls/tls.crt | Path to the TLS certificate file for the webhook server. If set, overrides the default certificate generation |
| capabilities.admissionController.webhookServer.tlsKeyFile | string | /etc/komodor/admission/tls/tls.key | Path to the TLS key file for the webhook server. If set, overrides the default certificate generation |
| capabilities.admissionController.webhookServer.reuseGeneratedTlsSecret | bool | true | If true, the webhook server will reuse the generated TLS secret. If false, the webhook server will recreate a new TLS secret on every upgrade. |
| capabilities.admissionController.mutatingWebhook | object | See sub-values | Configure the mutating webhook |
| capabilities.admissionController.mutatingWebhook.selfManage | bool | `false` | If true, the mutating webhook will be managed by the chart. If false, the mutating webhook will be managed by the user. |
| capabilities.admissionController.mutatingWebhook.timeoutSeconds | int | `5` | Timeout for the webhook call in seconds |
| capabilities.admissionController.mutatingWebhook.podBinpackingWebhookPath | string | `"/webhook/binpacking/pod"` | Path for the pod binpacking webhook |
| capabilities.admissionController.mutatingWebhook.podRightsizingWebhookPath | string | `"/webhook/rightsizing/pod"` | Path for the pod rightsizing webhook |
| capabilities.admissionController.mutatingWebhook.caBundle | string | using the kube-root-ca.crt ConfigMap in the kube-system namespace | CA bundle for the mutating webhook configuration. It should match the webhook server CA. |
| capabilities.admissionController.binpacking | object | See sub-values | Configure the binpacking capabilities for the admission controller |
| capabilities.admissionController.binpacking.markUnevictable | bool | `true` | Add a label to mark pods as unevictable (requires enabling per cluster in UI in addition) |
| capabilities.admissionController.binpacking.addNodeAffinityToMarkedPods | bool | `true` | Add node affinity to marked pods to prefer scheduling on nodes with already unevictable pods (requires enabling per cluster in UI in addition) |
| capabilities.admissionController.rightsizing | object | See sub-values | Configure the rightsizing capabilities for the admission controller |
| capabilities.admissionController.rightsizing.enabled | bool | `false` | Enable rightsizing capabilities by the komodor admission controller |
| components | object | See sub-values | Configure the agent components |
| components.komodorAgent | object | See sub-values | Configure the komodor agent components |
| components.komodorAgent.PriorityClassValue | int | `10000000` | Set the priority class value for the komodor agent deployment |
| components.komodorAgent.priorityClassName | string | `""` | Use an existing priority class for the komodor agent deployment. If not set, will create and use a priority class with PriorityClassValue. WARNING: priorityClassName is immutable and cannot be changed after initial deployment |
| components.komodorAgent.affinity | object | `{}` | Set node affinity for the komodor agent deployment |
| components.komodorAgent.annotations | object | `{}` | Set annotations for the komodor agent deployment |
| components.komodorAgent.labels | object | `{}` | Set custom labels |
| components.komodorAgent.nodeSelector | object | `{}` | Set node selectors for the komodor agent deployment |
| components.komodorAgent.tolerations | list | `[]` | Set tolerations for the komodor agent deployment |
| components.komodorAgent.podAnnotations | object | `{}` | Set pod annotations for the komodor agent deployment |
| components.komodorAgent.securityContext | object | `{}` | Set custom securityContext to the komodor agent deployment (use with caution) |
| components.komodorAgent.strategy | object | `{}` | Set the rolling update strategy for the komodor agent deployment |
| components.komodorAgent.watcher.image | object | `{ "name": "komodor-agent", "tag": .Chart.AppVersion }` | Override the komodor agent watcher image name or tag. |
| components.komodorAgent.watcher.resources | object | `{"limits":{"cpu":2,"memory":"8Gi"},"requests":{"cpu":0.25,"memory":"256Mi"}}` | Set custom resources to the komodor agent watcher container |
| components.komodorAgent.watcher.securityContext | object | `{}` | Set security context for the komodor agent watcher container (use with caution) |
| components.komodorAgent.watcher.ports | object | `{"healthCheck":8090}` | Override the komodor agent watcher ports configuration |
| components.komodorAgent.watcher.ports.healthCheck | int | `8090` | Override the health check port of the komodor agent watcher |
| components.komodorAgent.watcher.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorAgent.supervisor.image | object | `{ "name": "supervisor", "tag": .Chart.AppVersion }` | Override the komodor agent supervisor image name or tag. |
| components.komodorAgent.supervisor.resources | object | `{"requests":{"cpu":0.1,"memory":"256Mi"}}` | Set custom resources to the komodor agent supervisor container |
| components.komodorAgent.supervisor.securityContext | object | `{}` | Set security context for the komodor agent supervisor container (use with caution) |
| components.komodorAgent.supervisor.ports | object | `{"healthCheck":8089}` | Override the komodor agent supervisor ports configuration |
| components.komodorAgent.supervisor.ports.healthCheck | int | `8089` | Override the health check port of the komodor agent supervisor |
| components.komodorAgent.supervisor.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorKubectlProxy | object | See sub-values | Configure the komodor kubectl proxy components |
| components.komodorKubectlProxy.image | object | see sub-values | Override the komodor kubectl proxy image name or tag. |
| components.komodorKubectlProxy.resources | object | `{}` | Set custom resources to the komodor kubectl proxy container |
| components.komodorKubectlProxy.PriorityClassValue | int | `10000000` | Set the priority class value for the komodor kubectl proxy deployment |
| components.komodorKubectlProxy.priorityClassName | string | `""` | Use an existing priority class for the komodor kubectl proxy deployment. If not set, will create and use a priority class with PriorityClassValue. WARNING: priorityClassName is immutable and cannot be changed after initial deployment |
| components.komodorKubectlProxy.affinity | object | `{}` | Set node affinity for the komodor kubectl proxy deployment |
| components.komodorKubectlProxy.annotations | object | `{}` | Set annotations for the komodor kubectl proxy deployment |
| components.komodorKubectlProxy.podAnnotations | object | `{}` | Set pod annotations for the komodor kubectl proxy deployment |
| components.komodorKubectlProxy.labels | object | `{}` | Set custom labels |
| components.komodorKubectlProxy.nodeSelector | object | `{}` | Set node selectors for the komodor kubectl proxy deployment |
| components.komodorKubectlProxy.tolerations | list | `[]` | Set tolerations for the komodor kubectl proxy deployment |
| components.komodorKubectlProxy.securityContext | object | `{}` | Set custom securityContext to the komodor kubectl proxy deployment (use with caution) |
| components.komodorKubectlProxy.strategy | object | `{}` | Set the rolling update strategy for the komodor kubectl proxy deployment |
| components.admissionController | object | See sub-values | Configure the komodor admission controller component |
| components.admissionController.serviceAccount | object | see sub-values | Configure the service account for the admission controller |
| components.admissionController.serviceAccount.create | bool | `true` | Creates a service account for the admission controller |
| components.admissionController.serviceAccount.name | string | `nil` | Name of the service account, Required if `serviceAccount.create` is false |
| components.admissionController.serviceAccount.annotations | object | `{}` | Add annotations to the service account |
| components.admissionController.image | object | see sub-values | Override the komodor admission controller image name or tag. |
| components.admissionController.resources | object | `{"limits":{"cpu":1,"memory":"4Gi"},"requests":{"cpu":"500m","memory":"1Gi"}}` | Set custom resources to the komodor admission controller container - Memory utilization is relative to the amount of: [pods, nodes, pvcs, pvs, pdbs] resources you have in the cluster. |
| components.admissionController.PriorityClassValue | int | `10000000` | Set the priority class value for the komodor admission-controller deployment |
| components.admissionController.priorityClassName | string | `""` | Use an existing priority class for the komodor admission-controller deployment. If not set, will create and use a priority class with PriorityClassValue. WARNING: priorityClassName is immutable and cannot be changed after initial deployment |
| components.admissionController.affinity | object | `{}` | Set node affinity for the komodor admission controller deployment |
| components.admissionController.annotations | object | `{}` | Set annotations for the komodor admission controller deployment |
| components.admissionController.podAnnotations | object | `{}` | Set pod annotations for the komodor admission controller deployment |
| components.admissionController.labels | object | `{}` | Set custom labels |
| components.admissionController.nodeSelector | object | `{}` | Set node selectors for the komodor admission controller deployment |
| components.admissionController.tolerations | list | `[]` | Set tolerations for the komodor admission controller deployment |
| components.admissionController.securityContext | object | `{}` | Set custom securityContext to the komodor admission controller deployment (use with caution) |
| components.admissionController.strategy | object | `{}` | Set the rolling update strategy for the komodor admission controller |
| components.admissionController.extraVolumes | list | `[]` | List of additional volumes to mount in the komodor admission controller deployment/pod      extraVolumes:        - volume:            name: webhook-tls            secret:              secretName: komodor-admission-controller-tls          volumeMount:            name: webhook-tls            mountPath: /etc/komodor/admission/tls            readOnly: true |
| components.admissionController.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorMetrics.PriorityClassValue | int | `10000000` | Set the priority class value for the komodor metrics agent deployment |
| components.komodorMetrics.priorityClassName | string | `""` | Use an existing priority class for the komodor metrics agent deployment. If not set, will create and use a priority class with PriorityClassValue. WARNING: priorityClassName is immutable and cannot be changed after initial deployment |
| components.komodorMetrics.affinity | object | `{}` | Set node affinity for the komodor metrics agent deployment |
| components.komodorMetrics.annotations | object | `{}` | Set annotations for the komodor metrics agent deployment |
| components.komodorMetrics.labels | object | `{}` | Set custom labels |
| components.komodorMetrics.nodeSelector | object | `{}` | Set node selectors for the komodor metrics agent deployment |
| components.komodorMetrics.tolerations | list | `[]` | Set tolerations for the komodor metrics agent deployment |
| components.komodorMetrics.podAnnotations | object | `{}` | Set pod annotations for the komodor metrics agent deployment |
| components.komodorMetrics.securityContext | object | `{}` | Set custom securityContext to the komodor metrics agent deployment (use with caution) |
| components.komodorMetrics.strategy | object | `{}` | Set the rolling update strategy for the komodor metrics agent deployment |
| components.komodorMetrics.metricsInit | object | See sub-values | Configure the komodor metrics init container |
| components.komodorMetrics.metricsInit.image | object | `{ "name": "komodor-agent", "tag": .Chart.AppVersion }` | Override the komodor agent metrics init image name or tag. |
| components.komodorMetrics.metricsInit.resources | object | `{}` | Set custom resources to the komodor agent metrics init container |
| components.komodorMetrics.metricsInit.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorMetrics.metrics.image | object | `{"name":"telegraf","tag":"v2.0.12-alpine"}` | Override the komodor agent metrics image name or tag. |
| components.komodorMetrics.metrics.resources | object | `{"limits":{"cpu":1,"memory":"4Gi"},"requests":{"cpu":0.1,"memory":"384Mi"}}` | Set custom resources to the komodor agent metrics container |
| components.komodorMetrics.metrics.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorMetrics.metrics.sidecar | object | `{"enabled":true}` | Configure the telegraf-init sidecar container |
| components.komodorMetrics.metrics.sidecar.enabled | bool | `true` | Enable the telegraf-init sidecar container |
| components.komodorDaemon | object | See sub-values | Configure the komodor agent components |
| components.komodorDaemon.hostNetwork | bool | `false` | Set host network for the komodor agent daemon |
| components.komodorDaemon.dnsPolicy | string | `"ClusterFirst"` | Set dns policy for the komodor agent daemon |
| components.komodorDaemon.PriorityClassValue | int | `10000000` | Set the priority class value for the komodor daemon deployment |
| components.komodorDaemon.priorityClassName | string | `""` | Use an existing priority class for the komodor daemon deployment. If not set, will create and use a priority class with PriorityClassValue. WARNING: priorityClassName is immutable and cannot be changed after initial deployment |
| components.komodorDaemon.affinity | object | `{}` | Set node affinity for the komodor agent daemon |
| components.komodorDaemon.annotations | object | `{}` | Adds custom annotations - Example: `--set annotations."app\.komodor\.com/app"="komodor-agent"` |
| components.komodorDaemon.labels | object | `{}` | Adds custom labels |
| components.komodorDaemon.nodeSelector | object | `{}` | Set node selectors for the komodor agent daemon |
| components.komodorDaemon.tolerations | list | `[{"operator":"Exists"}]` | Add tolerations to the komodor agent daemon |
| components.komodorDaemon.podAnnotations | object | `{}` | # Add annotations to the komodor agent watcher pod |
| components.komodorDaemon.securityContext | object | `{}` | Set custom securityContext to the komodor agent daemon (use with caution) |
| components.komodorDaemon.updateStrategy | object | `{}` | Set the rolling update strategy for the komodor agent daemon deployment |
| components.komodorDaemon.metricsInit | object | See sub-values | Configure the komodor daemon metrics init container |
| components.komodorDaemon.metricsInit.image | object | `{ "name": "init-daemon-agent", "tag": .Chart.AppVersion }` | Override the komodor agent metrics init image name or tag. |
| components.komodorDaemon.metricsInit.resources | object | `{"limits":{"cpu":1,"memory":"100Mi"},"requests":{"cpu":0.1,"memory":"50Mi"}}` | Set custom resources to the komodor agent metrics init container |
| components.komodorDaemon.metricsInit.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorDaemon.metrics | object | `{"extraEnvVars":[],"image":{"name":"telegraf","tag":"v2.0.12-alpine"},"quiet":false,"resources":{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.1,"memory":"384Mi"}},"sidecar":{"enabled":true}}` | Configure the komodor daemon metrics components |
| components.komodorDaemon.metrics.image | object | `{"name":"telegraf","tag":"v2.0.12-alpine"}` | Override the komodor agent metrics image name or tag. |
| components.komodorDaemon.metrics.resources | object | `{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.1,"memory":"384Mi"}}` | Set custom resources to the komodor agent metrics container |
| components.komodorDaemon.metrics.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorDaemon.metrics.quiet | bool | `false` | Set the quiet mode for the komodor agent metrics |
| components.komodorDaemon.metrics.sidecar | object | `{"enabled":true}` | Configure the telegraf-init sidecar container |
| components.komodorDaemon.metrics.sidecar.enabled | bool | `true` | Enable the telegraf-init sidecar container |
| components.komodorDaemon.nodeEnricher | object | See sub-values | Configure the komodor daemon node enricher components |
| components.komodorDaemon.nodeEnricher.image | object | `{"name":"komodor-agent","tag":null}` | Override the komodor agent node enricher image name or tag. |
| components.komodorDaemon.nodeEnricher.resources | object | `{"limits":{"cpu":"10m","memory":"100Mi"},"requests":{"cpu":"1m","memory":"10Mi"}}` | Set custom resources to the komodor agent node enricher container |
| components.komodorDaemon.nodeEnricher.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorDaemon.opentelemetry | object | See sub-values | Configure the komodor daemon OpenTelemetry collector components |
| components.komodorDaemon.opentelemetry.image | object | `{"name":"public.ecr.aws/komodor-public/komodor-otel-collector","tag":"0.1.4"}` | Override the OpenTelemetry collector image name or tag. |
| components.komodorDaemon.opentelemetry.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Set custom resources to the OpenTelemetry collector container |
| components.komodorDaemon.opentelemetry.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorDaemon.opentelemetry.volumes | object | `{"varlibdockercontainers":{"hostPath":{"path":"/var/lib/docker/containers","type":""},"mountPath":"/var/lib/docker/containers"},"varlogpods":{"hostPath":{"path":"/var/log/pods","type":""},"mountPath":"/var/log/pods"}}` | Configure volumes for OpenTelemetry collector |
| components.komodorDaemon.opentelemetry.volumes.varlogpods | object | `{"hostPath":{"path":"/var/log/pods","type":""},"mountPath":"/var/log/pods"}` | Configure varlogpods volume |
| components.komodorDaemon.opentelemetry.volumes.varlogpods.hostPath | object | `{"path":"/var/log/pods","type":""}` | Configure hostPath for varlogpods volume |
| components.komodorDaemon.opentelemetry.volumes.varlogpods.hostPath.path | string | `"/var/log/pods"` | Host path to mount for pod logs |
| components.komodorDaemon.opentelemetry.volumes.varlogpods.hostPath.type | string | `""` | Type of hostPath ("" (Empty string, default = no checks), Directory, DirectoryOrCreate, File, FileOrCreate, Socket, CharDevice, BlockDevice) |
| components.komodorDaemon.opentelemetry.volumes.varlogpods.mountPath | string | `"/var/log/pods"` | Mount path inside the container for pod logs |
| components.komodorDaemon.opentelemetry.volumes.varlibdockercontainers | object | `{"hostPath":{"path":"/var/lib/docker/containers","type":""},"mountPath":"/var/lib/docker/containers"}` | Configure docker containers volume |
| components.komodorDaemon.opentelemetry.volumes.varlibdockercontainers.hostPath | object | `{"path":"/var/lib/docker/containers","type":""}` | Configure hostPath for docker containers volume |
| components.komodorDaemon.opentelemetry.volumes.varlibdockercontainers.hostPath.path | string | `"/var/lib/docker/containers"` | Host path to mount for docker containers |
| components.komodorDaemon.opentelemetry.volumes.varlibdockercontainers.hostPath.type | string | `""` | Type of hostPath ("" (Empty string, default = no checks), Directory, DirectoryOrCreate, File, FileOrCreate, Socket, CharDevice, BlockDevice) |
| components.komodorDaemon.opentelemetry.volumes.varlibdockercontainers.mountPath | string | `"/var/lib/docker/containers"` | Mount path inside the container for docker containers |
| components.komodorDaemonWindows | object | See sub-values | Configure the komodor agent components |
| components.komodorDaemonWindows.dnsPolicy | string | `"ClusterFirst"` | Set dns policy for the komodor agent daemon |
| components.komodorDaemonWindows.affinity | object | `{}` | Set node affinity for the komodor agent daemon |
| components.komodorDaemonWindows.annotations | object | `{}` | Adds custom annotations - Example: `--set annotations."app\.komodor\.com/app"="komodor-agent"` |
| components.komodorDaemonWindows.labels | object | `{}` | Adds custom labels |
| components.komodorDaemonWindows.nodeSelector | object | `{}` | Set node selectors for the komodor agent daemon |
| components.komodorDaemonWindows.tolerations | list | `[{"operator":"Exists"}]` | Add tolerations to the komodor agent daemon |
| components.komodorDaemonWindows.podAnnotations | object | `{}` | # Add annotations to the komodor agent watcher pod |
| components.komodorDaemonWindows.updateStrategy | object | `{}` | Set the rolling update strategy for the komodor agent daemon deployment |
| components.komodorDaemonWindows.metricsInit | object | See sub-values | Configure the komodor daemon metrics init container |
| components.komodorDaemonWindows.metricsInit.image | object | `{ "name": "init-daemon-agent", "tag": .Chart.AppVersion }` | Override the komodor agent metrics init image name or tag. |
| components.komodorDaemonWindows.metricsInit.resources | object | `{"limits":{"cpu":1,"memory":"100Mi"},"requests":{"cpu":0.1,"memory":"50Mi"}}` | Set custom resources to the komodor agent metrics init container |
| components.komodorDaemonWindows.metricsInit.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorDaemonWindows.metrics | object | `{"extraEnvVars":[],"image":{"name":"telegraf-windows","tag":"v2.0.12"},"quiet":false,"resources":{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.1,"memory":"384Mi"}},"sidecar":{"enabled":true}}` | Configure the komodor daemon metrics components |
| components.komodorDaemonWindows.metrics.image | object | `{"name":"telegraf-windows","tag":"v2.0.12"}` | Override the komodor agent metrics image name or tag. |
| components.komodorDaemonWindows.metrics.resources | object | `{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.1,"memory":"384Mi"}}` | Set custom resources to the komodor agent metrics container |
| components.komodorDaemonWindows.metrics.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorDaemonWindows.metrics.quiet | bool | `false` | Set the quiet mode for the komodor agent metrics |
| components.komodorDaemonWindows.metrics.sidecar | object | `{"enabled":true}` | Configure the telegraf-init sidecar container |
| components.komodorDaemonWindows.metrics.sidecar.enabled | bool | `true` | Enable the telegraf-init sidecar container |
| components.gpuAccess | object | `{"enabled":false,"image":"alpine:latest","labels":{},"nodeSelector":{},"pullPolicy":"IfNotPresent","resources":{"limits":{"cpu":"250m","memory":"100Mi"},"requests":{"cpu":"100m","memory":"50Mi"}},"tolerations":[{"effect":"NoSchedule","key":"nvidia.com/gpu","operator":"Exists"}]}` | settings for GPU host diagnostics accessor DaemonSet |
| components.gpuAccess.enabled | bool | `false` | Enable creating privileged CUDA container with host mounts to access GPU info |
| components.gpuAccess.image | string | `"alpine:latest"` | CUDA image to be used for GPU access container |
| components.gpuAccess.pullPolicy | string | `"IfNotPresent"` | Default Image pull policy for the GPU accessor image acceptable values <ifNotPresent\Always\Never>. |
| components.gpuAccess.resources | object | `{"limits":{"cpu":"250m","memory":"100Mi"},"requests":{"cpu":"100m","memory":"50Mi"}}` | Set custom resources to the GPU accessor container |
| components.gpuAccess.labels | object | `{}` | Adds custom labels |
| components.gpuAccess.nodeSelector | object | `{}` | Set node selectors for the komodor agent daemon |
| components.gpuAccess.tolerations | list | `[{"effect":"NoSchedule","key":"nvidia.com/gpu","operator":"Exists"}]` | Add tolerations to the komodor agent daemon |
| allowedResources.event | bool | `true` | Enables watching `event` |
| allowedResources.deployment | bool | `true` | Enables watching `deployments` |
| allowedResources.replicationController | bool | `true` | Enables watching `replicationControllers` |
| allowedResources.replicaSet | bool | `true` | Enables watching `replicaSets` |
| allowedResources.daemonSet | bool | `true` | Enables watching `daemonSets` |
| allowedResources.statefulSet | bool | `true` | Enables watching `statefulSets` |
| allowedResources.service | bool | `true` | Enables watching `services` |
| allowedResources.pod | bool | `true` | Enables watching `pods` |
| allowedResources.job | bool | `true` | Enables watching `jobs` |
| allowedResources.cronjob | bool | `true` | Enables watching `cronjobs` |
| allowedResources.node | bool | `true` | Enables watching `nodes` |
| allowedResources.clusterRole | bool | `true` | Enables watching `clusterRoles` |
| allowedResources.serviceAccount | bool | `true` | Enables watching `serviceAccounts` |
| allowedResources.persistentVolume | bool | `true` | Enables watching `persistentVolumes` |
| allowedResources.persistentVolumeClaim | bool | `true` | Enables watching `persistentVolumeClaims` |
| allowedResources.namespace | bool | `true` | Enables watching `namespaces` |
| allowedResources.secret | bool | `true` | Enables watching `secrets` |
| allowedResources.configMap | bool | `true` | Enables watching `configmaps` |
| allowedResources.ingress | bool | `true` | Enables watching `ingresses` |
| allowedResources.endpoints | bool | `true` | Enables watching `endpoints` |
| allowedResources.storageClass | bool | `true` | Enables watching `storageClasses` |
| allowedResources.rollout | bool | `true` | Enables watching `rollouts` |
| allowedResources.metrics | bool | `true` | Enables watching `metrics` |
| allowedResources.limitRange | bool | `true` | Enables watching `limitRange` |
| allowedResources.podTemplate | bool | `true` | Enables watching `podTemplate` |
| allowedResources.resourceQuota | bool | `true` | Enables watching `resourceQuota` |
| allowedResources.admissionRegistrationResources | bool | `true` | Enables watching `admissionRegistrationResources` |
| allowedResources.controllerRevision | bool | `true` | Enables watching `controllerRevision` |
| allowedResources.authorizationResources | bool | `true` | Enables watching `authorizationResources` |
| allowedResources.horizontalPodAutoscaler | bool | `true` | Enables watching `horizontalPodAutoscaler` |
| allowedResources.certificateSigningRequest | bool | `true` | Enables watching `certificateSigningRequest` |
| allowedResources.lease | bool | `true` | Enables watching `lease` |
| allowedResources.endpointSlice | bool | `true` | Enables watching `endpointslice` |
| allowedResources.flowControlResources | bool | `true` | Enables watching `flowControlResources` |
| allowedResources.ingressClass | bool | `true` | Enables watching `ingressClass` |
| allowedResources.networkPolicy | bool | `true` | Enables watching `networkPolicy` |
| allowedResources.runtimeClass | bool | `true` | Enables watching `runtimeClass` |
| allowedResources.policyResources | bool | `true` | Enables watching `policyResources` |
| allowedResources.clusterRoleBinding | bool | `true` | Enables watching `clusterRoleBinding` |
| allowedResources.roleBinding | bool | `true` | Enables watching `roleBinding` |
| allowedResources.role | bool | `true` | Enables watching `role` |
| allowedResources.priorityClass | bool | `true` | Enables watching `priorityClass` |
| allowedResources.csiDriver | bool | `true` | Enables watching `csiDriver` |
| allowedResources.csiNode | bool | `true` | Enables watching `csiNode` |
| allowedResources.csiStorageCapacity | bool | `true` | Enables watching `csiStorageCapacity` |
| allowedResources.volumeAttachment | bool | `true` | Enables watching `volumeAttachment` |
| allowedResources.argoWorkflows | object | See sub-values | Enables watching argo resources |
| allowedResources.argoWorkflows.workflows | bool | `true` | Enables watching Argo `workflows` |
| allowedResources.argoWorkflows.workflowTemplates | bool | `true` | Enables watching Argo `workflowTemplates` |
| allowedResources.argoWorkflows.clusterWorkflowTemplates | bool | `true` | Enables watching Argo `clusterWorkflowTemplates` |
| allowedResources.argoWorkflows.cronWorkflows | bool | `true` | Enables watching Argo `cronWorkflows` |
| allowedResources.customReadAPIGroups | list | `[]` | A list of custom API groups to allow read access to - each array element should be a string which represents the group name |
| allowedResources.allowReadAll | bool | `true` | Allow reading all the resources in the cluster |

[README.md](README.md)
> **Tip**: You can use the default [values.yaml](values.yaml)

### Using a Proxy

Komodor supports the standard proxy environment variables (`HTTP_PROXY, HTTPS_PROXY, NO_PROXY`) as well as these variables prefixed by `KOMOKW_` which will assign the proxy only to the HTTP clients communicating with Komodor. This is useful in case you want to leave the communication to the Kubernetes API in-cluster.

#### Use-cases:

- In-cluster proxy (which can communicate with local K8s IPs) - You can use either one of the solutions.
- External proxy (which _cannot_ communicate with the local K8s IPs) - You need to use the `KOMOKW_` prefix to the proxy environment variables to have only the traffic to Komodor pass through the proxy. If you're using the Helm chart - this can be disabled by setting `--set proxy.komodorOnly=false`.

