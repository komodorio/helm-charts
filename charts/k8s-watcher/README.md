# Komodor.io

## TL;DR;

```bash
helm repo add komodorio https://helm-charts.komodor.io
helm repo update
helm upgrade --install k8s-watcher komodorio/k8s-watcher --set apiKey=YOUR_API_KEY_HERE --set watcher.clusterName=CLUSTER_NAME
```

## Introduction

This chart bootstraps a Kubernetes Resources/Event Watcher deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

### Supported architectures
- [x] linux/amd64
- [x] linux/arm64 (v8) - starting from agent version 0.1.28

The default is `linux/amd64`. If you wish to install the chart for `linux/arm64` all you need to do is set image.arm flag. For example: `--set image.arm=true`

## Prerequisites

- Kubernetes 1.16+ (older versions not tested)
- Helm 2/3

## Installing the Chart

To install the chart with the release name `k8s-watcher`:

```bash
helm upgrade --install k8s-watcher komodorio/k8s-watcher --create-namespace --set apiKey=YOUR_API_KEY_HERE --set watcher.clusterName=CLUSTER_NAME
```

The command deploys the Komodor K8S-Watcher on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`


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

| Parameter                                 | Description                                                              | Default                                    |
|-------------------------------------------|--------------------------------------------------------------------------|--------------------------------------------|
| `apiKey`                                  | Komodor kubernetes api key (required)                                    | ``                                         |
| `watcher.redact`                                  | List of regular expressions. Config values for keys that matches one of these expressions will show up at Komodor as "REDACTED:\<SHA of config value\>" | `[]`
| `watcher.clusterName`                     | Override auto-discovery of Cluster Name with one of your choosing        | ``                                         |
| `watcher.watchNamespace`                  | Watch a specific namespace, or all namespaces ("", "all")                | `all`                                      |
| `watcher.namespacesBlacklist`             | Blacklist specific namespaces (list)                                     | `[kube-system]`                            |
| `watcher.nameBlacklist`                   | Blacklist specific resource names that contains any of these strings (list) - example: ```watcher.nameBlacklist=["dont-watch"] --> `pod/backend-dont-watch` wont be collected``` | `[]`                                                |
| `watcher.collectHistory`                  | On startup collect existing cluster resources in addition to watching new resources (true / false)                        | `true`                                    |
| `watcher.sinks.webhook.enabled`           | Enables a Webhook output                                                 | `true`                                     |
| `watcher.sinks.webhook.url`               | URL to send webhooks to                                                  | `https://app.komodor.io/k8s-events/event/` |
| `watcher.sinks.webhook.headers`           | Headers to attach to the webhooks                                        | `{}`                                       |
| `watcher.resources.event`                 | Enables watching Event                                                   | `true`                                     |
| `watcher.resources.deployment`            | Enables watching Deployments                                             | `true`                                     |
| `watcher.resources.replicationController` | Enables watching ReplicationControllers                                  | `true`                                     |
| `watcher.resources.replicaSet`            | Enables watching ReplicaSets                                             | `true`                                     |
| `watcher.resources.daemonSet`             | Enables watching DaemonSets                                              | `true`                                     |
| `watcher.resources.statefulSet`           | Enables watching StatefulSets                                            | `true`                                     |
| `watcher.resources.service`               | Enables watching Services                                                | `true`                                     |
| `watcher.resources.pod`                   | Enables watching Pods                                                    | `true`                                     |
| `watcher.resources.job`                   | Enables watching Jobs                                                    | `true`                                     |
| `watcher.resources.node`                  | Enables watching Nodes                                                   | `true`                                     |
| `watcher.resources.clusterRole`           | Enables watching ClusterRoles                                            | `true`                                     |
| `watcher.resources.serviceAccount`        | Enables watching ServiceAccounts                                         | `true`                                     |
| `watcher.resources.persistentVolume`      | Enables watching PersistentVolumes                                       | `true`                                     |
| `watcher.resources.persistentVolumeClaim` | Enables watching PersistentVolumeClaims                                  | `true`                                     |
| `watcher.resources.namespace`             | Enables watching Namespaces                                              | `true`                                     |
| `watcher.resources.secret`                | Enables watching Secrets                                                 | `false`                                    |
| `watcher.resources.configMap`             | Enables watching ConfigMaps                                              | `true`                                     |
| `watcher.resources.ingress`               | Enables watching Ingresses                                               | `true`                                     |
| `watcher.servers.healthCheck.port`        | Port of the health check server                                          | `8090`                                     |
| `resources.requests.cpu`                  | CPU resource requests                                                    | `100m`                                     |
| `resources.limits.cpu`                    | CPU resource limits                                                      | `500m`                                     |
| `resources.requests.memory`               | Memory resource requests                                                 | `128Mi`                                    |
| `resources.limits.memory`                 | Memory resource limits                                                   | `1024Mi`                                   |
| `image.repository`                        | Image registry/name                                                      | `docker.io/komodorio/k8s-watcher`          |
| `image.tag`                               | Image tag                                                                | `0.1.10`                                   |
| `image.pullPolicy`                        | Image pull policy                                                        | `Always`                                   |
| `image.arm`                               | arm64v8 image architecture                                               | `false`                                   |
| `serviceAccount.create`                   | Creates a service account                                                | `true`                                     |
| `serviceAccount.name`                     | Optional name for the service account                                    | `{RELEASE_FULLNAME}`                       |
| `proxy.enabled`                           | Configure proxy for watcher                                              | `true`                                     |
| `proxy.http`                              | Configure Proxy setting (HTTP_PROXY)                                     | ``                                         |
| `proxy.https`                             | Configure Proxy setting (HTTPS_PROXY)                                    | ``                                         |
| `proxy.no_proxy`                          | Configure Proxy setting (NO_PROXY)                                       | ``                                         |





The above parameters map to a yaml configuration file used by the watcher.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
helm upgrade --install k8s-watcher komodorio/k8s-watcher --set apiKey="YOUR_API_KEY_HERE"
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
```

> **Tip**: You can use the default [values.yaml](values.yaml)

## Advanced Usage

| Parameter                              | Description                                                              | Default                                    | Required |
|----------------------------------------|--------------------------------------------------------------------------|--------------------------------------------|----------|
| `kialiApiKey`                          | Komodor Kiali API Key (required if using kiali)                          | ``                                         | required if `watcher.sources.kiali.enabled` is true         |
| `watcher.sources.kiali.enabled`        | Enables Kiali data collection                                            |`false`                                     |         |
| `watcher.sources.kiali.url`            | Kiali URL                                                                | ``                                         | required if `watcher.sources.kiali.enabled` is true        |
| `watcher.sources.kiali.username`       | Kiali Username                                                           | ``                                         | false  |
| `watcher.sources.kiali.password`       | Kiali Password                                                           | ``                                         | false| |
