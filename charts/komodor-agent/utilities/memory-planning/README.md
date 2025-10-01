# Komodor Agent Memory Planning Utilities

This directory contains Kubernetes resources to help you analyze memory requirements for the Komodor agent before deployment.

## Overview

The Memory Checker utility runs the same resource loading logic as the Komodor agent to provide accurate memory usage analysis. This helps you:

- **Plan memory limits** before deploying the agent
- **Troubleshoot memory issues** in existing deployments
- **Optimize resource configurations** for large clusters
- **Understand resource consumption** patterns

## Files in this Directory
- `01-namespace.yaml` - Creates the komodor-precheck namespace
- `02-configmap.yaml` - Configuration for the memory checker
- `03-serviceaccount.yaml` - Dedicated ServiceAccount
- `04-clusterrole.yaml` - ClusterRole with required permissions
- `05-clusterrolebinding.yaml` - Binding ServiceAccount to ClusterRole
- `06-job.yaml` - Job definition for running the memory checker


## Quick Start

### Simple Memory Check Before Installing the Agent

```bash
# Apply all components in order
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-serviceaccount.yaml
kubectl apply -f 04-clusterrole.yaml
kubectl apply -f 05-clusterrolebinding.yaml
kubectl apply -f 06-job.yaml

# Or apply all at once
kubectl apply -f .

# Watch the job progress
kubectl logs -f job/komodor-memory-checker -n komodor-precheck

# View results
kubectl logs job/komodor-memory-checker -n komodor-precheck
```

## Configuration Options

### Configuration File Format

The memory checker uses the **exact same YAML configuration format** as the main Komodor agent, ensuring identical behavior. The configuration is mounted at `/etc/komodor/komodor-k8s-watcher.yaml` just like in the main agent.

Edit the `02-configmap.yaml` file to customize:

```yaml
# In the komodor-k8s-watcher.yaml section
data:
  komodor-k8s-watcher.yaml: |
    # Analyze only specific namespace
    watchNamespace: "production"
    # Resource configuration - set to false to disable specific resources
    resources:
      secret: false      # Disable for security/performance
      configMap: false   # Disable if not needed
      rollout: true      # Argo Rollouts
```

## Understanding the Output

### Sample Output

```
=== KUBERNETES RESOURCES MEMORY USAGE REPORT ===

=== SUMMARY ===
Total Memory Before: 45 MB
Total Memory After: 156 MB
Total Memory Used: 111 MB
Total Load Time: 2.345s
Total Objects Loaded: 1,234
Successful Resources: 23
Failed Resources: 2

=== RESOURCES BY OBJECT SIZE ===
Group      Version  Resource     Namespace  Objects  Size (MB)  Time    Status
core       v1       pods         all        456      67         234ms   OK
apps       v1       deployments  all        123      23         145ms   OK
...

=== MEMORY RECOMMENDATIONS ===
Recommended Memory Request: 128 MB
Minimum Memory Limit: 256 MB
Recommended Memory Limit: 512 MB
```

### Key Metrics

- **Total Memory Used**: Actual memory consumed by loading all resources
- **Object Size**: Memory footprint of each resource type
- **Load Time**: Time to fetch each resource type
- **Object Count**: Number of objects per resource type

### Memory Recommendations

- **Memory Request**: Conservative estimate for Kubernetes resource requests
- **Minimum Limit**: The expected maximum usage under normal use
- **Recommended Limit**: Production-ready buffer which will prevent OOMKills and unnecessary restarts

## Using Results for Helm Chart Configuration

Apply the recommendations to your Helm values:

```yaml
# values.yaml
components:
  komodorAgent:
    watcher:
      resources:
        requests:
          memory: "4Gi"    # Use "Recommended Memory Request"
        limits:
          memory: "8Gi"    # Use "Recommended Memory Limit"
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```
   ERROR: Failed to load resource: pods.v1. Error: pods is forbidden
   ```
   **Solution**: Ensure the ServiceAccount/ClusterRole has proper RBAC permissions set

2. **Job Fails to Start**
   ```
   Error: ImagePullBackOff
   ```
   **Solution**: Check image name and pull policy, or update image registry if using a self-hosted mirror

### Limiting Analysis Scope

You can limit the analysis by editing `02-configmap.yaml`:

```yaml
# In configmap.yaml
data:
  komodor-k8s-watcher.yaml: |
    watchNamespace: "custom-ns"  # Single namespace
    resources:
      ingress: false
```

### Viewing Logs in Real-time

```bash
# Follow logs as the job runs
kubectl logs -f job/komodor-memory-checker -n komodor-precheck

# Get logs after completion
kubectl logs job/komodor-memory-checker -n komodor-precheck

# If job fails, check events
kubectl describe job komodor-memory-checker -n komodor-precheck
```

## Cleanup

Remove the resources after analysis:

```bash
kubectl delete -f 06-job.yaml
kubectl delete -f 05-clusterrolebinding.yaml
kubectl delete -f 04-clusterrole.yaml
kubectl delete -f 03-serviceaccount.yaml
kubectl delete -f 02-configmap.yaml
kubectl delete -f 01-namespace.yaml
```

Or delete all at once:
```bash
kubectl delete -f .
```

## Advanced Usage
### Custom Resource Analysis

Add custom resource permissions to `04-clusterrole.yaml`:

```yaml
- apiGroups: ["custom.example.com"]
  resources: ["myresources"]
  verbs: ["get", "list"]
```