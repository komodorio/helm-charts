# Komodor Helm Charts Repository - Project Context

## Repository Overview

This is **Komodor's official Helm Charts repository** that hosts and distributes Helm charts for Komodor's Kubernetes tooling ecosystem. The repository is published to GitHub Pages at **https://helm-charts.komodor.io** and serves as the central distribution point for installing Komodor tools in Kubernetes clusters.

**Primary Purpose**: Provide production-ready Helm charts for Komodor's suite of Kubernetes monitoring, visualization, and management tools.

---

## Available Helm Charts

### 1. komodor-agent (Flagship Product)
- **Location**: `charts/komodor-agent/`
- **App Version**: 0.2.189
- **Complexity**: ⭐⭐⭐⭐⭐ (50+ templates, 917-line values.yaml)
- **Purpose**: Kubernetes event watcher and monitoring agent that watches K8s resource-related events and sends them to Komodor's platform
- **Architecture**:
  - **Watcher**: Deployment that watches cluster events
  - **Metrics**: DaemonSet for metrics collection (Telegraf v2.0.34)
  - **Node-Enricher**: DaemonSet for node metadata
  - **Daemon**: Additional DaemonSet capabilities
  - **GPU Support**: Separate DaemonSet for GPU nodes
  - **Windows Support**: Separate DaemonSet for Windows nodes
- **Key Components**:
  - Admission controller (v0.1.49)
  - Actions capability (kubectl-like operations from UI)
  - Helm release tracking
  - Cost optimization features (HPA/KEDA webhooks)
  - Custom CA support
  - Proxy configuration
  - OpenTelemetry integration
- **Supported Architectures**: linux/amd64, linux/arm64
- **Registry**: `public.ecr.aws/komodor-public`

### 2. helm-dashboard
- **Location**: `charts/helm-dashboard/`
- **App Version**: 2.0.4
- **Complexity**: ⭐⭐ (9 templates, 149-line values.yaml)
- **Purpose**: GUI dashboard for visualizing and managing Helm releases in the cluster
- **Features**:
  - View installed Helm charts and revision history
  - See corresponding K8s resources
  - Allow write actions (create/update/delete)
  - Persistent storage for Helm data
  - Automatic repository updates in cluster mode

### 3. komoplane
- **Location**: `charts/komoplane/`
- **App Version**: 0.1.6
- **Complexity**: ⭐⭐ (8 templates, 96-line values.yaml)
- **Purpose**: Crossplane resource visualization and troubleshooting tool
- **Features**:
  - Visualize Crossplane resource relationships
  - Debug Crossplane infrastructure
  - Managed Resource (MR) caching with configurable TTL
  - Managed Resource Definition (MRD) caching

### 4. podmotion
- **Location**: `charts/podmotion/`
- **App Version**: 0.1.20
- **Complexity**: ⭐⭐ (7 templates, 181-line values.yaml)
- **Purpose**: Live container migration for Kubernetes using CRIU (Checkpoint/Restore In Userspace)
- **Features**:
  - Live migration with minimal downtime
  - CRIU-based checkpointing
  - Support for Deployments, StatefulSets, DaemonSets, Jobs
  - Node labeling system (`komodor.com/podmotion-node=true`)
  - Custom runtime class (`runtimeClassName: podmotion`)
  - eBPF-based packet redirection
- **Requirements**:
  - Linux kernel with CRIU support (5.x+ preferred)
  - containerd 1.6+
  - Privileged containers for installer
- **Supported Platforms**: AKS, GKE, kind, k3s, rke2, standard Kubernetes

---

## Repository Structure

