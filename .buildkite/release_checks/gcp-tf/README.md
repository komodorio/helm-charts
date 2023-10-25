# Setup GKE cluster to test agent behaviour before releasing it to prod

```bash
terraform workspace new <CLUSTER-NAME> || true
terraform workspace select <CLUSTER-NAME>
terraform apply -var="cluster_name=<CLUSTER-NAME>" -auto-approve
terraform output -raw kubeconfig > kubeconfig.yaml
```