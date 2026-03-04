# Navigate to the chart directory first
cd /Users/giladtayeb/Git/helm-charts/charts/komodor-agent

# Test 1: Validate template rendering
helm template test-release . \
  --set apiKey=test-key \
  --set clusterName=test-cluster \
  --dry-run=server > /tmp/helm-template-validation.txt 2>&1 || \
helm template test-release . \
  --set apiKey=test-key \
  --set clusterName=test-cluster > /tmp/helm-template-validation.txt 2>&1

# Test 2: Verify RBAC resource count and types
helm template test-release . \
  --set apiKey=test-key \
  --set clusterName=test-cluster 2>&1 | \
  grep "^kind:" | grep -E "ClusterRole|ClusterRoleBinding" | sort | uniq -c > /tmp/rbac-resource-count.txt

# Test 3: Show full ClusterRole output
helm template test-release . \
  --set apiKey=test-key \
  --set clusterName=test-cluster \
  --show-only templates/clusterrole.yaml > /tmp/clusterrole-rendered.yaml 2>&1

# Test 4: Show full ClusterRoleBinding output  
helm template test-release . \
  --set apiKey=test-key \
  --set clusterName=test-cluster \
  --show-only templates/clusterrolebinding.yaml > /tmp/clusterrolebinding-rendered.yaml 2>&1

# Test 5: Verify deployments/scale is present
helm template test-release . \
  --set apiKey=test-key \
  --set clusterName=test-cluster \
  --show-only templates/clusterrole.yaml 2>&1 | \
  grep -A 5 "deployments/scale" > /tmp/scale-permissions.txt

# Test 6: Test with actions disabled (should have no deployments/scale)
helm template test-release . \
  --set apiKey=test-key \
  --set clusterName=test-cluster \
  --set capabilities.actions=false \
  --show-only templates/clusterrole.yaml 2>&1 | \
  grep -c "deployments/scale" > /tmp/actions-disabled-test.txt 2>&1 || echo "0" > /tmp/actions-disabled-test.txt

# Test 7: Run helm lint
helm lint . > /tmp/helm-lint-output.txt 2>&1

# Test 8: Count all generated resources
helm template test-release . \
  --set apiKey=test-key \
  --set clusterName=test-cluster 2>&1 | \
  grep "^kind:" | sort | uniq -c > /tmp/all-resources-count.txt

echo "All tests completed. Output files saved to /tmp/"



git commit --amend -m "refactor(komodor-agent): consolidate duplicate ClusterRole permissions

- Merge two duplicate capabilities.actions conditional blocks into one
- Add deployments/scale and statefulsets/scale to consolidated block
- Extract ClusterRoleBinding to separate file for better organization
- No functional changes to generated RBAC resources

Fixes: duplicate permission blocks in clusterrole.yaml"