# Komodor.io Helm Charts Repository

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
 
