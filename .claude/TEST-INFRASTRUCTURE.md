# Test Infrastructure Documentation

**Created**: March 1, 2026
**Purpose**: Reference document for understanding and improving the helm-charts test suite
**Status**: Discovery complete, remediation phases pending

---

## Table of Contents

1. [Overview](#overview)
2. [Test Categories](#test-categories)
3. [Integration Tests (pytest)](#integration-tests-pytest)
4. [Stability Tests (1-Hour Validation)](#stability-tests-1-hour-validation)
5. [Other Test Types](#other-test-types)
6. [Known Issues](#known-issues)
7. [Remediation Plan](#remediation-plan)
8. [Quick Reference](#quick-reference)

---

## Overview

### Test Infrastructure Summary

| Category | Location | Framework | Test Files | Test Cases |
|----------|----------|-----------|------------|------------|
| Integration Tests | `.buildkite/tests/` | pytest + kind | 8 files | ~50+ cases |
| Stability Tests | `.buildkite/release_checks/scenarios/` | Python asyncio | 9 scenarios | N/A |
| Shell Tests | `.buildkite/pipeline_scripts/` | bash | 2 scripts | N/A |
| BATS Tests | `.buildkite/pipeline_scripts_tests/` | bats | 1 file | N/A |
| Helm Test Hooks | `charts/*/templates/tests/` | Helm test pods | 2 charts | 2 tests |

### Test Execution Flow (CI Pipeline)

```
1. Helm template sanity check
2. Bump version script test (BATS)
3. README validation (helm-docs)
4. validations_test
5. basic_test
6. values_base_test
7. values_capabilities_events_test  ← DISABLED (commented out)
8. values_capabilities_proxy_test
9. values_capabilities_test
10. values_components_test
11. legacy_k8s_versions_test
12. Staging dry-run
13. Manual approval gates
14. Version bump & publish
```

---

## Test Categories

### By Purpose

| Purpose | Tests | Description |
|---------|-------|-------------|
| **Input Validation** | validations_test.py | Validates Helm values (site, cluster name, API key, etc.) |
| **Installation** | basic_test.py | Core installation and pod readiness |
| **Configuration** | values_base_test.py, values_components_test.py | Value overrides and component settings |
| **Capabilities** | values_capabilities_*.py | Feature toggles (metrics, helm, actions, proxy, events) |
| **Compatibility** | legacy_k8s_versions_test.py | K8s version backwards compatibility |
| **Stability** | release_checks/scenarios/ | Long-running stress tests for RC validation |

### By Component Tested

| Component | Test Coverage | Files |
|-----------|--------------|-------|
| Watcher Deployment | ✅ Full | All pytest files |
| Metrics DaemonSet | ✅ Full | values_components_test.py, values_capabilities_test.py |
| Node-Enricher DaemonSet | ✅ Partial | values_components_test.py |
| Daemon DaemonSet | ✅ Partial | values_components_test.py |
| GPU DaemonSet | ⚠️ Template only | values_components_test.py (no functional test) |
| Windows DaemonSet | ⚠️ Template only | values_components_test.py (no functional test) |
| Admission Controller | ❌ Missing | No dedicated tests |
| OpenTelemetry | ❌ Missing | No integration tests |
| ClusterRole/RBAC | ⚠️ Template only | Pipeline helm template check |

---

## Integration Tests (pytest)

### Location: `.buildkite/tests/`

### Configuration Files

| File | Purpose |
|------|---------|
| `requirements.txt` | Dependencies: pytest 7.4.2, kubernetes 28.1.0, deepdiff, PyYAML, requests, pytest-rerunfailures |
| `config.py` | Environment config: API keys, namespaces, release names, backend URLs |
| `fixtures.py` | pytest fixtures: cluster setup/teardown, cleanup |
| `Makefile` | Build targets for each test type |

### Helper Modules (`helpers/`)

| Module | Lines | Functions |
|--------|-------|-----------|
| `helm_helper.py` | 55 | `helm_agent_install()`, `helm_template()`, `helm_agent_uninstall()` |
| `kubernetes_helper.py` | 157 | Pod checks, secrets, service accounts, logs, rollout |
| `komodor_helper.py` | 35 | Backend API queries, UID creation |
| `utils.py` | 30 | Shell command utilities, filename helpers |

### Test Files Detail

#### 1. `validations_test.py` (202 lines)

**Purpose**: Validate Helm template input requirements

**Test Cases**:
| Test | Parameters | Validates |
|------|------------|-----------|
| `test_site_validation` | il, asia, EU, US, eu, us | Invalid/valid site values |
| `test_cluster_name_validation` | missing, empty | Required cluster name |
| `test_api_key_validation` | missing, empty, from-secret | API key handling |
| `test_service_account_validation` | create=false without name | SA requirements |
| `test_admission_controller_sa` | RBAC SA requirements | Admission controller SA |
| `test_tags_validation` | map, string, array | Tags type validation |
| `test_combined_validations` | multiple missing values | Combined error handling |

**Parameterization**: 20+ test cases via `pytest.mark.parametrize`

---

#### 2. `basic_test.py` (62 lines)

**Purpose**: Core installation and connectivity tests

**Test Cases**:
| Test | Description | Timeout |
|------|-------------|---------|
| `test_dont_provide_required_values` | Missing apiKey/clusterName rejection | N/A |
| `test_helm_installation` | Full install with pod readiness | 100 seconds |
| `test_get_configmap_from_resources_api` | Backend API connectivity | Retry with backoff |

**Dependencies**: `setup_cluster` fixture, backend API access

---

#### 3. `values_base_test.py` (82 lines)

**Purpose**: Test value override mechanisms

**Test Cases**:
| Test | Configuration Tested |
|------|---------------------|
| `test_override_image_tag` | Container image tag customization |
| `test_override_image_name` | Container image name customization |
| `test_api_key_from_secret` | Secret-based API key injection |
| `test_use_existing_service_account` | Pre-existing service account usage |
| `test_override_image_default_pull_policy` | ImagePullPolicy for Deployment/DaemonSet |
| `test_image_pull_secret_for_service_account` | Image pull secret configuration |

---

#### 4. `values_components_test.py` (222 lines)

**Purpose**: Component-level configuration testing

**Test Cases** (with parameterization):
| Test | Scenarios | Components Tested |
|------|-----------|-------------------|
| `test_override_deployment_pod_annotations` | 2 | komodorAgent, komodorMetrics |
| `test_user_labels` | 5 | Deployment, DaemonSet variants |
| `test_override_deployment_tolerations` | 3 | GPU/special node tolerations |
| `test_override_deployment_node_selector` | 3 | Node selector configuration |
| `test_override_deployment_annotations` | 3 | Deployment-level annotations |
| `test_override_deployment_affinity` | 3 | Node affinity rules |
| `test_extra_env_vars` | 4 | watcher, supervisor, metrics, metricsInit |
| `test_override_security_context` | 4 | runAsUser, fsGroup |
| `test_override_update_strategy` | 5 | Rolling updates for Deployments/DaemonSets |

**Total parameterized cases**: 30+

---

#### 5. `values_capabilities_test.py` (111 lines)

**Purpose**: Feature capability testing

**Test Cases**:
| Test | Capability | Notes |
|------|------------|-------|
| `test_get_metrics` | Metrics collection | ⚠️ Flaky (reruns=3), 5-minute wait |
| `test_disable_helm_capabilities` | Helm tracking | Toggle verification |
| `test_disable_actions_capabilities` | Actions (basic, advanced, podExec, portforward) | Toggle verification |
| `test_log_redact_multiline` | Log redaction | Pattern validation |

---

#### 6. `values_capabilities_proxy_test.py` (187 lines)

**Purpose**: Proxy and custom CA testing

**Test Cases**:
| Test | Description | Notes |
|------|-------------|-------|
| `test_use_proxy_and_custom_ca` | Full proxy integration test | ⚠️ Flaky (reruns=3) |
| `test_proxy_envroinment_vars_are_set` | Env var injection (3 scenarios) | HTTP_PROXY, HTTPS_PROXY variants |

**Setup Requirements**:
- mitmproxy pod deployed via `test-data/mitm-proxy.yaml`
- CA certificate extraction from proxy pod
- Secret creation for custom CA

**Known TODO**: Line 81 - NetworkPolicy not implemented for proxy testing

---

#### 7. `values_capabilities_events_test.py` (97 lines) ⚠️ DISABLED IN CI

**Purpose**: Event watching and redaction testing

**Test Cases**:
| Test | Description | Notes |
|------|-------------|-------|
| `test_namespace_behavior` | Namespace watching vs denylist (2 scenarios) | ⚠️ Flaky (reruns=3) |
| `test_redact_workload_names` | Workload name redaction in events | ⚠️ Flaky (reruns=3) |

**Status**: **COMMENTED OUT** in pipeline.yml lines 71-83

**Known Issue**: Line 95 has bare `except:` clause (should be `except Exception:`)

---

#### 8. `legacy_k8s_versions_test.py` (25 lines)

**Purpose**: Kubernetes version backwards compatibility

**Test Cases**:
| Test | K8s Versions |
|------|--------------|
| `test_agent_on_legacy_k8s_versions` | 1.25.11, 1.27.13 |

**Implementation**: Uses pytest indirect fixture parameter to create clusters with specific versions

---

## Stability Tests (1-Hour Validation)

### Location: `.buildkite/release_checks/`

### Purpose

Validate RC (Release Candidate) stability before promoting to GA (General Availability) through long-running stress tests on real GKE infrastructure.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    agent-stability-checks Pipeline               │
├─────────────────────────────────────────────────────────────────┤
│  1. Manual Trigger                                               │
│  2. Select RC Version + Mode (GA/Hotfix)                        │
│  3. Create GKE Cluster (Terraform)                              │
│  4. Deploy 9 Stress Scenarios                                    │
│  5. Install RC Agent + GA Agent (side-by-side)                  │
│  6. Wait 1 Hour (default timeout)                               │
│  7. Cleanup Scenarios                                            │
│  8. Destroy Cluster                                              │
│  9. User Approves Version Bump                                   │
│  10. Trigger helm-charts release pipeline                        │
└─────────────────────────────────────────────────────────────────┘
```

### Components

| Component | Location | Purpose |
|-----------|----------|---------|
| Terraform | `gcp-tf/` | Create ephemeral GKE clusters |
| Docker Image | `k8s-gcp-tools/` | kubectl, helm, terraform, gcloud tooling |
| Pipeline Generator | `pipeline/generate.py` | Generate release pipeline YAML |
| Scenarios | `scenarios/` | Stress test implementations |
| Entry Script | `ci.sh` | Start k8s-gcp-tools container |
| Runner Script | `start.sh` | Provision cluster and run scenarios |

### Scenarios (9 Total)

| Scenario | File | Purpose | Behavior |
|----------|------|---------|----------|
| `komodor_agent` | `komodor_agent/scenario.py` | RC vs GA comparison | Deploy both versions side-by-side |
| `memory_leak` | `memory_leak/scenario.py` | OOMKill handling | 10 pods with intentional memory leaks (32-75MB limits) |
| `log_chaos` | `log_chaos/scenario.py` | Logging stability | 10 deployments generating high log volume |
| `jobs` | `jobs/scenario.py` | Batch job tracking | Jobs every ~minute (random 0s-15min duration) |
| `edit_deployment` | `edit_deployment/scenario.py` | Change detection | Deployments modified every ~minute |
| `mass_deployment` | `mass_deployment/scenario.py` | Scalability | X deployments at once |
| `daemonset` | `daemonset/scenario.py` | DaemonSet tracking | X DaemonSets across cluster |
| `image_pull_backoff` | `image_pull_backoff/scenario.py` | Error event capture | Deployments with non-existent images |
| `bank_of_anthos` | `bank_of_anthos/scenario.py` | Real-world simulation | Sample bank microservices app |

### Scenario Base Class

Location: `scenarios/scenario.py`

```python
class Scenario:
    async def run(self):
        """Deploy scenario resources"""
        raise NotImplementedError

    async def cleanup(self):
        """Remove scenario resources"""
        raise NotImplementedError
```

### Entry Point

Location: `scenarios/main.py`

- Runs all scenarios in parallel using asyncio
- Signal handlers for graceful shutdown (SIGINT, SIGTERM)
- Optional `--skip-cleanup` flag
- Requires `CHART_VERSION` and `AGENT_API_KEY` environment variables

### Environment Variables

| Variable | Purpose | Source |
|----------|---------|--------|
| `CHART_VERSION` | RC version to test (e.g., `1.2.3+RC1`) | Pipeline input |
| `AGENT_API_KEY` | Agent API key | AWS SSM |
| `KUBECONFIG` | Cluster credentials | Terraform output |

### Pipeline Templates

| File | Phase | Purpose |
|------|-------|---------|
| `pipeline_template_ph1.yaml` | Phase 1 | Version selection, cluster creation |
| `pipeline_template_ph2.yaml` | Phase 2 | Scenario execution, cleanup, release trigger |

### Modes

| Mode | Description | Scenarios Run |
|------|-------------|---------------|
| GA | Full validation | All 9 scenarios for 1 hour |
| Hotfix | Quick release | Skips scenarios (urgent fixes only) |

---

## Other Test Types

### Shell Tests (Staging Deployment)

| File | Purpose |
|------|---------|
| `.buildkite/pipeline_scripts/test_helm_new_install.sh` | Fresh chart installation on staging |
| `.buildkite/pipeline_scripts/test_helm_update_install.sh` | Chart upgrade path testing |

### BATS Tests (Script Validation)

| File | Purpose |
|------|---------|
| `.buildkite/pipeline_scripts_tests/bump_version_test.bat` | Version bump script validation |

### Helm Test Hooks

| Chart | File | Purpose |
|-------|------|---------|
| helm-dashboard | `templates/tests/test-connection.yaml` | Service connectivity (wget) |
| komoplane | `templates/tests/test-connection.yaml` | Service connectivity |

---

## Known Issues

### Critical Issues

| ID | Issue | Location | Severity | Description |
|----|-------|----------|----------|-------------|
| **ISS-001** | Disabled Test | `pipeline.yml:71-83` | 🔴 High | `values_capabilities_events_test` commented out - namespace watching and redaction tests not running |
| **ISS-002** | Bare Except | `values_capabilities_events_test.py:95` | 🟡 Medium | Catches all exceptions including SystemExit, KeyboardInterrupt |

### Flaky Tests

| ID | Test | File | Reruns | Likely Cause |
|----|------|------|--------|--------------|
| **FLK-001** | `test_get_metrics` | values_capabilities_test.py | 3 | Timing - waits up to 5 minutes for metrics collection |
| **FLK-002** | `test_use_proxy_and_custom_ca` | values_capabilities_proxy_test.py | 3 | Complex setup - mitmproxy CA extraction |
| **FLK-003** | `test_namespace_behavior` | values_capabilities_events_test.py | 3 | Backend API timing - event propagation delay |
| **FLK-004** | `test_redact_workload_names` | values_capabilities_events_test.py | 3 | Backend API timing - event indexing delay |

### Missing Coverage

| ID | Gap | Description | Priority |
|----|-----|-------------|----------|
| **GAP-001** | Windows DaemonSet | Only template validation, no functional tests | Low |
| **GAP-002** | GPU DaemonSet | Only template validation, no functional tests | Low |
| **GAP-003** | Admission Controller | No dedicated integration tests | Medium |
| **GAP-004** | OpenTelemetry | No integration tests for OTEL configuration | Medium |
| **GAP-005** | Cost Features | No tests for HPA/KEDA webhooks | Medium |
| **GAP-006** | Network Policy | TODO at proxy_test.py:81 - proxy tests don't validate network isolation | Low |

### Test Isolation Concerns

| ID | Concern | Location | Impact |
|----|---------|----------|--------|
| **ISO-001** | Shared cluster state | fixtures.py | Tests may affect each other |
| **ISO-002** | External mitmproxy dependency | proxy_test.py | Non-deterministic setup |
| **ISO-003** | No cleanup verification | fixtures.py | Stale resources between tests |

---

## Remediation Plan

### Phase 1: Critical Fixes (Immediate)

| Task | Issue | Action | Effort |
|------|-------|--------|--------|
| 1.1 | ISS-001 | Investigate why events test was disabled, fix or create tracking issue | 2-4 hours |
| 1.2 | ISS-002 | Fix bare except clause to `except Exception as e:` | 5 minutes |

### Phase 2: Flakiness Reduction (Short-term)

| Task | Issue | Action | Effort |
|------|-------|--------|--------|
| 2.1 | FLK-001 | Add exponential backoff to metrics query, explicit pod ready check | 2 hours |
| 2.2 | FLK-002 | Add mitmproxy readiness verification before CA extraction | 2 hours |
| 2.3 | FLK-003, FLK-004 | Improve backend query retry logic with longer initial wait | 2 hours |

### Phase 3: Test Isolation (Medium-term)

| Task | Issue | Action | Effort |
|------|-------|--------|--------|
| 3.1 | ISO-001 | Use unique namespaces per test or test class | 4 hours |
| 3.2 | ISO-002 | Deploy mitmproxy as part of cluster setup fixture | 4 hours |
| 3.3 | ISO-003 | Add cleanup verification step in fixture teardown | 2 hours |

### Phase 4: Coverage Expansion (Long-term)

| Task | Gap | Action | Effort |
|------|-----|--------|--------|
| 4.1 | GAP-003 | Add admission controller validation tests | 8 hours |
| 4.2 | GAP-004 | Add OTEL trace export verification tests | 8 hours |
| 4.3 | GAP-005 | Add HPA/KEDA webhook integration tests | 8 hours |
| 4.4 | GAP-006 | Implement NetworkPolicy for proxy test isolation | 4 hours |

---

## Quick Reference

### Running Tests Locally

```bash
# Navigate to test directory
cd .buildkite/tests

# Install dependencies
make install-requirements

# Create kind cluster
kind create cluster --name test --wait 5m

# Run specific test suite
make validations_test
make basic_test
make values_base_test
make values_components_test
make values_capabilities_test
make values_capabilities_proxy_test
make values_capabilities_events_test  # Currently disabled in CI
make legacy_k8s_versions_test

# Run with pytest directly (for debugging)
pytest -v -s validations_test.py
pytest -v -s basic_test.py::test_helm_installation

# Cleanup
kind delete cluster --name test
```

### Running Stability Tests Locally

```bash
cd .buildkite/release_checks/scenarios

# Prerequisites
export CHART_VERSION="1.2.3+RC1"
export AGENT_API_KEY="your-api-key"
export KUBECONFIG="/path/to/kubeconfig"

# Run all scenarios
python3 main.py $KUBECONFIG

# Run with skip cleanup (for debugging)
python3 main.py $KUBECONFIG --skip-cleanup
```

### Key Files Reference

| Purpose | File |
|---------|------|
| CI Pipeline | `.buildkite/pipeline.yml` |
| Test Configuration | `.buildkite/tests/config.py` |
| Test Fixtures | `.buildkite/tests/fixtures.py` |
| Stability Entry Point | `.buildkite/release_checks/scenarios/main.py` |
| Scenario Base Class | `.buildkite/release_checks/scenarios/scenario.py` |
| GKE Terraform | `.buildkite/release_checks/gcp-tf/gke.tf` |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `API_KEY` | (from AWS SSM) | Test agent API key |
| `PUBLIC_API_KEY` | (from AWS SSM) | Public API key |
| `RELEASE_NAME` | `helm-test` | Helm release name |
| `CHART_PATH` | `../../charts/komodor-agent` | Chart location |
| `NAMESPACE` | `test-chart` | K8s namespace |
| `BE_BASE_URL` | `https://app.komodor.com` | Backend API URL |

---

## Appendix: Test Data Files

| File | Purpose |
|------|---------|
| `.buildkite/tests/test-data/mitm-proxy.yaml` | mitmproxy pod for proxy testing |
| `.buildkite/tests/test-data/network-mapper.yaml` | Network mapper pod configuration |

---

**Last Updated**: March 1, 2026
**Next Review**: After Phase 1 remediation complete
