# Komodor.io

## TL;DR;

```bash
helm repo add komodorio https://helm-charts.komodor.io
helm repo update
helm upgrade --install k8s-watcher komodorio/k8s-watcher --set apiKey="YOUR_API_KEY_HERE"
```

## Introduction

This chart bootstraps a Kubernetes Resources/Event Watcher deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.16+ (older versions not tested)
- Helm 3 (older versions not tested)

## Installing the Chart

To install the chart with the release name `k8s-watcher`:

```bash
helm upgrade --install k8s-watcher komodorio/k8s-watcher --set apiKey="YOUR_API_KEY_HERE"
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
1. Make sure to set the apiKey secret value in `./kube-install/k8s-watcher/templates/secret-credentials.yaml`
2. Then just apply everything: `kubectl apply -f ./kube-install`

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter                                 | Description                                                              | Default                                    |
|-------------------------------------------|--------------------------------------------------------------------------|--------------------------------------------|
| `apiKey`                                  | Komodor kubernetes api key (required)                                    | ``                                         |
| `watcher.watchNamespace`                  | Watch a specific namespace, or all namespaces ("", "all")                | `all`                                      |
| `watcher.namespacesBlacklist`             | Blacklist specific namespaces (list)                                     | `[kube-system]`                            |
| `watcher.nameBlacklist`                   | Blacklist specific resource names that contains any of these strings (list) - example: ```watcher.nameBlacklist=["dont-watch"] --> `pod/backend-dont-watch` wont be collected``` | `[]`                                                |
| `watcher.collectHistory`                  | On startup collect existing cluster resources in addition to watching new resources (true / false)                        | `false`                                    |
| `watcher.sinks.webhook.enabled`           | Enables a Webhook output                                                 | `true`                                     |
| `watcher.sinks.webhook.url`               | URL to send webhooks to                                                  | `https://app.komodor.io/k8s-events/event/` |
| `watcher.sinks.webhook.headers`           | Headers to attach to the webhooks                                        | `{}`                                       |
| `watcher.resources.event`                 | Enables watching Event                                                   | `true`                                     |
| `watcher.resources.deployment`            | Enables watching Deployments                                             | `true`                                     |
| `watcher.resources.replicationController` | Enables watching ReplicationControllers                                  | `true`                                     |
| `watcher.resources.replicaSet`            | Enables watching ReplicaSets                                             | `true`                                     |
| `watcher.resources.daemonSet`             | Enables watching DaemonSets                                              | `true`                                     |
| `watcher.resources.service`               | Enables watching Services                                                | `true`                                     |
| `watcher.resources.pod`                   | Enables watching Pods                                                    | `true`                                     |
| `watcher.resources.job`                   | Enables watching Jobs                                                    | `true`                                     |
| `watcher.resources.node`                  | Enables watching Nodes                                                   | `true`                                     |
| `watcher.resources.clusterRole`           | Enables watching ClusterRoles                                            | `true`                                     |
| `watcher.resources.serviceAccount`        | Enables watching ServiceAccounts                                         | `true`                                     |
| `watcher.resources.persistentVolume`      | Enables watching PersistentVolumes                                       | `true`                                     |
| `watcher.resources.persistentVolumeClaim` | Enables watching PersistentVolumeClaims                                  | `true`                                     |
| `watcher.resources.namespace`             | Enables watching Namespaces                                              | `true`                                     |
| `watcher.resources.secret`                | Enables watching Secrets                                                 | `true`                                     |
| `watcher.resources.configMap`             | Enables watching ConfigMaps                                              | `true`                                     |
| `watcher.resources.ingress`               | Enables watching Ingresses                                               | `true`                                     |
| `resources.requests.cpu`                  | CPU resource requests                                                    | `100m`                                     |
| `resources.limits.cpu`                    | CPU resource limits                                                      | `500m`                                     |
| `resources.requests.memory`               | Memory resource requests                                                 | `128Mi`                                    |
| `resources.limits.memory`                 | Memory resource limits                                                   | `1024Mi`                                   |
| `image.repository`                        | Image registry/name                                                      | `docker.io/komodorio/k8s-watcher`          |
| `image.tag`                               | Image tag                                                                | `latest`                                   |
| `image.pullPolicy`                        | Image pull policy                                                        | `Always`                                   |
| `serviceAccount.create`                   | Creates a service account                                                | `true`                                     |
| `serviceAccount.name`                     | Optional name for the service account                                    | `{RELEASE_FULLNAME}`                       |





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

| Parameter                                 | Description                                                              | Default                                    |
|-------------------------------------------|--------------------------------------------------------------------------|--------------------------------------------|
| `kialiApiKey`      | Komodor Kiali API Key (required if using kiali)           | ``                                         
| `watcher.sources.kiali.url`               | Kiali URL                                                                | ``                                         |
| `watcher.sources.kiali.username`          | Kiali Username                                                           | ``                                         |
| `watcher.sources.kiali.password`          | Kiali Password                                                           | ``                                         
