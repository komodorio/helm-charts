# Podmotion Helm Chart

This Helm chart deploys [Podmotion](https://github.com/komodorio/podmotion), a live container migration solution for Kubernetes.

## Description

Podmotion enables live migration of containers between Kubernetes nodes with minimal downtime. It uses CRIU (Checkpoint/Restore In Userspace) to checkpoint running containers and restore them on different nodes.

## Prerequisites

- Kubernetes 1.20+
- Helm 3.2.0+
- Nodes must support CRIU and have the required kernel features
- Container runtime must be containerd

## Installation

### Add Helm Repository

```bash
helm repo add komodorio https://helm-charts.komodor.io
helm repo update
```

### Install Chart

```bash
# Install with default values
helm upgrade --install komodor-podmotion komodorio/podmotion

# Install in a specific namespace
helm upgrade --install komodor-podmotion komodorio/podmotion --create-namespace --namespace komodor-podmotion-system

# Install with custom values
helm upgrade --install komodor-podmotion komodorio/podmotion -f values.yaml
```

## Configuration

The following table lists the configurable parameters of the Podmotion chart and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Global Docker image registry | `""` |
| `global.imagePullSecrets` | Global Docker registry secret names | `[]` |

### Namespace Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.create` | Create the namespace | `true` |
| `namespace.name` | Namespace name (if empty, uses release namespace) | `""` |

### Image Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `images.installer.repository` | Installer image repository | `komodorio/podmotion-installer` |
| `images.installer.tag` | Installer image tag | `latest` |
| `images.installer.pullPolicy` | Installer image pull policy | `IfNotPresent` |
| `images.manager.repository` | Manager image repository | `komodorio/podmotion-manager` |
| `images.manager.tag` | Manager image tag | `latest` |
| `images.manager.pullPolicy` | Manager image pull policy | `IfNotPresent` |

### DaemonSet Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `daemonset.nodeSelector` | Node selector for podmotion nodes | `komodor.com/podmotion-node: "true"` |
| `daemonset.tolerations` | Tolerations for the daemonset | `[{operator: Exists}]` |
| `daemonset.hostNetwork` | Use host network | `true` |
| `daemonset.dnsPolicy` | DNS policy | `ClusterFirstWithHostNet` |

### Manager Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `manager.metrics.enabled` | Enable metrics endpoint | `true` |
| `manager.metrics.port` | Metrics port | `8080` |
| `manager.nodeServer.port` | Node server port | `8090` |

### RBAC Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rbac.create` | Create RBAC resources | `true` |
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.name` | Service account name | `""` |
| `migrationManager.enabled` | Enable migration manager RBAC | `true` |

### Uninstall Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `uninstall.enabled` | Enable uninstall mode to clean up podmotion components | `false` |

### CRD Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `crd.create` | Install Migration CRD | `true` |

## Usage

### 1. Label Nodes

Before using podmotion, label the nodes where you want to enable live migration:

```bash
kubectl label nodes <node-name> komodor.com/podmotion-node=true
```

### 2. Trigger Migrations

There are two ways to trigger migrations:

#### Method 1: Using Annotations (Recommended)

Annotate your workloads (Deployment, StatefulSet, etc.) to enable automatic migration when pods are rescheduled.

##### `komodor.com/podmotion-migrate`

Enables migration of scaled down containers by listing the containers to be migrated. When such an annotated pod is deleted and it's part of a Deployment, the new pod will fetch the checkpoints of these containers and instead of starting it will simply wait for activation again. This minimizes the surge in resources if for example a whole node of scaled down podmotions is drained.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        komodor.com/podmotion-migrate: "nginx,sidecar"
    spec:
      containers:
      - name: nginx
        image: nginx:latest
      - name: sidecar
        image: sidecar:latest
```

##### `komodor.com/podmotion-live-migrate`

Enables live-migration of a running container in the pod. Only one container per pod is supported at this point. When such an annotated pod is deleted and it's part of a Deployment, the new pod will do a lazy-migration of the memory contents.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        komodor.com/podmotion-live-migrate: "nginx"
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

#### Method 2: Manual Migration CRD

Create a Migration custom resource to manually trigger a migration:

```yaml
apiVersion: runtime.podmotion.komodorio.dev/v1
kind: Migration
metadata:
  name: example-migration
  namespace: default
spec:
  sourceNode: node-1
  targetNode: node-2
  sourcePod: my-pod
  podTemplateHash: abc123
  liveMigration: true
  containers:
  - name: my-container
    id: container-id-123
```

### 3. Monitor Migrations

```bash
# List all migrations
kubectl get migrations --all-namespaces

# Get migration details
kubectl describe migration example-migration

# Check podmotion logs
kubectl logs -n komodor-podmotion-system -l app.kubernetes.io/name=komodor-podmotion

## Troubleshooting

### Common Issues

1. **Pods not starting**: Check if nodes have the required label and CRIU support
2. **Permission errors**: Ensure RBAC is properly configured
3. **Container runtime issues**: Verify containerd is properly configured

### Debugging Commands

```bash
# Check daemonset status
kubectl get daemonset -n <namespace>

# View podmotion logs
kubectl logs -n <namespace> -l app.kubernetes.io/name=komodor-podmotion-node -c manager

# Check node labels
kubectl get nodes --show-labels | grep podmotion
```

## Uninstallation

### Method 1: Using Uninstall Mode

To properly clean up podmotion components from nodes before removing the chart:

```bash
# Enable uninstall mode to clean up components
helm upgrade komodor-podmotion komodor/podmotion -n komodor-podmotion-system --set uninstall.enabled=true

# Wait for the cleanup to complete, then uninstall the chart
helm uninstall komodor-podmotion -n komodor-podmotion-system
```

### Method 2: Direct Uninstall

```bash
helm uninstall komodor-podmotion -n komodor-podmotion-system
```

To remove the namespace (if created by the chart):

```bash
kubectl delete namespace <namespace>
```

**Note**: Using Method 1 (uninstall mode) is recommended as it ensures proper cleanup of podmotion components installed on the nodes.

## Contributing

Please see the main [Podmotion repository](https://github.com/komodorio/podmotion) for contribution guidelines.

## License

This chart is licensed under the same license as Podmotion. See the [LICENSE](https://github.com/komodorio/podmotion/blob/main/LICENSE.md) file for details.
