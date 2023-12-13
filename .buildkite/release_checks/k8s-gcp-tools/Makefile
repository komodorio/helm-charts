
.PHONY k8s-gcp-tools:
k8s-gcp-tools:
	@echo "Build k8s-gcp-tools image"
	 docker build . -t 634375685434.dkr.ecr.us-east-1.amazonaws.com/k8s-gcp-tools --platform linux/amd64

.PHONY k8s-gcp-tools-push:
k8s-gcp-tools-push: k8s-gcp-tools
	@echo "Push k8s-gcp-tools image"
	 komo ci docker-login
	 docker push 634375685434.dkr.ecr.us-east-1.amazonaws.com/k8s-gcp-tools

