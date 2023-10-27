# GKE Terraform 

Use this terraform to setup a GKE cluster, Use this cluster to test agent behaviour and stability before releasing it as GA version

## How to use it manually

### Prerequisites: 
* Google service account key file named `sa.json` in this folder.
  You can use the key that is in the parameters store
  to get the file using CLI:
  * Login to aws with MFA
  * `aws ssm get-parameter --with-decryption --name /app/ci/gcp/AGENT_RELEASE_SA_KEY > sa.json`

### Running terraform:

Use the following commands to install / upgrade GKE cluster

```bash
terraform workspace new <CLUSTER-NAME> || true
terraform workspace select <CLUSTER-NAME>
terraform apply -var="cluster_name=<CLUSTER-NAME>" -auto-approve
```

To get the cluster `kubeconfig` file use the following command:
```bash
terraform output -raw kubeconfig > kubeconfig.yaml
```

To remove a cluster use the following commands:

```bash
terraform destroy -auto-approve -var="cluster_name=<CLUSTER-NAME>"
```