# Komodor.io

## TL;DR;

```bash
helm repo add komodorio https://helm-charts.komodor.io
helm repo update
helm upgrade --install k8s-watcher komodorio/k8s-watcher --set apiKey=YOUR_API_KEY_HERE --set watcher.clusterName=CLUSTER_NAME --set watcher.allowReadingPodLogs=true --set watcher.enableAgentTaskExecution=true --set watcher.enableAgentTaskExecutionV2=true --set watcher.enableHelm=true  --set helm.enableActions=true --wait --timeout=90s
```

In case of error try contact us for assistance via intercom at: https://app.komodor.com
Or run:

1. Logs of k8s-watcher

```bash
kubectl logs --tail=10 deployment/k8s-watcher  -n komodor
```

2. Helm status

```bash
helm status k8s-watcher
```

3. Reinstall

```bash
helm uninstall helm-k8s-watcher
```

## Introduction

This chart bootstraps a Kubernetes Resources/Event Watcher deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

### Supported architectures

- [x] linux/amd64
- [x] linux/arm64

## Prerequisites

- Kubernetes 1.19+ (older versions not officially supported)
- Helm 2/3

## Installing the Chart

To install the chart with the release name `k8s-watcher`:

```bash
helm upgrade --install k8s-watcher komodorio/k8s-watcher --create-namespace --set apiKey=YOUR_API_KEY_HERE --set watcher.clusterName=CLUSTER_NAME
```

The command deploys the Komodor K8S-Watcher on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Api Key

The Komodor kubernetes api key can be provided in the helm upgrade command, in the `values.yaml` file or can be taken from an existing kubernetes secret resource.
When using an existing kubernetes secret resource, specify the secret name in `existingSecret` and store the api key under the name 'apiKey'.

## Uninstalling the Chart

To uninstall/delete the `k8s-watcher` deployment:

Helm 3:

```bash
helm uninstall k8s-watcher
```

Helm 2:

