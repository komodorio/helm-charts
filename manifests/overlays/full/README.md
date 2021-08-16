# Full features manifests 
## Extra features
The features are configured by adding additional permissions to cluster role and patching values in `komodor-k8s-watcher.yaml`
* Resync period - [Config] `controller.resync.period`
* Describing pod using `kubectl describe` [Config] `enableAgentTaskExecution=true`
* Reading pod logs [Config] `allowReadingPodLogs=true` and additional permissions in `logs-reader.yaml`
* Collecting history on installation `collectHistory=true`

## Install
* Create namespace `kubectl create ns komodor`
* Install
  * `export KOMOKW_API_KEY=$KOMODOR_API_KEY` (required)
  * `export KOMOKW_CLUSTER_NAME=$KOMOKW_CLUSTER_NAME`
  * Using `kubectl` - `kubectl apply -n komodor -k manifests/overlays/full`
  * Using `kustomize` - `kustomize build ./manifests/overlays/full | kubectl apply -n komodor -f -`