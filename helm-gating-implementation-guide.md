# Helm Chart: Resource Gating Implementation Guide

## Problem Statement

The chart has two value blocks that control cluster role / resource creation:

- **`allowedResources`** — acts as a global gate (allow-list). If a resource is `false` here, it must never be created regardless of any other setting.
- **`capabilities`** — acts as a per-deployment toggle. Only takes effect when the corresponding `allowedResources` entry is `true`.

**Truth table:**

| allowedResources.X | capabilities.X | Resource Created? |
|---------------------|----------------|-------------------|
| true                | true           | YES               |
| true                | false          | no                |
| false               | true           | no                |
| false               | false          | no                |

Currently, templates only check `capabilities`, bypassing the gate entirely.

---

## Implementation Steps

### 1. Create a Named Template Helper

In `_helpers.tpl`, add the following named template. It accepts a resource key string, looks it up in both blocks, and returns `"true"` only when both are `true`.

```yaml
{{/*
Checks whether a resource is both allowed (global gate) and enabled (capability toggle).
Usage: {{- if eq (include "chart.isAllowed" (dict "root" . "key" "rbac")) "true" }}
Params:
  root - the top-level chart context (usually ".")
  key  - the string key to look up in both allowedResources and capabilities
*/}}
{{- define "chart.isAllowed" -}}
{{- $allowed := false -}}
{{- if hasKey .root.Values.allowedResources .key -}}
  {{- $allowed = index .root.Values.allowedResources .key -}}
{{- end -}}
{{- $capable := false -}}
{{- if hasKey .root.Values.capabilities .key -}}
  {{- $capable = index .root.Values.capabilities .key -}}
{{- end -}}
{{- and $allowed $capable -}}
{{- end -}}
```

### 2. Update Every Template That Creates a Gated Resource

Find every occurrence where a template conditionally creates a resource based on `capabilities` alone. Replace the condition with the helper.

**Before:**

```yaml
{{- if .Values.capabilities.rbac }}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
...
{{- end }}
```

**After:**

```yaml
{{- if eq (include "chart.isAllowed" (dict "root" . "key" "rbac")) "true" }}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
...
{{- end }}
```

Repeat for every resource key: `deployment`, `replicaset`, `statefulset`, `service`, `ingress`, `configmap`, `secret`, `serviceaccount`, `networkpolicy`, `pdb`, `hpa`, and any others defined in your values.

### 3. Ensure values.yaml Has Both Blocks With Matching Keys

```yaml
allowedResources:
  rbac: true
  deployment: true
  replicaset: false
  statefulset: true
  service: true
  ingress: false
  configmap: true
  secret: true
  serviceaccount: true
  networkpolicy: false
  pdb: true
  hpa: false

capabilities:
  rbac: true
  deployment: true
  replicaset: true
  statefulset: false
  service: true
  ingress: true
  configmap: true
  secret: true
  serviceaccount: true
  networkpolicy: true
  pdb: false
  hpa: true
```

### 4. Handle Sub-Charts (Dependencies)

If this is an umbrella chart with sub-charts, sub-charts receive only their own scoped values by default. You need to explicitly pass `allowedResources` down.

**Option A — global values (recommended):**

```yaml
# parent values.yaml
global:
  allowedResources:
    rbac: true
    deployment: true
    ...
```

Then in the helper, reference `$.Values.global.allowedResources` instead:

```yaml
{{- $allowed := false -}}
{{- if hasKey .root.Values.global.allowedResources .key -}}
  {{- $allowed = index .root.Values.global.allowedResources .key -}}
{{- end -}}
```

**Option B — pass values explicitly per sub-chart:**

```yaml
# parent values.yaml
subchart-name:
  allowedResources:
    rbac: true
    ...
```

Option A is cleaner when many sub-charts share the same gate.

### 5. Validate

After making changes, run:

```bash
# Dry-run render to inspect output
helm template my-release ./my-chart -f values.yaml > rendered.yaml

# Check that gated-off resources are absent
grep -c "kind: ClusterRole" rendered.yaml

# Lint for syntax errors
helm lint ./my-chart -f values.yaml
```

Toggle values in `allowedResources` to `false` and re-render to confirm those resources disappear from the output even when `capabilities` has them as `true`.

---

## Checklist

- [ ] Helper `chart.isAllowed` added to `_helpers.tpl`
- [ ] Every gated template updated to use the helper instead of bare `capabilities` checks
- [ ] `values.yaml` has both `allowedResources` and `capabilities` blocks with matching keys
- [ ] Sub-chart value passing handled (global or explicit)
- [ ] `helm template` dry-run confirms gating works as expected
- [ ] `helm lint` passes cleanly
- [ ] Edge case: missing keys in one block do not cause render failures (handled by `hasKey` guard)
