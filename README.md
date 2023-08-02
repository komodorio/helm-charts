# Komodor.io Helm Charts Repository

## Install with Kustomize

- Create namespace `kubectl create ns komodor`
- Install
  - `export KOMOKW_API_KEY=` (required)
  - `export KOMOKW_CLUSTER_NAME=`
  - Using `kubectl` - `kubectl apply -n komodor -k https://github.com/komodorio/helm-charts/manifests/overlays/full/?ref=master`
  - Using `kustomize` - `kustomize build https://github.com/komodorio/helm-charts/manifests/overlays/full/?ref=master | kubectl apply -n komodor -f -`

[Read more](./manifests/overlays/full/README.md)

## How to install a chart from this repository

- Add the repository to helm  
  `helm repo add komodorio https://helm-charts.komodor.io`

- Update helm repository listing  
  `helm repo update`

- Install the chart  
  `helm install komodorio/CHART_NAME`

## Available charts

[k8s-watcher](https://github.com/komodorio/helm-charts/tree/master/charts/k8s-watcher) - Watch for Kubernetes events in your cluster and sends them to Komodor  
[helm-dashboard](https://github.com/komodorio/helm-charts/tree/master/charts/helm-dashboard) - Visualize installed Helm charts, see their revision history and corresponding k8s resources
[komoplane](https://github.com/komodorio/komoplane/tree/master/charts/komoplane) - Visualize Crossplane resources

---
 
