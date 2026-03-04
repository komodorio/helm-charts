# PRD: RBAC Segregation for Komodor Agent Daemon and Metrics Workloads

## Problem

The komodor-agent Helm chart currently uses a **single shared ServiceAccount, ClusterRole, and ClusterRoleBinding** for all workloads:
- `komodor-agent` (main deployment/watcher)
- `komodor-agent-daemon` (DaemonSet - Linux)
- `komodor-agent-daemon-windows` (DaemonSet - Windows)
- `komodor-agent-metrics` (Deployment)
- `komodor-agent-daemon-gpu` (DaemonSet)

This monolithic RBAC approach violates the **principle of least privilege** - each workload receives all permissions even if it only needs a subset. The daemon and metrics workloads have specific, narrower permission requirements that don't need the full capabilities of the watcher component.

### Current State Analysis

**Workloads sharing the same ServiceAccount (`komodorAgent.serviceAccountName`):**
| Workload | Type | Template File |
|----------|------|---------------|
| komodor-agent | Deployment | `deployment.yaml` |
| komodor-agent-daemon | DaemonSet | `daemonset.yaml` |
| komodor-agent-daemon-windows | DaemonSet | `daemonset_windows.yaml` |
| komodor-agent-daemon-gpu | DaemonSet | `daemonset_gpu.yaml` |
| komodor-agent-metrics | Deployment | `deployment_metrics.yaml` |

**Separate RBAC already exists for:**
- Admission Controller (has its own ServiceAccount, ClusterRole, ClusterRoleBinding in `admission-controller/`)

## Goals & Success Metrics

### Primary Goals
1. **Identify permission requirements** - Determine exactly what RBAC permissions `komodor-agent-daemon` and `komodor-agent-metrics` workloads need
2. **Create dedicated RBAC resources** - New ServiceAccount, ClusterRole, and ClusterRoleBinding specifically for daemon and metrics workloads
3. **Maintain existing functionality** - No regression in workload capabilities
4. **Document the RBAC architecture** - Clear mapping of which workloads use which RBAC resources

### Important Constraints
- **No permission reduction** - This is NOT a "minimum permissions" exercise. All permissions currently granted to daemon/metrics workloads must be preserved in the new dedicated RBAC. The goal is **segregation**, not **restriction**.
- **Same RBAC for Linux and Windows** - Kubernetes RBAC operates at the API server level, not the node OS level. The same ServiceAccount/ClusterRole works for both Linux and Windows DaemonSets.

### Success Metrics
- [ ] Current ClusterRole consumers are documented (which workloads need which permissions)
- [ ] New RBAC resources are created for daemon + metrics workloads
- [ ] Daemon and metrics workloads function correctly with the new dedicated RBAC (same permissions as before)
- [ ] Existing workloads (watcher, etc.) continue using the original RBAC without issues
- [ ] Helm chart validates successfully (`helm template`, `helm lint`)
- [ ] Both Linux and Windows DaemonSets use the same new ServiceAccount

## Requirements

### Functional Requirements

#### FR-1: RBAC Audit and Documentation
1. Analyze the current ClusterRole permissions in `clusterrole.yaml`
2. Map which capabilities/permissions are used by which workloads:
   - Watcher (main deployment)
   - Node Enricher (daemon)
   - Metrics collector (metrics deployment)
3. Document findings in a clear matrix format

#### FR-2: New ServiceAccount for Daemon/Metrics
1. Create a new ServiceAccount template (e.g., `serviceaccount-daemon-metrics.yaml`)
2. Use naming convention: `{{ include "komodorAgent.daemonMetrics.serviceAccountName" . }}`
3. Support the same `imagePullSecret` configuration as the main ServiceAccount
4. Conditionally create based on a helm value (e.g., `serviceAccount.createDaemonMetrics`)

#### FR-3: New ClusterRole for Daemon/Metrics
1. Create a new ClusterRole template (e.g., `clusterrole-daemon-metrics.yaml`)
2. Include ONLY the permissions required by:
   - Node-level metrics collection
   - Pod metrics collection
   - Node stats and proxy access (for daemon)
   - Metrics API access
3. Permissions should be the minimal set required for daemon and metrics functionality

#### FR-4: New ClusterRoleBinding for Daemon/Metrics
1. Create a new ClusterRoleBinding template (e.g., `clusterrolebinding-daemon-metrics.yaml`)
2. Bind the new ClusterRole to the new ServiceAccount
3. Conditionally create based on the same helm value as the ServiceAccount

#### FR-5: Update Workload Templates
1. Update `daemonset.yaml` to use the new ServiceAccount
2. Update `daemonset_windows.yaml` to use the new ServiceAccount (if in scope)
3. Update `daemonset_gpu.yaml` to use the new ServiceAccount
4. Update `deployment_metrics.yaml` to use the new ServiceAccount

#### FR-6: Helm Values Configuration
1. Add new helm values to control the new RBAC resources:
   ```yaml
   serviceAccount:
     createDaemonMetrics: true  # or separate flag
   ```
2. Ensure backwards compatibility via sensible defaults

### Non-Functional Requirements

#### NFR-1: Backwards Compatibility
- Existing installations should continue working without manual intervention
- Default behavior should maintain current functionality
- Migration path should be documented if breaking changes are unavoidable

#### NFR-2: Maintainability
- Follow existing Helm chart patterns and naming conventions
- Use helper templates consistent with `_helpers.tpl` and `_service_account.tpl`
- Minimize code duplication

#### NFR-3: Security
- Apply principle of least privilege
- No permission escalation compared to current state
- Permissions should be auditable and well-documented

