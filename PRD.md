# PRD: ClusterRole Separation for komodor-agent Helm Chart

## Problem

The current `komodor-agent` Helm chart uses a monolithic `clusterrole.yaml` file that grants extensive Kubernetes RBAC permissions to a single ServiceAccount. This ServiceAccount is shared across all workloads (Deployment, DaemonSet, Metrics Deployment), meaning every container inherits ALL permissions regardless of actual need.

**Current Issues:**
- **Over-permissioning**: The `node-enricher` container only needs `nodes (get)` but inherits 500+ lines of permissions
- **Security risk**: Least-privilege principle is violated - containers have access to resources they never use
- **Audit complexity**: Difficult to understand which container requires which permission
- **Blast radius**: A compromised container has access to all permissions, not just what it needs

**Current State:**
- 1 monolithic `clusterrole.yaml` (~540 lines) serving k8s-watcher + supervisor
- 1 `clusterrole-daemon-metrics.yaml` (~47 lines) for metrics containers (incomplete)
- 10 containers across 3 workloads, but only 4 actually need K8s API access

## Goals & Success Metrics

### Primary Goal
Implement least-privilege RBAC by separating the monolithic ClusterRole into container-specific ClusterRole files, where each container receives exactly the permissions it needs.

### Secondary Goal
Provide a "legacy mode" option that preserves the current behavior (all containers get all permissions) for users who may have undocumented permission dependencies or prefer the existing behavior.

### Success Metrics
- **Permission accuracy**: Each ClusterRole contains only permissions used by its target container
- **No functionality regression**: All features work identically after separation
- **Equivalent total permissions**: Sum of all new ClusterRoles equals the original monolithic ClusterRole
- **Clear ownership**: Each ClusterRole file clearly maps to a specific container/function
- **Audit trail**: Git history shows which permissions belong to which container
- **Test coverage**: Comprehensive tests validate permission equivalence before/after changes

## Requirements

### Functional Requirements

#### FR-1: Break `clusterrole.yaml` into Two Files
Split the existing monolithic ClusterRole into:

1. **`clusterrole-k8s-watcher.yaml`** - Read/watch permissions for the k8s-watcher container
   - All `allowedResources.*` conditional permissions
   - Core resource watching (pods, deployments, events, etc.)
   - Logs capability (`pods/log`)
   - Helm read capability (secrets get/list/watch)
   - Argo Rollouts read + patch
   - Komodor CRD full access
   - Events create/update (for enrichment)

2. **`clusterrole-supervisor.yaml`** - Write/action permissions for the supervisor container
   - All `capabilities.actions` permissions (CRUD on workloads)
   - Pod exec/eviction/portforward
   - Node patch (cordon/uncordon)
   - Helm write capability (secrets create/update/delete + wildcard delete)
   - RBAC management (`capabilities.rbac`)
   - Temp token creation (`capabilities.rbacTempTokens`)
   - CR actions (`capabilities.crActions`)
   - KEDA cost optimization (`capabilities.cost.hpa`)

#### FR-2: Refine `clusterrole-daemon-metrics.yaml`
Update the existing file to include all permissions needed by the DaemonSet's `metrics` container:

```yaml
# For kube_consolidated plugin
- apiGroups: [""]
  resources: ["pods", "nodes", "nodes/stats", "nodes/proxy", "configmaps", "namespaces"]
  verbs: ["get", "list"]

# For owner resolution (dynamic client)
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
  verbs: ["get"]
- apiGroups: ["batch"]
  resources: ["jobs", "cronjobs"]
  verbs: ["get"]

# For ingress metrics (kube_inventory)
- apiGroups: ["networking.k8s.io", "extensions"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch"]

# API server metrics
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]

# metrics.k8s.io for resource metrics
- apiGroups: ["metrics.k8s.io"]
  resources: ["nodes", "pods"]
  verbs: ["get", "watch", "list"]
```

#### FR-3: Create `clusterrole-metrics-deployment.yaml`
New ClusterRole for the Metrics Deployment's `metrics` container:

```yaml
# Everything from daemon-metrics PLUS:

# For HPA metrics (kube_generic plugin)
- apiGroups: ["autoscaling"]
  resources: ["horizontalpodautoscalers"]
  verbs: ["get", "list"]

# For binpacking state (informer cache)
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]  # watch required for informer

# For external_dns metrics
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

#### FR-4: Create `clusterrole-node-enricher.yaml`
Minimal ClusterRole for the `node-enricher` container:

```yaml
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get"]
```

#### FR-5: Update ClusterRoleBindings
Create ClusterRoleBindings to bind each ClusterRole to the ServiceAccount:
- Architecture: Multiple ClusterRoles → Multiple ClusterRoleBindings → Single ServiceAccount
- Each ClusterRoleBinding binds one ClusterRole to the shared ServiceAccount

#### FR-6: Maintain Helm Conditionals
All existing Helm conditionals (`capabilities.*`, `allowedResources.*`) must be preserved in the appropriate ClusterRole files to maintain feature toggle functionality.

#### FR-7: Legacy Mode Option
Provide a Helm value toggle for users who want to preserve the current "all permissions to all containers" behavior:

```yaml
# values.yaml
rbac:
  # When true, use least-privilege per-container ClusterRoles
  # When false, use legacy monolithic ClusterRole (all permissions to all containers)
  leastPrivilege: true  # default: true (new behavior)