```
/Users/giladtayeb/Git/helm-charts/
├── charts/                          # Helm charts directory
│   ├── komodor-agent/              # Main agent (50 templates)
│   │   ├── templates/              # Kubernetes manifests
│   │   │   ├── watcher/           # Watcher component templates
│   │   │   ├── metrics/           # Metrics component templates
│   │   │   ├── node-enricher/     # Node enricher templates
│   │   │   ├── opentelemetry/     # OpenTelemetry integration
│   │   │   ├── deployment.yaml
│   │   │   ├── daemonset.yaml
│   │   │   ├── daemonset_gpu.yaml
│   │   │   ├── daemonset_windows.yaml
│   │   │   └── clusterrole.yaml
│   │   ├── utilities/             # Helper utilities
│   │   │   └── memory-planning/   # Pre-deployment memory analysis
│   │   ├── values.yaml            # 917 lines of configuration
│   │   ├── Chart.yaml
│   │   ├── README.md              # 51.4KB comprehensive guide
│   │   ├── README.md.gotmpl       # helm-docs template
│   │   └── Makefile               # Build automation
│   ├── helm-dashboard/
│   ├── komoplane/
│   └── podmotion/
│       └── examples/              # Migration CRD examples
├── .buildkite/                    # Primary CI/CD (Buildkite)
│   ├── pipeline.yml              # Main pipeline definition
│   ├── pipeline_scripts/         # Build and release scripts
│   │   ├── bump_version.sh       # Version management
│   │   ├── publish_helm_charts.sh # Chart publishing
│   │   └── ...
│   ├── tests/                    # Python pytest integration tests
│   │   ├── helm_helper.py
│   │   ├── kubernetes_helper.py
│   │   ├── komodor_helper.py
│   │   └── test_*.py
│   ├── release_checks/           # Release validation system
│   │   ├── gcp-tf/              # Terraform for GKE test clusters
│   │   ├── k8s-gcp-tools/       # Docker image with tools
│   │   ├── pipeline/            # Release pipeline templates
│   │   └── scenarios/           # Test scenarios (memory leak, log chaos)
│   └── vulnerability-scan/       # Security scanning
├── .github/                       # Secondary CI/CD (GitHub Actions)
│   └── workflows/
│       ├── publish-chart-komoplane.yaml
│       ├── publish-chart-dashboard.yaml
│       └── publish-chart-podmotion.yaml
├── manifests/                     # Legacy Kustomize manifests
│   ├── base/
│   └── overlays/
├── scripts/                       # Utility scripts
│   ├── helm-migration/           # Go tool for migrating old chart values
│   ├── network-mapper/
│   ├── nginx/
│   └── telegraf/
├── publish.sh                     # Chart publishing script
├── install-helm.sh               # Helm installation script
├── .pre-commit-config.yaml       # Git hooks (helm-docs)
└── README.md                      # Main repository documentation
```

---

## CI/CD Architecture

### Primary: Buildkite (for komodor-agent)

**Pipeline File**: `.buildkite/pipeline.yml`

**Testing Framework**:
- Python + pytest + kind (Kubernetes in Docker)
- Test types:
  - Template validation tests
  - Integration tests (basic_test, values_base_test)
  - Proxy configuration tests
  - Component capability tests
  - Legacy K8s version compatibility (1.19+)
  - Validation tests

**Release Process** (komodor-agent):
1. **Code merged to master**
2. **Template sanity checks**
3. **README validation** (helm-docs)
4. **Integration tests** on kind clusters
5. **Dry-run on staging** cluster
6. **Manual approval**: "Bump Versions" block
7. **Version bump** via `bump_version.sh`
8. **Manual approval**: "release helm chart" block
9. **Publish charts** via `publish_helm_charts.sh`:
   - Clone gh-pages branch
   - Package charts with `helm package`
   - Push to Docker Hub OCI registry (komodor-agent only)
   - Sync to S3 buckets (komodor.com, komodor.io)
   - Generate `index.yaml` with `helm repo index`
   - Commit and push to gh-pages
10. **Create GitHub release** (draft)
11. **Validate chart** in public repo
12. **Deploy to environments**:
    - Staging cluster
    - Production US cluster
    - Production EU cluster
    - CI/lab clusters

**Agent-Stability-Checks Pipeline**:
- Long-running release validation (1 hour)
- Creates GKE cluster via Terraform
- Deploys test scenarios (memory leaks, log chaos)
- Runs RC and GA versions side-by-side
- Compares behavior and stability

