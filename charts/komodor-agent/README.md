# komodor-agent

Watches and sends kubernetes resource-related events

![AppVersion: 0.2.132](https://img.shields.io/badge/AppVersion-0.2.132-informational?style=flat-square)

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
| telegrafImageVersion | string | `"v1.34.1-build1-alpine"` | Telegraf version to be used |
| telegrafWindowsImageVersion | string | `"v1.34.1-build1-windows"` | Telegraf version to be used for windows |
| serviceAccount | object | See sub-values | Configure service account for the agent |
| serviceAccount.create | bool | `true` | Creates a service account for the agent |
| serviceAccount.name | string | `nil` | Name of the service account, Required if `serviceAccount.create` is false |
| serviceAccount.annotations | object | `{}` | Add annotations to the service account |
| proxy.enabled | bool | `false` | Enable proxy for the agent |
| proxy.komodorOnly | bool | `true` | Configure proxy to be applied only on communication to Komodor servers (comms. to K8S API remains without proxy) |
| proxy.http | string | `nil` | Configure Proxy setting (HTTP_PROXY) `eg. http://proxy.com:8080` |
| proxy.https | string | `nil` | Configure Proxy setting (HTTPS_PROXY) `eg. https://proxy.com:8080` |
| proxy.no_proxy | string | `nil` | Specify specific domains to ignore proxy for. eg. `komodor.com,google.com` |
| customCa | object | See sub-values | Configure custom CA for the agent |
| customCa.enabled | bool | `false` | Enable custom CA certificate for the agent |
| customCa.secretName | string | `nil` | Name of the secret containing the CA |
| customCa.resources | dict | `{"limits":{"cpu":"10m","memory":"100Mi"},"requests":{"cpu":"1m","memory":"10Mi"}}` | Set custom resources to the custom CA container |
| imageRepo | string | `"public.ecr.aws/komodor-public"` | Override the komodor agent image repository. |
| pullPolicy | string | `"IfNotPresent"` | Default Image pull policy for the komodor agent image exceptable values <ifNotPresent\Always\Never>. |
| imagePullSecret | string | `nil` | Set the image pull secret for the komodor agent |
| capabilities | object | See sub-values | Configure the agent capabilities |
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
| components | object | See sub-values | Configure the agent components |
| components.komodorAgent | object | See sub-values | Configure the komodor agent components |
| components.komodorAgent.PriorityClassValue | int | `10000000` | Set the priority class value for the komodor agent deployment |
| components.komodorAgent.affinity | object | `{}` | Set node affinity for the komodor agent deployment |
| components.komodorAgent.annotations | object | `{}` | Set annotations for the komodor agent deployment |
| components.komodorAgent.labels | object | `{}` | Set custom labels |
| components.komodorAgent.nodeSelector | object | `{}` | Set node selectors for the komodor agent deployment |
| components.komodorAgent.tolerations | list | `[]` | Set tolerations for the komodor agent deployment |
| components.komodorAgent.podAnnotations | object | `{}` | Set pod annotations for the komodor agent deployment |
| components.komodorAgent.securityContext | object | `{}` | Set custom securityContext to the komodor agent deployment (use with caution) |
| components.komodorAgent.strategy | object | `{}` | Set the rolling update strategy for the komodor agent deployment |
| components.komodorAgent.watcher.image | object | `{ "name": "k8s-watcher", "tag": .Chart.AppVersion }` | Override the komodor agent watcher image name or tag. |
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
| components.komodorMetrics.PriorityClassValue | int | `10000000` | Set the priority class value for the komodor metrics agent deployment |
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
| components.komodorMetrics.metrics.image | object | `{"name":"telegraf","tag":"v1.34.1-build1-alpine"}` | Override the komodor agent metrics image name or tag. |
| components.komodorMetrics.metrics.resources | object | `{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.1,"memory":"384Mi"}}` | Set custom resources to the komodor agent metrics container |
| components.komodorMetrics.metrics.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorDaemon | object | See sub-values | Configure the komodor agent components |
| components.komodorDaemon.hostNetwork | bool | `false` | Set host network for the komodor agent daemon |
| components.komodorDaemon.dnsPolicy | string | `"ClusterFirst"` | Set dns policy for the komodor agent daemon |
| components.komodorDaemon.PriorityClassValue | int | `10000000` | Set the priority class value for the komodor daemon deployment |
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
| components.komodorDaemon.metrics | object | `{"extraEnvVars":[],"image":{"name":"telegraf","tag":"v1.34.1-build1-alpine"},"resources":{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.1,"memory":"384Mi"}}}` | Configure the komodor daemon metrics components |
| components.komodorDaemon.metrics.image | object | `{"name":"telegraf","tag":"v1.34.1-build1-alpine"}` | Override the komodor agent metrics image name or tag. |
| components.komodorDaemon.metrics.resources | object | `{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.1,"memory":"384Mi"}}` | Set custom resources to the komodor agent metrics container |
| components.komodorDaemon.metrics.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorDaemon.nodeEnricher | object | See sub-values | Configure the komodor daemon node enricher components |
| components.komodorDaemon.nodeEnricher.image | object | `{"name":"komodor-agent","tag":null}` | Override the komodor agent node enricher image name or tag. |
| components.komodorDaemon.nodeEnricher.resources | object | `{"limits":{"cpu":"10m","memory":"100Mi"},"requests":{"cpu":"1m","memory":"10Mi"}}` | Set custom resources to the komodor agent node enricher container |
| components.komodorDaemon.nodeEnricher.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
| components.komodorDaemonWindows | object | See sub-values | Configure the komodor agent components |
| components.komodorDaemonWindows.dnsPolicy | string | `"ClusterFirst"` | Set dns policy for the komodor agent daemon |
| components.komodorDaemonWindows.affinity | object | `{}` | Set node affinity for the komodor agent daemon |
| components.komodorDaemonWindows.annotations | object | `{}` | Adds custom annotations - Example: `--set annotations."app\.komodor\.com/app"="komodor-agent"` |
| components.komodorDaemonWindows.labels | object | `{}` | Adds custom labels |
| components.komodorDaemonWindows.nodeSelector | object | `{}` | Set node selectors for the komodor agent daemon |
| components.komodorDaemonWindows.tolerations | list | `[{"operator":"Exists"}]` | Add tolerations to the komodor agent daemon |
| components.komodorDaemonWindows.podAnnotations | object | `{}` | # Add annotations to the komodor agent watcher pod |
| components.komodorDaemonWindows.updateStrategy | object | `{}` | Set the rolling update strategy for the komodor agent daemon deployment |
| components.komodorDaemonWindows.metrics | object | `{"extraEnvVars":[],"image":{"name":"telegraf-windows","tag":"v1.34.1-build1-windows"},"resources":{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.1,"memory":"384Mi"}}}` | Configure the komodor daemon metrics components |
| components.komodorDaemonWindows.metrics.image | object | `{"name":"telegraf-windows","tag":"v1.34.1-build1-windows"}` | Override the komodor agent metrics image name or tag. |
| components.komodorDaemonWindows.metrics.resources | object | `{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":0.1,"memory":"384Mi"}}` | Set custom resources to the komodor agent metrics container |
| components.komodorDaemonWindows.metrics.extraEnvVars | list | `[]` | List of additional environment variables, Each entry is a key-value pair |
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

