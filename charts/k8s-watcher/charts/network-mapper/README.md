# Parameters

## Mapper parameters
| Key                            | Description                          | Default                        |
|--------------------------------|--------------------------------------|--------------------------------|
| `mapper.image.repository`      | Mapper image repository.             | `otterize`                     |
| `mapper.image.image`           | Mapper image.                        | `network-mapper`               |
| `mapper.image.tag`             | Mapper image tag.                    | `latest`                       |
| `mapper.pullPolicy`            | Mapper pull policy.                  | `(none)`                       |
| `mapper.resources`             | Resources override.                  | `(none)`                       |
| `mapper.uploadIntervalSeconds` | Interval for uploading data to cloud | `60`                           |

## Sniffer parameters
| Key                        | Description               | Default                  |
|----------------------------|---------------------------|--------------------------|
| `sniffer.image.repository` | Sniffer image repository. | `otterize`               |
| `sniffer.image.image`      | Sniffer image.            | `network-mapper-sniffer` |
| `sniffer.image.tag`        | Sniffer image tag.        | `latest`                 |
| `sniffer.pullPolicy`       | Sniffer pull policy.      | `(none)`                 |
| `sniffer.resources`        | Resources override.       | `(none)`                 |   

## Cloud parameters
| Key                                             | Description                                     | Default  |
|-------------------------------------------------|-------------------------------------------------|----------|
| `global.otterizeCloud.credentials.clientId`     | Client ID for connecting to Otterize Cloud.     | `(none)` |
| `global.otterizeCloud.credentials.clientSecret` | Client secret for connecting to Otterize Cloud. | `(none)` |
| `global.otterizeCloud.apiAddress`               | Overrides Otterize Cloud default API address.   | `(none)` |

## Global parameters
| Key                              | Description                                                                                                                                 | Default |
|----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|---------|
| `global.allowGetAllResources`    | If defined overrides `allowGetAllResources`.                                                                                                |         |

## Common parameters
| Key                    | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Default                        |
|------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------|
| `debug`                | Enable debug logs                                                                                                                                                                                                                                                                                                                                                                                                                                             | `false`                        |
| `allowGetAllResources` | Gives get, list and watch permission to watch on all resources. This is used to resolve service names when pods have owners that are custom resources. When disabled, a limited set of permissions is used that only allows access to built-in Kubernetes resources that deploy Pods and Pods themselves - Deployments, StatefulSets, DaemonSets, ReplicaSets and Services. Resolving may not be able to complete if the owning resource is not one of those. | `true`                         |