```bash
helm delete --purge k8s-watcher
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Alternative: Install without Helm

To install the chart directly with kubectl, use the manifests located in `./kube-install`.

1. Make sure to set the apiKey (as base 64) secret value in `./kube-install/k8s-watcher/templates/secret-credentials.yaml`
   - `KOMOKW_APIKEY=YOUR_APIKEY sed -i "s/YOUR_APIKEY_AS_BASE_64/$(echo $KOMOKW_APIKEY | base64)/g" kube-install/k8s-watcher/templates/secret-credentials.yaml`
2. Then just apply everything in order:
   - `kubectl apply -f ./kube-install/k8s-watcher/templates/namespace.yaml`
   - `kubectl apply -f ./kube-install/k8s-watcher/templates`

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter                                          | Description                                                                                                                                                                                                                  | Default                             |
|----------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| `apiKey`                                           | Komodor kubernetes api key (required if `existingSecret` not specified)                                                                                                                                                      | ``                                  |
| `existingSecret`                                   | Existing kubernetes secret resource containing Komodor kubernetes apiKey (required if `apiKey` not specified)                                                                                                                | ``                                  |
| `enableRWCache`                                    | Mounts a ReadWrite cache volume for the kubernetes api cache                                                                                                                                                                 | `true`                              |
| `watcher.actions.basic`                            | Enables basic actions (Delete pods. Scale and restart deployments, statefulsets, replicasets. Restart and trigger jobs)                                                                                                      | `false`                             |
| `watcher.actions.advanced`                         | Enables advanced actions (Update, Create and Delete resources)                                                                                                                                                               | `false`                             |
| `watcher.actions.podExec`                          | Enables executing arbitrary commands in pod containers                                                                                                                                                                       | `false`                             |
| `watcher.actions.portforward`                      | Enables port-forwarding for pods                                                                                                                                                                                             | `false`                             |
| `watcher.redact`                                   | List of regular expressions. Config values for keys that matches one of these expressions will show up at Komodor as "REDACTED:\<SHA of config value\>"                                                                      | `[]`                                |
| `watcher.redactLogs`                               | List of regular expressions. Patterns in Logs that matches one of these expressions will show up at Komodor as `<REDACTED>`                                                                                                  | `[]`                                |
| `watcher.enableHelm`                               | Enables reporting of unredacted secrets of type "helm.sh/release.v1" containing helm releases data                                                                                                                           | `true`                              |
| `watcher.clusterName`                              | Override auto-discovery of Cluster Name with one of your choosing                                                                                                                                                            | ``                                  |
| `watcher.watchNamespace`                           | Watch a specific namespace, or all namespaces ("", "all")                                                                                                                                                                    | `all`                               |
| `watcher.namespacesDenylist`                       | Exclude specific namespaces (list)                                                                                                                                                                                           | `[]`                                |
| `watcher.logsNamespacesDenylist`                       | Exclude the ability to fetch container logs from specific namespaces (list)                                                                                                                                                                                           | `[]`                                |
| `watcher.nameDenylist`                             | Exclude specific resource names that contains any of these strings (list) - example: `` watcher.nameDenylist=["dont-watch"] --> `pod/backend-dont-watch` wont be collected ``                                                | `[]`                                |
| `watcher.collectHistory`                           | On startup collect existing cluster resources in addition to watching new resources (true / false)                                                                                                                           | `true`                              |
| `watcher.collectHistoryFrom`                       | Allows configuring specific resources to list on startup instead of everything (default). `[]string` - example: `watcher.collectHistoryFrom=["deployment","daemonset","statefulset"]` or `KOMOKW_COLLECT_HISTORY_FROM="deployment daemonset statefulset"`                                         | `""`                              |
| `watcher.monitoringFQDN`                           | If you have custom FQDN for you monitoring tool (e.x. Prometheus)                                                                                                                                                            | `https:/www.myPrometheusServer.com` |
| `watcher.sinks.webhook.headers`                    | Headers to attach to the webhooks                                                                                                                                                                                            | `{}`                                |
| `watcher.resources.event`                          | Enables watching Event                                                                                                                                                                                                       | `true`                              |
| `watcher.resources.deployment`                     | Enables watching Deployments                                                                                                                                                                                                 | `true`                              |
| `watcher.resources.replicationController`          | Enables watching ReplicationControllers                                                                                                                                                                                      | `true`                              |
| `watcher.resources.replicaSet`                     | Enables watching ReplicaSets                                                                                                                                                                                                 | `true`                              |
| `watcher.resources.daemonSet`                      | Enables watching DaemonSets                                                                                                                                                                                                  | `true`                              |
| `watcher.resources.statefulSet`                    | Enables watching StatefulSets                                                                                                                                                                                                | `true`                              |
| `watcher.resources.service`                        | Enables watching Services                                                                                                                                                                                                    | `true`                              |
| `watcher.resources.pod`                            | Enables watching Pods                                                                                                                                                                                                        | `true`                              |
| `watcher.resources.job`                            | Enables watching Jobs                                                                                                                                                                                                        | `true`                              |
| `watcher.resources.node`                           | Enables watching Nodes                                                                                                                                                                                                       | `true`                              |
| `watcher.resources.clusterRole`                    | Enables watching ClusterRoles                                                                                                                                                                                                | `true`                              |
| `watcher.resources.serviceAccount`                 | Enables watching ServiceAccounts                                                                                                                                                                                             | `true`                              |
| `watcher.resources.persistentVolume`               | Enables watching PersistentVolumes                                                                                                                                                                                           | `true`                              |
| `watcher.resources.persistentVolumeClaim`          | Enables watching PersistentVolumeClaims                                                                                                                                                                                      | `true`                              |
| `watcher.resources.namespace`                      | Enables watching Namespaces                                                                                                                                                                                                  | `true`                              |
| `watcher.resources.secret`                         | Enables watching Secrets                                                                                                                                                                                                     | `false`                             |
| `watcher.resources.configMap`                      | Enables watching ConfigMaps                                                                                                                                                                                                  | `true`                              |
| `watcher.resources.ingress`                        | Enables watching Ingresses                                                                                                                                                                                                   | `true`                              |
| `watcher.resources.storageClass`                   | Enables watching StorageClasses                                                                                                                                                                                              | `true`                              |
| `watcher.resources.rollout`                        | Enables watching Argo Rollouts                                                                                                                                                                                               | `true`                              |
| `watcher.resources.metrics`                        | Enables watching Metrics                                                                                                                                                                                                     | `true`                              |
| `watcher.resources.limitRange`                     | Enables watching LimitRange                                                                                                                                                                                                  | `true`                              |
| `watcher.resources.podTemplate`                    | Enables watching PodTemplate                                                                                                                                                                                                 | `true`                              |
| `watcher.resources.resourceQuota`                  | Enables watching ResourceQuota                                                                                                                                                                                               | `true`                              |
| `watcher.resources.admissionRegistrationResources` | Enables watching MutatingWebhookConfigurations and ValidatingWebhookConfigurations                                                                                                                                           | `true`                              |
| `watcher.resources.controllerRevision`             | Enables watching ControllerRevision                                                                                                                                                                                          | `true`                              |
| `watcher.resources.authorizationResources`         | Enables watching Authorization Resources                                                                                                                                                                                     | `true`                              |
| `watcher.resources.horizontalPodAutoscaler`        | Enables watching HorizontalPodAutoscaler                                                                                                                                                                                     | `true`                              |
| `watcher.resources.certificateSigningRequest`      | Enables watching CertificateSigningRequest                                                                                                                                                                                   | `true`                              |
| `watcher.resources.lease`                          | Enables watching Lease                                                                                                                                                                                                       | `true`                              |
| `watcher.resources.endpointSlice`                  | Enables watching EndpointSlice                                                                                                                                                                                               | `true`                              |
| `watcher.resources.flowControlResources`           | Enables watching FlowControl Resources                                                                                                                                                                                       | `true`                              |
| `watcher.resources.ingressClass`                   | Enables watching IngressClass                                                                                                                                                                                                | `true`                              |
| `watcher.resources.networkPolicy`                  | Enables watching NetworkPolicy                                                                                                                                                                                               | `true`                              |
| `watcher.resources.runtimeClass`                   | Enables watching RuntimeClass                                                                                                                                                                                                | `true`                              |
| `watcher.resources.policyResources`                | Enables watching Policy Resources                                                                                                                                                                                            | `true`                              |
| `watcher.resources.clusterRoleBinding`             | Enables watching ClusterRoleBinding                                                                                                                                                                                          | `true`                              |
| `watcher.resources.roleBinding`                    | Enables watching RoleBinding                                                                                                                                                                                                 | `true`                              |
| `watcher.resources.role`                           | Enables watching Role                                                                                                                                                                                                        | `true`                              |
| `watcher.resources.PriorityClass`                  | Enables watching PriorityClass                                                                                                                                                                                               | `true`                              |
| `watcher.resources.csiDriver`                      | Enables watching CSIDriver                                                                                                                                                                                                   | `true`                              |
| `watcher.resources.csiNode`                        | Enables watching CSINode                                                                                                                                                                                                     | `true`                              |
| `watcher.resources.csiStorageCapacity `            | Enables watching CSIStorageCapacity                                                                                                                                                                                          | `true`                              |
| `watcher.resources.volumeAttachment`               | Enables watching VolumeAttachment                                                                                                                                                                                            | `true`                              |
| `watcher.resources.allowReadAll`                   | Enables reading all the resources in the cluster                                                                                                                                                                             | `true`                              |
| `watcher.resources.customReadAPIGroups`            | A list of custom API groups to allow read access to - each array element should be a string which represents the group name                                                                                                  | `[]`                                |
| `watcher.servers.healthCheck.port`                 | Port of the health check server                                                                                                                                                                                              | `8090`                              |
| `watcher.networkMapper.enable`                     | Enable the network mapper                                                                                                                                                                                                    | `true`                              |
| `resources.requests.cpu`                           | CPU resource requests                                                                                                                                                                                                        | `0.25`                              |
| `resources.limits.cpu`                             | CPU resource limits                                                                                                                                                                                                          | `1`                                 |
| `resources.requests.memory`                        | Memory resource requests                                                                                                                                                                                                     | `256Mi`                             |
| `resources.limits.memory`                          | Memory resource limits                                                                                                                                                                                                       | `4096Mi`                            |
| `image.repository`                                 | Image registry/name                                                                                                                                                                                                          | `docker.io/komodorio/k8s-watcher`   |
| `image.tag`                                        | Image tag                                                                                                                                                                                                                    | `0.1.10`                            |
| `image.pullPolicy`                                 | Image pull policy                                                                                                                                                                                                            | `IfNotPresent`                      |
| `imagePullSecret`                                  | Image pull secret                                                                                                                                                                                                            | ``                                  |
| `serviceAccount.create`                            | Creates a service account                                                                                                                                                                                                    | `true`                              |
| `serviceAccount.name`                              | Optional name for the service account                                                                                                                                                                                        | `{RELEASE_FULLNAME}`                |
| `proxy.enabled`                                    | Configure proxy for watcher                                                                                                                                                                                                  | `false`                             |
| `proxy.komodorOnly`                                | Configure proxy to be applied only on communication to Komodor servers (comms. to K8S API remains without proxy)                                                                                                             | `true`                              |
| `proxy.http`                                       | Configure Proxy setting (HTTP_PROXY)                                                                                                                                                                                         | ``                                  |
| `proxy.https`                                      | Configure Proxy setting (HTTPS_PROXY)                                                                                                                                                                                        | ``                                  |
| `proxy.no_proxy`                                   | Configure Proxy setting (NO_PROXY)                                                                                                                                                                                           | ``                                  |
| `watcher.controller.resync.period`                 | Resync period (in minutes, minimum 5) to resync the state of selected controllers (deployment, daemonset, statefulset)                                                                                                       | `"0"`                               |
| `watcher.enableAgentTaskExecution`                 | Enable to the agent to execute tasks in the cluster such as log streaming                                                                                                                                                    | `true`                              |
| `watcher.enableAgentTaskExecutionV2`               | Enable to the agent to execute tasks in the cluster such as log streaming (dependent on `watcher.enableAgentTaskExecution`)                                                                                                  | `true`                              |
| `watcher.allowReadingPodLogs`                      | Enable the agent to read pod logs from the cluster                                                                                                                                                                           | `true`                              |
| `watcher.telemetry.enable`                         | Enable the agent's telemetry                                                                                                                                                                                                 | `true`                              |
| `watcher.telemetry.collectApiServerMetrics`        | Enable the agent's telemetry to collect metrics on the k8s api server                                                                                                                                                        | `false`                              |
| `watcher.telemetry.bufferLength`                   | Sets the buffer length of the telemetry client (capacity before flush)                                                                                                                                                       | `2000`                              |
| `watcher.telemetry.bufferFlushInterval`            | Sets the buffer flush interval of the telemetry client (time duration in seconds)                                                                                                                                            | `5`                                 |
| `createNamespace`                                  | Creates the namespace                                                                                                                                                                                                        | `true`                              |
| `podAnnotations`                                   | Adds custom annotations on the agent pod - Example: `--set podAnnotations."app\.komodor\.com/app"="komodor-agent"`                                                                                                           | `{}`                                |
| `deploymentAnnotations`                            | Adds custom annotations on the agent deployment - Example: `--set deploymentAnnotations."app\.komodor\.com/app"="komodor-agent"`                                                                                             | `{}`                                |
| `nodeSelector`                                     | Adds a custom node selector label on the agent deployment - Example: `--set nodeSelector=nodegroup:shared`                                                                                                                   | `{}`                                |
| `watcher.kubeconfigPath`                           | Specifies a custom absolute path to load the kubeconfig file for authenticating to the requested cluster (by default, the agent will try to use the Pod's Service Account if it exists, or fallback to `$HOME/.kube/config`) | `""`                                |
| `watcher.kubeMasterUrl`                            | Specifies a custom absolute URL to the kubernetes master API for authenticating to the requested cluster (takes precedence over `kubeconfigPath` if set)                                                                     | `""`                                |
| `helm.volumeSizeLimit`                             | The size limit for the mounted volume holding helm metadata                                                                                                                                                                  | `256Mi`                             |
| `metrics.enabled`                                  | Enables metrics collection (CPU & Memory)                                                                                                                                                                                    | `false`                             |
| `network_mapper.debug`   | Enable debug mode for network mapper | `false` |
| `network_mapper.mapper.resources`  | Set network mapper resources | `{}` |
| `network_mapper.sniffer.resources` | Set resources for network mapper sniffer | `{}` |
| `daemon.tolerations`                               | Tolerations for daemonset pod assignment - Example:   --set 'daemon.tolerations[0].key=my-key' --set 'daemon.tolerations[0].operator=Equal' --set 'daemon.tolerations[0].value=my-value' --set 'daemon.tolerations[0].effect=NoSchedule'                                                                                                                                                                         | `[]`                                |
| `supervisor.enabled`                                  | Enables supervisor sidecar (monitoring the agent)                                                                                                                                                                                    | `false`                             |



The above parameters map to a yaml configuration file used by the watcher.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
helm upgrade --install k8s-watcher komodorio/k8s-watcher --set apiKey="YOUR_API_KEY_HERE" --set watcher.enableAgentTaskExecution=true --set watcher.allowReadingPodLogs=true --set watcher.actions=true
```

