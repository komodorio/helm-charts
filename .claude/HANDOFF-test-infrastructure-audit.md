# Handoff: Test Infrastructure Audit

**Date**: March 1, 2026
**Branch**: `gt/cluster-role-dupl` (same branch as ClusterRole refactor)
**Status**: 🔍 **Discovery Complete** - Remediation phases pending
**Related**: [HANDOFF-cluster-role-refactor.md](./HANDOFF-cluster-role-refactor.md), [TEST-INFRASTRUCTURE.md](./TEST-INFRASTRUCTURE.md)

---

## 📋 Summary

Conducted comprehensive audit of the helm-charts test infrastructure. Documented all test suites, identified issues, and created a phased remediation plan. Full documentation saved to `TEST-INFRASTRUCTURE.md`.

---

## 🔍 What Was Discovered

### Test Infrastructure Overview

| Category | Location | Framework | Count |
|----------|----------|-----------|-------|
| Integration Tests | `.buildkite/tests/` | pytest + kind | 8 files, ~50+ cases |
| Stability Tests | `.buildkite/release_checks/scenarios/` | Python asyncio | 9 scenarios |
| Shell Tests | `.buildkite/pipeline_scripts/` | bash | 2 scripts |
| BATS Tests | `.buildkite/pipeline_scripts_tests/` | bats | 1 file |
| Helm Test Hooks | `charts/*/templates/tests/` | Helm pods | 2 charts |

### Critical Issues Found

| ID | Issue | Severity | Location |
|----|-------|----------|----------|
| **ISS-001** | `values_capabilities_events_test` DISABLED in CI | 🔴 High | `pipeline.yml:71-83` |
| **ISS-002** | Bare `except:` clause (catches SystemExit) | 🟡 Medium | `values_capabilities_events_test.py:95` |

### Flaky Tests (4 tests with reruns=3)

| Test | File | Cause |
|------|------|-------|
| `test_get_metrics` | values_capabilities_test.py | Metrics collection timing |
| `test_use_proxy_and_custom_ca` | values_capabilities_proxy_test.py | Complex mitmproxy setup |
| `test_namespace_behavior` | values_capabilities_events_test.py | Backend API timing |
| `test_redact_workload_names` | values_capabilities_events_test.py | Backend API timing |

### Missing Test Coverage

- Windows/GPU DaemonSets (functional tests)
- Admission Controller
- OpenTelemetry integration
- HPA/KEDA webhooks
- Network Policy isolation

---

## 📚 Documentation Created

### [TEST-INFRASTRUCTURE.md](./TEST-INFRASTRUCTURE.md)

Comprehensive reference document containing:

1. **Overview** - Test categories, execution flow, summary tables
2. **Integration Tests** - All 8 pytest files with test case details
3. **Stability Tests** - 1-hour validation architecture and 9 scenarios
4. **Other Tests** - Shell, BATS, Helm hooks
5. **Known Issues** - Critical issues, flaky tests, missing coverage
6. **Remediation Plan** - 4-phase improvement plan with effort estimates
7. **Quick Reference** - Commands, files, environment variables

---

## 🚀 Remediation Phases

### Phase 1: Critical Fixes (Immediate)
- [ ] **1.1**: Investigate disabled events test, fix or create tracking issue
- [ ] **1.2**: Fix bare except clause to `except Exception as e:`

### Phase 2: Flakiness Reduction (Short-term)
- [ ] **2.1**: Add exponential backoff to metrics query
- [ ] **2.2**: Add mitmproxy readiness verification
- [ ] **2.3**: Improve backend query retry logic

### Phase 3: Test Isolation (Medium-term)
- [ ] **3.1**: Use unique namespaces per test
- [ ] **3.2**: Deploy mitmproxy as part of cluster setup fixture
- [ ] **3.3**: Add cleanup verification step

### Phase 4: Coverage Expansion (Long-term)
- [ ] **4.1**: Add admission controller tests
- [ ] **4.2**: Add OTEL tests
- [ ] **4.3**: Add HPA/KEDA webhook tests
- [ ] **4.4**: Implement NetworkPolicy for proxy tests

---

## 🔄 1-Hour Stability Test Summary

**Pipeline**: `agent-stability-checks` (Buildkite)

**Purpose**: Validate RC stability before GA promotion

**Flow**:
```
Manual Trigger → Select RC → Create GKE (Terraform) → Deploy 9 Scenarios
→ Install RC+GA Side-by-Side → Wait 1 Hour → Cleanup → Destroy Cluster
```

**Scenarios**:
1. `komodor_agent` - RC vs GA comparison
2. `memory_leak` - OOMKill handling (10 pods)
3. `log_chaos` - High-volume logging (10 deployments)
4. `jobs` - Batch job tracking (random duration)
5. `edit_deployment` - Change detection (modified every ~minute)
6. `mass_deployment` - Scalability
7. `daemonset` - DaemonSet tracking
8. `image_pull_backoff` - Error event capture
9. `bank_of_anthos` - Real-world microservices

**Modes**: GA (full validation) or Hotfix (skip scenarios)

---

## 📂 Key Files

| Purpose | File |
|---------|------|
| Full Test Documentation | `.claude/TEST-INFRASTRUCTURE.md` |
| CI Pipeline | `.buildkite/pipeline.yml` |
| Disabled Test | `.buildkite/tests/values_capabilities_events_test.py` |
| Stability Entry Point | `.buildkite/release_checks/scenarios/main.py` |
| GKE Terraform | `.buildkite/release_checks/gcp-tf/gke.tf` |

---

## 💡 Next Session Recommendations

1. **Start with Phase 1** - Quick wins, high impact
2. **Reference TEST-INFRASTRUCTURE.md** - Contains all details
3. **For stability test deep-dive** - Read `scenarios/README.md` and `main.py`
4. **For specific test issues** - See "Known Issues" section in TEST-INFRASTRUCTURE.md

---

**Last Updated**: March 1, 2026
**Next Review**: After Phase 1 complete
