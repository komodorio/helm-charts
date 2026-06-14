# Komodor Agent — Impersonation RBAC Design

**Date:** 2026-06-01
**Branch:** `CU-86c7qyj1g_rbac_changes_for_impersonation`
**Chart:** `charts/komodor-agent`

## Problem

When the Komodor agent performs user-triggered actions on a cluster, the API
calls are made by the agent's broad ServiceAccount. We want those actions to be
attributed to the real Komodor user (their email) in the cluster's audit log,
without requiring that user to exist as a real cluster identity or to have any
cluster RBAC of their own.

The mechanism is Kubernetes user impersonation: the agent calls the API with
`--as=<email>` (audit attribution) and `--as-group=<group>` (authorization).

### Key fact driving the design

Impersonation **replaces** the caller's identity — it does not stack with the
agent ServiceAccount's permissions. When the agent impersonates `<email>`, the
request is authorized as that user. Since the email is dynamic and typically has
no bindings, it has **zero** permissions on its own. Therefore the authorization
must come from an impersonated **Group** that carries the agent's permissions.

So: `--as=<email>` provides the audit trail; `--as-group=<group>` provides the
authorization.

## Goals

- Grant the agent ServiceAccount the ability to impersonate:
  - any user (unrestricted — see Security), and
  - one fixed group that carries the agent's existing permission set.
- Bind that group to the agent's existing permissions so impersonated calls have
  exactly the capabilities the agent already has.
- Opt-in, default off. No change to behavior for existing installs.

## Non-goals / out of scope

- **Agent runtime behavior.** This is a chart-only change that grants the RBAC.
  The agent code must separately choose to issue impersonated calls
  (`--as=<email> --as-group=komodor:agent-actions`) when executing user actions.
  The group string must match exactly on both sides. Tracked as a dependency.
- **Surfacing the group name to the pod** via env/configmap. The group is
  hardcoded on both sides; no plumbing added. Can be a follow-up if the agent
  team prefers reading it from config.
- Restricting impersonation by individual usernames (not feasible — see below).

## Decisions

| Decision | Choice |
|---|---|
| Purpose | `--as=<email>` for audit, `--as-group` carries authorization |
| Group model | New ClusterRoleBinding binding the **existing** `k8s-watcher` ClusterRole to a Group subject |
| Config surface | Single flag `capabilities.impersonation.enabled`, default `false` |
| Group name | Hardcoded constant `komodor:agent-actions` (not a value) |
| Template layout | One-object-per-file, matching existing chart convention (Approach 1) |
| User impersonation scope | Unrestricted (any user) |
| Group impersonation scope | Pinned to `komodor:agent-actions` via `resourceNames` |

## Configuration (values.yaml)

New block under `capabilities`:

```yaml
capabilities:
  # capabilities.impersonation -- Allow the agent to impersonate users (for audit attribution)
  # and a fixed group that carries the agent's own permissions, so user-triggered actions
  # are attributed to the real user while authorized via the agent's existing ClusterRole.
  # @default -- See sub-values
  impersonation:
    # capabilities.impersonation.enabled -- (bool) Grant the agent impersonate on users + the komodor agent group
    enabled: false
```

## Templates (Approach 1 — one object per file)

All three gated by `{{- if and .Values.createRbac .Values.capabilities.impersonation.enabled -}}`.

| File | Object | Subject → roleRef |
|---|---|---|
| `templates/clusterrole-impersonation.yaml` | ClusterRole `<fullname>-impersonation` | — |
| `templates/clusterrolebinding-impersonation.yaml` | ClusterRoleBinding | agent **SA** → `<fullname>-impersonation` |
| `templates/clusterrolebinding-k8s-watcher-group.yaml` | ClusterRoleBinding `<fullname>-k8s-watcher-group` | **Group** `komodor:agent-actions` → existing `<fullname>-k8s-watcher` |

New helpers in `templates/_service_account.tpl`:

- `komodorAgent.clusterRole.impersonation` → `<fullname>-impersonation`
- `komodorAgent.impersonationGroup` → `komodor:agent-actions` (single source of truth)

No existing template files are modified.

### clusterrole-impersonation.yaml

```yaml
{{- if and .Values.createRbac .Values.capabilities.impersonation.enabled -}}
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: {{ include "komodorAgent.clusterRole.impersonation" . }}
rules:
  - apiGroups: [""]
    resources: ["users"]
    verbs: ["impersonate"]
  - apiGroups: [""]
    resources: ["groups"]
    resourceNames:
      - {{ include "komodorAgent.impersonationGroup" . | quote }}
    verbs: ["impersonate"]
{{- end -}}
```

### clusterrolebinding-impersonation.yaml

```yaml
{{- if and .Values.createRbac .Values.capabilities.impersonation.enabled -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ include "komodorAgent.clusterRole.impersonation" . }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ include "komodorAgent.clusterRole.impersonation" . }}
subjects:
  - kind: ServiceAccount
    name: {{ include "komodorAgent.serviceAccountName" . }}
    namespace: {{ .Release.Namespace }}
{{- end -}}
```

### clusterrolebinding-k8s-watcher-group.yaml

```yaml
{{- if and .Values.createRbac .Values.capabilities.impersonation.enabled -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ include "komodorAgent.clusterRole.k8sWatcher" . }}-group
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ include "komodorAgent.clusterRole.k8sWatcher" . }}
subjects:
  - kind: Group
    name: {{ include "komodorAgent.impersonationGroup" . }}
    apiGroup: rbac.authorization.k8s.io
{{- end -}}
```

## Runtime effect

At runtime the agent calls `--as=<email> --as-group=komodor:agent-actions`:

- `<email>` → audit attribution (no permissions of its own).
- `komodor:agent-actions` → resolves to the `k8s-watcher` ClusterRole, i.e.
  exactly the permission set the agent already has (shaped by `capabilities.*`
  and `allowedResources.*`).

The agent's own SA → `k8s-watcher` binding stays intact for its normal
watch/read loop. Impersonation is additive.

## Security considerations

- `impersonate` on `users` is **unrestricted** (any username). This is forced:
  emails are dynamic and Kubernetes `resourceNames` does not support
  wildcards/prefixes. An unrestricted user-impersonation grant means the agent
  could impersonate a username that happens to hold privileged bindings; however
  the agent SA already holds broad permissions directly, so this does not
  meaningfully expand its blast radius.
- `impersonate` on `groups` is pinned to the single `komodor:agent-actions`
  group via `resourceNames`, so the agent cannot escalate via arbitrary groups
  (e.g. `system:masters`).
- The whole feature is opt-in (`enabled: false` by default); existing installs
  are unaffected.

## Testing / verification

- **Render tests (`helm template`):**
  - Flag off → none of the three objects render; default RBAC golden output is
    byte-identical to current (no regression).
  - Flag on → all three render with correct names, the `Group` subject, and the
    `groups` rule pinned via `resourceNames`.
- **`helm lint`** passes.
- **Live smoke test** (lab cluster, once AWS SSO is re-authenticated):
  - `kubectl auth can-i list pods --as=someone@komodor.io --as-group=komodor:agent-actions` → **yes**
  - `kubectl auth can-i list pods --as=someone@komodor.io` (no group) → **no**
    (proves the group carries the permissions, not the bare user).

## Open dependency

Agent application code must issue impersonated requests with the matching group
string. Without that, this RBAC is inert (granted but unused).