```

This ensures:
- Users with undocumented permission dependencies can fall back to legacy mode
- Gradual migration path for existing deployments
- Safety net for edge cases where containers need permissions not identified in source code analysis

### Non-Functional Requirements

#### Security
- **Least privilege**: Each container must have exactly the permissions it needs, no more
- **No privilege escalation**: Separation must not accidentally grant additional permissions
- **Audit compliance**: Clear mapping from permission to container for security audits

#### Backward Compatibility
- **Feature parity**: All existing features must work without modification
- **Upgrade path**: Users upgrading from previous versions must not experience permission errors
- **Legacy mode**: Option to use original monolithic ClusterRole behavior
- **Deprecation strategy**: If changing ServiceAccount structure, provide migration path

#### Maintainability
- **Clear ownership**: Each file should have a comment header explaining which container(s) it serves
- **DRY principle**: Consider using Helm helpers for common permission blocks
- **Documentation**: Update README with new RBAC structure

#### Performance
- **No impact**: RBAC changes should not affect runtime performance
- **Startup time**: Additional ClusterRoleBindings should not significantly impact pod startup

## Container to ClusterRole Mapping

### Workloads and Their Containers

| Workload | Container | ClusterRole Required |
|----------|-----------|---------------------|
| Deployment (komodor-agent) | k8s-watcher | `clusterrole-k8s-watcher.yaml` |
| Deployment (komodor-agent) | supervisor | `clusterrole-supervisor.yaml` |
| Deployment (komodor-agent-metrics) | metrics | `clusterrole-metrics-deployment.yaml` |
| Deployment (komodor-agent-metrics) | telegraf-init | None |
| Deployment (komodor-agent-metrics) | telegraf-init-sidecar | None |
| DaemonSet (komodor-agent-daemon) | metrics | `clusterrole-daemon-metrics.yaml` |
| DaemonSet (komodor-agent-daemon) | init-daemon | None |
| DaemonSet (komodor-agent-daemon) | telegraf-init-sidecar | None |
| DaemonSet (komodor-agent-daemon) | node-enricher | `clusterrole-node-enricher.yaml` |
| DaemonSet (komodor-agent-daemon) | otel-collector | None |
| DaemonSet (komodor-agent-daemon) | otel-init | None |
| DaemonSet (komodor-agent-daemon) | otel-init-sidecar | None |

### Containers Requiring No RBAC (7 of 10)
These containers make zero K8s API calls:
- `telegraf-init` / `init-daemon` - Generate config from Komodor backend
- `telegraf-init-sidecar` - Poll Komodor backend for config updates
- `otel-init` - Generate OTel config from Komodor backend
- `otel-init-sidecar` - Poll Komodor backend for config updates
- `otel-collector` - Receives OTLP telemetry on ports 4317/4318
- `ca-init` - Copies CA certificates (file operations only)

## Technical Considerations

### Helm Template Structure
- Each ClusterRole should be in `templates/` directory
- Follow existing naming convention: `clusterrole-<purpose>.yaml`
- Include corresponding ClusterRoleBinding in same file or separate file

### Conditional Logic Preservation
The following Helm value paths must be preserved:
- `createRbac` - Master toggle for all RBAC resources
- `rbac.leastPrivilege` - Toggle between least-privilege and legacy mode
- `capabilities.*` - Feature toggles (actions, helm, rbac, logs, etc.)
- `allowedResources.*` - Resource-specific toggles

### ServiceAccount Strategy
**Confirmed: Single ServiceAccount with Multiple Bindings**
- Multiple ClusterRoles bound to single ServiceAccount via multiple ClusterRoleBindings
- Simpler migration path
- No changes to workload templates
- Each ClusterRole bound to same ServiceAccount

### File Structure After Implementation
```
templates/
├── clusterrole-k8s-watcher.yaml       # NEW - from clusterrole.yaml (least-privilege mode)
├── clusterrole-supervisor.yaml        # NEW - from clusterrole.yaml (least-privilege mode)
├── clusterrole-daemon-metrics.yaml    # EXISTING - refined
├── clusterrole-metrics-deployment.yaml # NEW
├── clusterrole-node-enricher.yaml     # NEW
├── clusterrole-legacy.yaml            # NEW - original monolithic (legacy mode)
├── clusterrolebinding.yaml            # UPDATE - bind all roles to SA
└── clusterrole.yaml                   # DELETE after migration
```

## Testing Requirements

### Test Strategy
Deploy the chart before and after changes, validating that permission behavior is identical across various configurations.

### Test Cases

#### TC-1: Default Configuration
- Deploy chart with default `values.yaml`
- Verify all containers can perform their intended operations
- Compare rendered RBAC resources before/after changes

#### TC-2: Bring-Your-Own-RBAC (`createRbac: false`)
- Deploy chart with `createRbac: false`
- Verify no ClusterRole/ClusterRoleBinding resources are created
- Document required permissions for users managing their own RBAC

#### TC-3: Capability Combinations
Test various `capabilities.*` combinations:
- `capabilities.actions: false` - Verify supervisor ClusterRole excludes action permissions
- `capabilities.helm.enabled: false` - Verify helm-related permissions excluded
- `capabilities.helm.readonly: true` - Verify write permissions excluded
- `capabilities.metrics: false` - Verify metrics ClusterRoles not created
- `capabilities.nodeEnricher: false` - Verify node-enricher ClusterRole not created

#### TC-4: Legacy Mode
- Deploy chart with `rbac.leastPrivilege: false`
- Verify legacy monolithic ClusterRole is used
- Verify behavior matches pre-change deployment

#### TC-5: Permission Equivalence
- Render templates with both modes
- Compare total permissions (union of all ClusterRoles)
- Verify least-privilege mode permissions ⊆ legacy mode permissions

#### TC-6: Edge Cases
- Test with all capabilities enabled
- Test with all capabilities disabled
- Test with mixed capability configurations
- Test upgrade from previous chart version

### Test Automation
- Add Helm unit tests using `helm-unittest`
- Add integration tests that deploy to a test cluster
- Create CI pipeline job for RBAC validation

## Acceptance Criteria

### Core Functionality
- [ ] `clusterrole.yaml` is split into `clusterrole-k8s-watcher.yaml` and `clusterrole-supervisor.yaml`
- [ ] `clusterrole-daemon-metrics.yaml` is updated with all required permissions
- [ ] `clusterrole-metrics-deployment.yaml` is created with deployment-specific permissions
- [ ] `clusterrole-node-enricher.yaml` is created with minimal `nodes (get)` permission
- [ ] All ClusterRoleBindings are created/updated appropriately
- [ ] Legacy mode (`rbac.leastPrivilege: false`) renders original monolithic ClusterRole

### Permission Validation
- [ ] Sum of all new ClusterRole permissions equals original `clusterrole.yaml` + `clusterrole-daemon-metrics.yaml`
- [ ] No container has more permissions than required (in least-privilege mode)
- [ ] All Helm conditionals (`capabilities.*`, `allowedResources.*`) work correctly

### Testing
- [ ] `helm template` renders all ClusterRoles correctly with default values
- [ ] `helm template` with various capability combinations produces correct output
- [ ] Existing unit tests pass
- [ ] New unit tests validate least-privilege vs legacy mode rendering
- [ ] Integration tests confirm all features work (actions, helm, logs, metrics, etc.)
- [ ] Test cases TC-1 through TC-6 pass

### Documentation
- [ ] Each ClusterRole file has header comments explaining its purpose
- [ ] README updated with new RBAC architecture
- [ ] Migration notes for users upgrading from previous versions
- [ ] Documentation for bring-your-own-RBAC users updated with new permission structure

### Backward Compatibility
- [ ] Users with `createRbac: true` get all necessary permissions
- [ ] Users with `createRbac: false` (bring-your-own-RBAC) have clear documentation
- [ ] Legacy mode provides identical behavior to pre-change chart
- [ ] No breaking changes to `values.yaml` schema

## Additional Context

### Source Code References
The permission requirements were determined by tracing actual K8s API calls in source code:

| Container | Source Repository | Key File |
|-----------|-------------------|----------|
| k8s-watcher | komodor-agent | `cmd/watcher/` |
| supervisor | komodor-agent | `cmd/supervisor/` |
| metrics (telegraf) | telegraf-plugins | `plugins/inputs/kube_consolidated/` |
| node-enricher | komodor-agent | `cmd/node_enricher/node_enricher.go` |
| telegraf-init | komodor-agent | `cmd/telegraf_init/telegraf_init.go` |

### Config Sources
Telegraf plugin configurations that define K8s API access:
- DaemonSet: `mono/services/agents-service/pkg/remote_config_telegraf/configs/*/komodor-agent-daemon/`
- Deployment: `mono/services/agents-service/pkg/remote_config_telegraf/configs/*/komodor-agent-metrics/`

### Risk Mitigation
- **Legacy mode**: Provides fallback for undocumented permission dependencies
- **Test thoroughly**: Run full integration test suite before merging
- **Staged rollout**: Consider feature flag for new RBAC structure
- **Rollback plan**: Legacy mode allows instant rollback without chart changes

### Why Legacy Mode is Important
Some containers may have undocumented permission requirements that weren't identified during source code analysis:
- Dynamic plugin loading that wasn't traced
- Future features that may require additional permissions
- Customer-specific configurations or customizations
- Permissions used only in specific edge cases

Legacy mode ensures users always have a working fallback option.

## Out of Scope
- Separate ServiceAccounts per workload (can be future enhancement)
- Network policies or other security controls
- Changes to container images or application code
- Changes to non-RBAC Helm templates