#### NFR-4: Testability
- New RBAC resources should be testable via `helm template`
- Should pass existing CI/CD validation checks

## User Flow

### Deployment Flow (User Perspective)
1. User installs/upgrades the komodor-agent Helm chart
2. Helm creates the new dedicated RBAC resources for daemon/metrics (if enabled)
3. DaemonSet and Metrics Deployment use the new ServiceAccount
4. Watcher and other components continue using the original ServiceAccount
5. All workloads function correctly with their respective permissions

### Configuration Flow
1. User can optionally disable the new RBAC segregation via helm values
2. When disabled, all workloads fall back to the original shared ServiceAccount
3. Documentation guides users on when to use segregated vs shared RBAC

## Technical Considerations

### Preferred Approach
- **Shared RBAC for daemon + metrics** - Both workloads likely need similar node-level and metrics permissions, so a single new ServiceAccount/ClusterRole serving both is cleaner than two separate sets

### Files to Create/Modify
| File | Action | Purpose |
|------|--------|---------|
| `templates/serviceaccount-daemon-metrics.yaml` | Create | New ServiceAccount |
| `templates/clusterrole-daemon-metrics.yaml` | Create | New ClusterRole with minimal permissions |
| `templates/clusterrolebinding-daemon-metrics.yaml` | Create | Bind new ClusterRole to new ServiceAccount |
| `templates/_service_account.tpl` | Modify | Add helper for new ServiceAccount name |
| `templates/daemonset.yaml` | Modify | Reference new ServiceAccount |
| `templates/daemonset_windows.yaml` | Modify | Reference new ServiceAccount (Phase 2) |
| `templates/daemonset_gpu.yaml` | Modify | Reference new ServiceAccount |
| `templates/deployment_metrics.yaml` | Modify | Reference new ServiceAccount |
| `values.yaml` | Modify | Add new configuration options |
| `README.md` | Modify | Document new RBAC structure |

### Permission Analysis (To Be Completed During Implementation)

The new ClusterRole for daemon/metrics workloads will **replicate the relevant permissions from the existing ClusterRole** - not minimize them. The investigation phase will identify which permission blocks from `clusterrole.yaml` are relevant to daemon and metrics workloads (based on which `capabilities.*` and `allowedResources.*` values they use).

Key capabilities to investigate:
- `capabilities.metrics` - likely used by metrics deployment
- Any node-level access patterns used by daemon workloads

### Constraints
- Kubernetes 1.19+ (RBAC v1 API)
- Helm 3.x
- Must work with existing Komodor backend expectations
- Windows DaemonSet may have different requirements (Phase 2)

### Risks and Mitigations
| Risk | Mitigation |
|------|------------|
| Breaking existing installations | Feature flag with default to current behavior |
| Missing permissions | Thorough testing and validation before release |
| Windows DaemonSet complexity | Phase the work - Linux first, Windows as follow-up |

## Acceptance Criteria

### Phase 1: Analysis & Documentation
- [ ] Document which workloads use the current ClusterRole
- [ ] Create permission matrix mapping capabilities to workloads
- [ ] Identify minimum permissions for daemon workload
- [ ] Identify minimum permissions for metrics workload
- [ ] Determine if permissions overlap justifies shared RBAC

### Phase 2: Implementation (Linux)
- [ ] New ServiceAccount template created and functional
- [ ] New ClusterRole template created with minimal permissions
- [ ] New ClusterRoleBinding template created
- [ ] `daemonset.yaml` updated to use new ServiceAccount
- [ ] `daemonset_gpu.yaml` updated to use new ServiceAccount
- [ ] `deployment_metrics.yaml` updated to use new ServiceAccount
- [ ] Helper templates added to `_service_account.tpl`
- [ ] Values schema updated with new configuration options

### Phase 3: Validation
- [ ] `helm template` produces valid Kubernetes manifests
- [ ] `helm lint` passes without errors
- [ ] Existing tests pass
- [ ] Manual validation in test cluster confirms workloads function correctly
- [ ] No permission errors in workload logs

### Phase 4: Windows Support
- [ ] `daemonset_windows.yaml` updated to use new ServiceAccount (same as Linux)
- [ ] Validated on Windows node pool

> **Note:** Kubernetes RBAC is OS-agnostic. The same ServiceAccount and ClusterRole work for both Linux and Windows nodes since permissions are enforced at the API server level, not the node level.

### Phase 5: Documentation & Release
- [ ] README.md updated with new RBAC architecture
- [ ] Migration notes added if needed
- [ ] CHANGELOG updated

## Additional Context

### Existing RBAC Patterns in This Chart
The admission-controller already has its own dedicated RBAC in `templates/admission-controller/`:
- `serviceaccount.yaml` - Dedicated ServiceAccount
- `rbac.yaml` - Combined ClusterRole and ClusterRoleBinding

This pattern can be followed for the daemon/metrics RBAC segregation.

### Related Work
- Previous session identified duplicate permission blocks in `clusterrole.yaml` (capabilities.actions appears twice with different permissions)
- ClusterRoleBinding extraction to separate file was previously discussed

### Key Helm Values Affecting Current ClusterRole
- `capabilities.metrics` - Adds nodes/stats, nodes/proxy, /metrics access
- `capabilities.actions` - Adds write permissions (patch, delete, create)
- `allowedResources.*` - Controls read permissions for various resource types
- `capabilities.helm.enabled` - Adds secrets access
- `capabilities.rbac` - Adds RBAC management permissions

### Stakeholders
- **Komodor customers** - All paid customers benefit from improved security posture
- **Komodor engineering** - Easier to audit and maintain RBAC permissions
- **Security teams** - Clearer permission boundaries for compliance
