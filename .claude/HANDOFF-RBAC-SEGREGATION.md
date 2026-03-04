# Handoff: RBAC Segregation for Komodor Agent Daemon/Metrics Workloads

**Date:** 2026-03-03
**Branch:** gt/cr-modific
**PRD:** [.claude/PRD.md](.claude/PRD.md)

## Summary

Implementing RBAC segregation to give daemon and metrics workloads their own dedicated ServiceAccount, ClusterRole, and ClusterRoleBinding instead of sharing the main agent's RBAC resources.

## Current Status: Phase 5 - Documentation & Release (IN PROGRESS)

### Completed

#### Phase 1: Analysis & Documentation
- [x] Analyzed current ClusterRole permissions in `clusterrole.yaml`
- [x] Mapped workloads sharing the same ServiceAccount
- [x] Identified that daemon/metrics workloads need `capabilities.metrics` permissions

#### Phase 2: Implementation
- [x] **Helper template** - Added `komodorAgent.daemonMetrics.serviceAccountName` to `_service_account.tpl`
- [x] **ServiceAccount** - Created `serviceaccount-daemon-metrics.yaml`
- [x] **ClusterRole** - Created `clusterrole-daemon-metrics.yaml` with metrics permissions
- [x] **ClusterRoleBinding** - Created `clusterrolebinding-daemon-metrics.yaml`
- [x] **values.yaml** - Added `serviceAccount.createDaemonMetrics` (default: true) and `serviceAccount.daemonMetricsName`
- [x] **Workload updates** - Updated 4 templates to use new ServiceAccount:
  - `daemonset.yaml`
  - `daemonset_windows.yaml`
  - `daemonset_gpu.yaml`
  - `deployment_metrics.yaml`

#### Phase 3: Validation (COMPLETE - 2026-03-03)
- [x] `helm lint` passes
- [x] `helm template` produces valid manifests
- [x] Verify new RBAC resources are created when `createDaemonMetrics=true`
- [x] Verify fallback to main ServiceAccount when `createDaemonMetrics=false`

#### Phase 4: Windows Support
- [x] `daemonset_windows.yaml` updated (done in Phase 2)
- [x] Verified Windows DaemonSet uses new ServiceAccount in `helm template` output

### In Progress

#### Phase 5: Documentation & Release
- [x] Update README.md with new RBAC architecture
- [x] Migration notes: Not needed (backward compatible - defaults to `createDaemonMetrics=true`)
- [x] CHANGELOG: No CHANGELOG file in this repo (changes tracked via git commits)

## Files Created/Modified

### New Files
| File | Purpose |
|------|---------|
| `templates/serviceaccount-daemon-metrics.yaml` | Dedicated ServiceAccount for daemon/metrics |
| `templates/clusterrole-daemon-metrics.yaml` | ClusterRole with metrics-specific permissions |
| `templates/clusterrolebinding-daemon-metrics.yaml` | Binds ClusterRole to ServiceAccount |

### Modified Files
| File | Changes |
|------|---------|
| `templates/_service_account.tpl` | Added `komodorAgent.daemonMetrics.serviceAccountName` helper |
| `templates/daemonset.yaml` | Changed `serviceAccountName` to use new helper |
| `templates/daemonset_windows.yaml` | Changed `serviceAccountName` to use new helper |
| `templates/daemonset_gpu.yaml` | Changed `serviceAccountName` to use new helper |
| `templates/deployment_metrics.yaml` | Changed `serviceAccountName` to use new helper |
| `values.yaml` | Added `serviceAccount.createDaemonMetrics` and `serviceAccount.daemonMetricsName` |

## New Helm Values

```yaml
serviceAccount:
  createDaemonMetrics: true  # Creates dedicated SA for daemon/metrics (default: true)
  daemonMetricsName:         # Optional custom name (default: <fullname>-daemon-metrics)
```

## ClusterRole Permissions (daemon-metrics)

The new ClusterRole grants these permissions (from `capabilities.metrics`):

```yaml
rules:
  # Core resources for metrics collection
  - apiGroups: [""]
    resources: [configmaps, namespaces, pods, nodes, nodes/stats, nodes/proxy]
    verbs: [get, list]

  # Ingress for metrics
  - apiGroups: [extensions, networking.k8s.io]
    resources: [ingresses]
    verbs: [get, watch, list]

  # Kubernetes metrics API
  - apiGroups: [metrics.k8s.io]
    resources: [nodes, pods]
    verbs: [get, watch, list]

  # API server metrics endpoint
  - nonResourceURLs: ["/metrics"]
    verbs: [get]
```

## Validation Commands

Run from `/Users/giladtayeb/Git/helm-charts`:

```bash
# 1. Lint the chart
helm lint charts/komodor-agent --set apiKey=test-api-key --set clusterName=test-cluster

# 2. Template and check new resources are created
helm template test-release charts/komodor-agent \
  --set apiKey=test-api-key \
  --set clusterName=test-cluster \
  2>&1 | grep -A 50 "daemon-metrics"

# 3. Verify resource kinds and serviceAccountNames
helm template test-release charts/komodor-agent \
  --set apiKey=test-api-key \
  --set clusterName=test-cluster \
  2>&1 | grep -E "(kind:|name:.*daemon-metrics|serviceAccountName:)"

# 4. Test fallback (disabled segregation)
helm template test-release charts/komodor-agent \
  --set apiKey=test-api-key \
  --set clusterName=test-cluster \
  --set serviceAccount.createDaemonMetrics=false \
  2>&1 | grep -E "(kind:|serviceAccountName:)"
```

## Known Issues

1. **YAML syntax error fixed** - The `clusterrole-daemon-metrics.yaml` had Helm comment blocks (`{{- /* ... */ -}}`) that caused YAML parsing issues. Fixed by converting to standard YAML comments (`#`).

## Architecture Decision

**Shared RBAC for daemon + metrics**: Both workloads use the same new ServiceAccount/ClusterRole because:
- They have similar node-level and metrics permission requirements
- Simpler than maintaining two separate RBAC sets
- Follows the admission-controller pattern already in the chart

## Next Steps

1. Run validation commands above to confirm `helm lint` and `helm template` work
2. If validation passes, test in a real cluster
3. Update README.md with new configuration options
4. Create PR for review