Alternativly, you can pass the configuration as environment variables using the `KOMOKW_` prefix and by replacing all the `.` to `_`, for the root items the camelcase transforms into underscores as well. For example,

```bash
# apiKey
KOMOKW_API_KEY=1a2b3c4d5e6f7g7h
# watcher.resources.replicaSet
KOMOKW_RESOURCES_REPLICASET=false

# watcher.watchNamespace
KOMOKW_WATCH_NAMESPACE=my-namespace
# watcher.collectHistory
KOMOKW_COLLECT_HISTORY=true

# watcher.redact
KOMOKW_REDACT="password PG.*"
KOMOKW_REDACT_LOGS="password=(.+?)\b (?U)\"sessionId\": (\".+\"{1})"
```

> **Tip**: You can use the default [values.yaml](values.yaml)

### Using a Proxy

Komodor supports the standard proxy environment variables (`HTTP_PROXY, HTTPS_PROXY, NO_PROXY`) as well as these variables prefixed by `KOMOKW_` which will assign the proxy only to the HTTP clients communicating with Komodor. This is useful in case you want to leave the communication to the Kubernetes API in-cluster.

#### Use-cases:

- In-cluster proxy (which can communicate with local K8s IPs) - You can use either one of the solutions.
- External proxy (which _cannot_ communicate with the local K8s IPs) - You need to use the `KOMOKW_` prefix to the proxy environment variables to have only the traffic to Komodor pass through the proxy. If you're using the Helm chart - this can be disabled by setting `--set proxy.komodorOnly=false`.
