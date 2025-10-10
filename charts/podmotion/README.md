# Podmotion Helm Chart

This Helm chart deploys [Podmotion](https://github.com/komodorio/podmotion), a live container migration solution for Kubernetes.

## Description

Podmotion enables live migration of containers between Kubernetes nodes with minimal downtime. It uses CRIU (Checkpoint/Restore In Userspace) to checkpoint running containers and restore them on different nodes.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.2.0+
- Nodes must support CRIU and have the required kernel features
- Container runtime must be containerd 1.6+

## Requirements and Limitations

### System Requirements

Podmotion uses [CRIU](https://criu.org/) (Checkpoint/Restore In Userspace) for checkpointing and restoring containers. The following requirements must be met:

#### Kernel Requirements

- **Linux Kernel**: Modern Linux kernel with CRIU support (kernel 3.11+ recommended, though 5.x+ is preferred)
- **userfaultfd**: For live migration support, the kernel must have `CONFIG_USERFAULTFD` enabled
- **CRIU Features**: The following kernel config options are required:
  - `CONFIG_CHECKPOINT_RESTORE`
  - `CONFIG_NAMESPACES`
  - `CONFIG_UTS_NS`, `CONFIG_IPC_NS`, `CONFIG_PID_NS`, `CONFIG_NET_NS`
  - `CONFIG_FHANDLE`
  - `CONFIG_EVENTFD`
  - `CONFIG_EPOLL`
  - `CONFIG_UNIX_DIAG`
  - `CONFIG_INET_DIAG`
  - `CONFIG_PACKET_DIAG`
  - `CONFIG_NETLINK_DIAG`

#### Container Runtime

- **Containerd**: Version 1.6+ is required
- **RuntimeClass**: Pods must use `runtimeClassName: podmotion`
- **Network**: Host network mode is used by default for the daemonset

#### Privileges

- The installer runs as a privileged init container
- The manager requires specific capabilities: `SYS_PTRACE`, `SYS_ADMIN`, `NET_ADMIN`, `SYS_RESOURCE`
- eBPF programs are used for packet redirection and TCP activity tracking

### Supported Environments

Podmotion has been tested and is compatible with the following Kubernetes distributions:

- **Standard Kubernetes**: Generic Kubernetes clusters with containerd
- **Azure Kubernetes Service (AKS)**: Supported
- **Google Kubernetes Engine (GKE)**: Special configuration required -- Contact us!
- **kind**: Supported with specific configuration - Ideal for local testing and development
- **k3s**: Supported with specific configuration (note: initial installation requires k3s service restart)
- **rke2**: Supported with specific configuration (note: initial installation requires rke2 service restart)

#### Supported Architectures

CRIU and Podmotion support the following architectures:

- **x86_64** (amd64) - Supported (Linux)
- **arm64** (aarch64) - Supported (Linux, some workloads in VMs on macOS may be flaky)

### Supported Workloads

While Podmotion should work with any type of workload supported by Kubernetes - we tested and officially support the following:
* Deployment

Support will be soon added for:
* StatefulSet
* Job
* CronJob

#### Recommended Use Cases

- **Low-traffic web applications**: Sites with intermittent traffic that can tolerate brief restoration times
- **Development/Staging environments**: Non-production workloads where minimal resource usage is prioritized
- **API services**: RESTful APIs with bursty traffic patterns
- **Stateful applications**: Applications that maintain in-memory state that needs to be preserved between restarts

#### Compatible Application Types

Most standard applications work with Podmotion, including:

- Web servers (nginx, Apache)
- Application runtimes (Node.js, Python, Ruby, Go applications)
- Databases running in containers (with appropriate checkpointing intervals)
- Microservices
- Containerized applications without special kernel dependencies

#### Probe Support

- **HTTP Probes**: Fully supported while scaled down (probes don't wake container)
- **TCP Probes**: Fully supported while scaled down (probes don't wake container)
- **GRPC Probes**: Will wake the container on each probe
- **Exec Probes**: Will wake the container on each probe

### Limitations

#### Known Limitations

- **Live Migration**: Only one container per pod is supported for live migration (`komodor.com/podmotion-live-migrate`)
- **RuntimeClass Required**: Pods must explicitly set `runtimeClassName: podmotion`
- **Containerd Only**: Docker and other container runtimes are not supported
- **Restoration Time**: Depending on memory size, restoration can take up to hundreds of milliseconds or more
- **First Install Impact**: Installation restarts the containerd service on each targeted node (k3s/rke2 require full service restart)
- **eBPF Requirements**: The host must support eBPF programs for packet redirection

#### Platform-Specific Issues

- **macOS VMs**: Some arm64 workloads running in Linux VMs on macOS can be flaky
- **k3s/rke2**: Initial installation causes workload restarts on targeted nodes due to service restart requirements

#### Unsupported Scenarios

- **Kernel Modules**: Applications that load custom kernel modules
- **Direct Hardware Access**: Applications requiring direct hardware access beyond standard containerization (i.e. GPUs)
- **Real-time Applications**: Applications with strict real-time requirements that cannot tolerate checkpoint/restore overhead
- **Very Large Memory Footprints**: While technically supported, very large applications (multiple GB) may have longer checkpoint/restore times that could time out

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

### 2. Ensure correct Runtime is used

Make sure your workloads use the `podmotion` runtime class by setting `runtimeClassName: podmotion` in the pod spec.

### 3. Trigger Migrations

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

### 4. Monitor Migrations

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
