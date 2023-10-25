
To run this checks we are using GKE (Google Kubernetes Engine) cluster.
In order to communicate with the cluster we need to use gcloud tool.
to do so you can use the Dockerfile in this directory to build an image with the gcloud tool installed.

to use this image you need to run the following command:
```bash
docker run -it --rm -v $(pwd)/sa.json:/sa.json -v $(pwd)/kubeconfig.json:/root/.kube/config 634375685434.dkr.ecr.us-east-1.amazonaws.com/k8s-gcp-tools
```