### Secondary: GitHub Actions (for helm-dashboard, komoplane, podmotion)

**Tool**: chart-releaser (v1.4.1)
**Trigger**: Push to master or manual workflow_dispatch
**Process**:
1. Package chart
2. Upload to GitHub releases
3. Update index.yaml
4. Push to gh-pages branch

---

## Version Management

### komodor-agent
- **Chart.yaml version**: 0.0.0 (replaced dynamically by CI)
- **App version**: Updated when new agent Docker image is released
- **RC Workflow**:
  - Format: `1.1.1+RC1` (RC on top of GA version)
  - Automatic RC creation on merge to master or new agent release
  - RC promoted to GA after stability checks pass

### Other Charts
- **Semantic versioning**: Manually managed
- **Chart version**: Matches app version typically
- **Release process**: GitHub Actions on version tag

---

## Technology Stack

### Core Technologies
- **Helm**: v3.x for chart packaging and distribution
- **Kubernetes**: 1.19+ (komodor-agent), 1.16+ (dashboard)
- **Docker**: Multi-registry support
  - `public.ecr.aws/komodor-public` (komodor-agent)
  - `komodorio/*` (Docker Hub)

### Build & Development Tools
- **helm-docs** (v1.11.2): Auto-generate README from values.yaml comments
- **pre-commit**: Git hooks for README generation on values.yaml changes
- **kind** (v0.19.0): Local Kubernetes testing
- **Make**: Build automation (see `charts/komodor-agent/Makefile`)
- **Python + pytest**: Integration testing framework
- **bats**: Bash script testing
- **Go**: Helm migration utility (`scripts/helm-migration/`)

### Monitoring & Observability
- **Telegraf**: v2.0.34 (alpine for Linux, separate Windows version)
- **OpenTelemetry**: Integration for distributed tracing
- **Prometheus**: Metrics endpoints
- **Metrics Server**: Kubernetes metrics collection

### Infrastructure & Deployment
- **GitHub Pages**: Chart hosting (https://helm-charts.komodor.io)
- **AWS S3**: Chart storage mirrors (helm-charts.komodor.com, helm-charts.komodor.io)
- **Docker Hub**: OCI registry for komodor-agent chart
- **Terraform**: GCP infrastructure provisioning for release tests
- **AWS SSM**: Secrets management for CI/CD

### Testing Infrastructure
- **kind**: Ephemeral Kubernetes clusters for testing
- **GKE**: Long-running stability tests (via Terraform)
- **pytest fixtures**: Reusable test data and helpers

---

## Key Development Workflows

### Adding a New Feature to komodor-agent

1. **Develop locally**: Modify templates and values.yaml
2. **Update README**: Run `make docs` to regenerate from values.yaml comments
3. **Pre-commit hook**: Automatically runs helm-docs on commit
4. **Test locally**: Use kind or existing cluster
5. **Create PR**: CI runs template validation and integration tests
6. **Merge to master**: Automatic RC creation
7. **Stability validation**: 1-hour agent-stability-checks pipeline
8. **Manual version bump**: Approve "Bump Versions" block
9. **Publish**: Approve "release helm chart" block
10. **Deploy**: Automatic deployment to staging → production

### Modifying Other Charts (helm-dashboard, komoplane, podmotion)

1. **Develop locally**: Modify chart files
2. **Update version**: Manually increment version in Chart.yaml
3. **Create PR**: Review and merge
4. **GitHub Actions**: Automatically publishes on merge to master
5. **Verify**: Check GitHub releases and helm repo

### Testing Changes

```bash
# Local template validation
cd charts/komodor-agent
helm template test-release . --values values.yaml --debug

# Integration tests
cd .buildkite/tests
make install-requirements
pytest -v test_basic.py

# Memory planning utility
kubectl apply -f charts/komodor-agent/utilities/memory-planning/
kubectl logs -n komodor-memory-planning job/memory-checker
```

### Publishing Charts Manually

```bash
# Package chart
helm package charts/komodor-agent

# Update index
helm repo index . --url https://helm-charts.komodor.io

# Push to gh-pages (handled by CI normally)
```

---

## Key Configuration Files

### komodor-agent
- **values.yaml**: 917 lines of configuration options
  - API key and cluster name (required)
  - Site (US/EU regions)
  - Component toggles (watcher, metrics, node-enricher, daemon)
  - Resource limits and requests
  - RBAC settings
  - Proxy configuration
  - Custom CA certificates
  - Namespace watching scope
  - Resource filtering
  - Actions capability
  - Helm release tracking
  - Cost optimization features
- **staging-values.yaml**: Staging environment overrides
- **production-values.yaml**: Production configuration
- **ci-override-values.yaml**: CI test customizations

### Build Configuration
- **.pre-commit-config.yaml**: Runs helm-docs on values.yaml changes
- **Makefile** (komodor-agent): Build targets for docs generation, testing
- **.buildkite/pipeline.yml**: Main CI/CD pipeline definition

---

## Important Patterns & Conventions

### Multi-Environment Support
- **US region**: `site: "us"` → API: `https://api.komodor.com`
- **EU region**: `site: "eu"` → API: `https://api.komodor.io`
- Environment-specific values files for staging/production
- Cross-region agent reporting capability

### Security Practices
- **RBAC**: Fully automated ClusterRole/ClusterRoleBinding creation
- **Service accounts**: Automatic creation with token management
- **Custom CA**: TLS certificate injection for corporate networks
- **Read-only mode**: Option to disable write capabilities
- **Secret management**: AWS SSM for CI/CD secrets
- **Vulnerability scanning**: Automated in release pipeline

### Resource Management
- **Memory planning utility**: Pre-deployment analysis for large clusters
- **Resource quotas**: Configurable limits per component
- **Priority classes**: Pod scheduling priorities
- **Node selection**: Tolerations, affinity, node selectors
- **HPA/VPA support**: Horizontal/Vertical Pod Autoscaling

### Testing Philosophy
- **Short-cycle tests**: Fast feedback (template validation, basic integration)
- **Long-cycle tests**: 1-hour stability checks on real GKE clusters
- **Scenario-based testing**: Memory leaks, log chaos, proxy configurations
- **Side-by-side validation**: RC vs GA comparison before promotion

### Documentation Standards
- **helm-docs**: README auto-generation from values.yaml comments
- **Format**: Each value documented with description, type, default
- **Pre-commit hook**: Ensures README stays in sync with values.yaml
- **Comprehensive guides**: Each chart has extensive README with examples

---

## Special Utilities & Tools

### Memory Planning Utility
- **Location**: `charts/komodor-agent/utilities/memory-planning/`
- **Purpose**: Analyze cluster size and recommend agent memory settings
- **Usage**:
  ```bash
  kubectl apply -f charts/komodor-agent/utilities/memory-planning/
  kubectl logs -n komodor-memory-planning job/memory-checker
  ```
- **Output**: Memory recommendations (request, min limit, recommended limit)
- **Use case**: Prevent OOMKills in large clusters (1000+ nodes)

### Helm Migration Tool
- **Location**: `scripts/helm-migration/`
- **Language**: Go
- **Purpose**: Migrate from legacy k8s-watcher chart to komodor-agent chart
- **Build**: Cross-platform (Windows/Linux/macOS for amd64/arm64)
- **Usage**:
  ```bash
  cd scripts/helm-migration
  go run main.go --release-name komodor-agent --namespace komodor
  ```
- **Output**: Migration command with mapped values

### Legacy Kustomize Manifests
- **Location**: `manifests/`
- **Status**: Legacy, pre-Helm deployment method
- **Structure**: Base + overlays pattern
- **Note**: Replaced by Helm charts, kept for historical reference

---

## Common Tasks & Commands

### Development

```bash
# Generate documentation for komodor-agent
cd charts/komodor-agent
make docs

# Validate chart templates
helm lint charts/komodor-agent

# Render templates locally
helm template test-release charts/komodor-agent --values values.yaml

# Run integration tests
cd .buildkite/tests
make install-requirements
pytest -v

# Check for outdated dependencies
helm dependency update charts/komodor-agent
```

### Installation & Usage

```bash
# Add Komodor Helm repository
helm repo add komodorio https://helm-charts.komodor.io
helm repo update

# Install komodor-agent
helm install komodor-agent komodorio/komodor-agent \
  --set apiKey=YOUR_API_KEY \
  --set clusterName=my-cluster \
  --namespace komodor \
  --create-namespace

# Install with custom values
helm install komodor-agent komodorio/komodor-agent \
  --values custom-values.yaml \
  --namespace komodor

# Upgrade existing installation
helm upgrade komodor-agent komodorio/komodor-agent \
  --reuse-values \
  --set image.tag=0.2.189

# Check agent status
kubectl get pods -n komodor
kubectl logs -n komodor deployment/komodor-agent-watcher
```

### Release Management

```bash
# Bump version (manual process in CI)
.buildkite/pipeline_scripts/bump_version.sh

# Publish charts (manual trigger in CI)
.buildkite/pipeline_scripts/publish_helm_charts.sh

# Create GitHub release (done via CI)
gh release create v1.2.3 --draft --generate-notes
```

---

## Troubleshooting Guide

### Common Issues

#### komodor-agent OOMKills
- **Symptom**: Agent pods restarting with OOM errors
- **Solution**: Use memory-planning utility to calculate proper limits
- **Prevention**: Set appropriate resource limits based on cluster size

#### Helm Chart Not Found
- **Symptom**: `Error: chart "komodor-agent" not found in komodorio index`
- **Solution**:
  ```bash
  helm repo update
  helm search repo komodorio/komodor-agent
  ```

#### Template Validation Failures
- **Symptom**: CI tests failing on template validation
- **Solution**:
  ```bash
  helm template test-release . --debug --validate
  helm lint .
  ```

#### README Out of Sync
- **Symptom**: Pre-commit hook failing or README doesn't match values.yaml
- **Solution**:
  ```bash
  cd charts/komodor-agent
  make docs
  git add README.md values.yaml
  ```

#### Integration Tests Failing
- **Symptom**: pytest failures in CI
- **Solution**: Run tests locally with kind
  ```bash
  cd .buildkite/tests
  make install-requirements
  kind create cluster
  pytest -v -s test_basic.py
  ```

---

## Multi-Region & Multi-Cluster Architecture

### Supported Regions
- **US**: `site: "us"` → `https://api.komodor.com`
- **EU**: `site: "eu"` → `https://api.komodor.io`

### Deployment Targets (komodor-agent)
1. **Staging cluster**: Initial deployment for validation
2. **Production US cluster**: US region production
3. **Production EU cluster**: EU region production
4. **CI cluster**: Continuous testing environment
5. **Lab cluster**: Experimental features
6. **Customer clusters**: Managed via Helm chart distribution

### Cross-Region Reporting
- Agents can report to different regions than their installation region
- Configurable via `site` parameter in values.yaml
- Useful for multi-region observability

---

## Security & Compliance

### RBAC Configuration
- **Automatic creation**: ClusterRole, ClusterRoleBinding, ServiceAccount
- **Granular permissions**: Read-only by default with opt-in write capabilities
- **Namespace-scoped option**: Limit agent to single namespace
- **Actions capability**: Optional kubectl-like operations from UI

### Secret Management
- **API keys**: Stored in Kubernetes secrets
- **CI/CD secrets**: AWS SSM for pipeline secrets
- **Custom CA**: Inject trusted certificates for corporate networks
- **Token rotation**: Support for temporary service account tokens

### Vulnerability Scanning
- **Location**: `.buildkite/vulnerability-scan/`
- **Process**: Automated scanning in release pipeline
- **Scope**: Container images, Helm charts, dependencies

---

## License & Ownership

- **Owner**: Komodor Ltd (komodorio GitHub organization)
- **License**: Proprietary (Komodor Kubernetes agent license)
- **Not Open Source**: Source code is proprietary
- **Distribution**: Free Helm chart distribution for Komodor customers

---

## Quick Reference Links

### Documentation
- **komodor-agent README**: `charts/komodor-agent/README.md` (51.4KB)
- **Memory Planning**: `charts/komodor-agent/utilities/memory-planning/README.md`
- **Helm Dashboard**: `charts/helm-dashboard/README.md`
- **Komoplane**: `charts/komoplane/README.md`
- **Podmotion**: `charts/podmotion/README.md`
- **Release Process**: `.buildkite/release_checks/README.md`
- **Migration Tool**: `scripts/helm-migration/README.md`

### Key Files
- **Main Pipeline**: `.buildkite/pipeline.yml`
- **Version Bump**: `.buildkite/pipeline_scripts/bump_version.sh`
- **Chart Publishing**: `.buildkite/pipeline_scripts/publish_helm_charts.sh`
- **Integration Tests**: `.buildkite/tests/test_*.py`
- **Values Schema**: `charts/komodor-agent/values.yaml`

### External Resources
- **Helm Repository**: https://helm-charts.komodor.io
- **GitHub Releases**: https://github.com/komodorio/helm-charts/releases
- **Docker Images**: https://gallery.ecr.aws/komodor-public
- **Documentation**: https://docs.komodor.com

---

## Working with This Repository

### For New Contributors

1. **Understand the chart structure**: Review `charts/komodor-agent/` first
2. **Run tests locally**: Use kind + pytest for rapid iteration
3. **Follow documentation standards**: Use helm-docs for README generation
4. **Test before PR**: Run `helm lint` and template validation
5. **Watch CI pipeline**: Understand the full release process

### For Operators/Users

1. **Add Helm repo**: `helm repo add komodorio https://helm-charts.komodor.io`
2. **Review values.yaml**: Understand configuration options
3. **Use memory planning**: For clusters with 100+ nodes
4. **Monitor agent health**: Check logs and metrics after installation
5. **Keep up to date**: Regular `helm upgrade` for latest features

### For Release Managers

1. **RC creation**: Automatic on merge to master
2. **Stability validation**: Monitor agent-stability-checks pipeline (1 hour)
3. **Version bump**: Approve manual block in Buildkite
4. **Chart publishing**: Approve release block after GitHub release
5. **Environment rollout**: Staging → Production US → Production EU
6. **GA promotion**: After RC passes all validation checks

---

## Architecture Decision Records (Implicit)

### Why Buildkite for Primary CI/CD?
- Complex multi-stage pipeline with manual approval gates
- Long-running stability checks (1+ hour)
- Integration with internal Komodor infrastructure
- Flexibility for custom testing scenarios

### Why GitHub Actions for Secondary Charts?
- Simple release workflow (package → upload → index)
- Native GitHub integration for releases
- Lower complexity charts don't need Buildkite features
- Community-standard chart-releaser tool

### Why helm-docs for Documentation?
- Single source of truth (values.yaml)
- Automatic README generation prevents drift
- Pre-commit hook ensures consistency
- Standard practice in Helm community

### Why kind for Integration Tests?
- Fast cluster creation/destruction
- Consistent test environment
- Docker-based, runs anywhere
- Sufficient for template and basic integration validation

### Why GKE for Stability Tests?
- Real cloud environment for production-like testing
- Long-running validation (1 hour)
- Side-by-side comparison (RC vs GA)
- Terraform-managed infrastructure as code

---

## Next Steps for Understanding This Repository

1. **Read the main README**: `README.md` for quick overview
2. **Explore komodor-agent**: Review `charts/komodor-agent/values.yaml` and `README.md`
3. **Check the pipeline**: Understand `.buildkite/pipeline.yml` workflow
4. **Run tests locally**: Set up kind and run pytest tests
5. **Review recent commits**: Understand recent changes and patterns
6. **Study release process**: Read `.buildkite/release_checks/README.md`

---

This CLAUDE.md provides comprehensive context for understanding the Komodor Helm Charts repository across sessions. Refer to specific sections as needed when working with different parts of the codebase.
