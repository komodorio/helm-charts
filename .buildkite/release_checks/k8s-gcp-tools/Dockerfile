FROM python:3.9-slim as builder

# Install curl, wget, bash, and unzip
RUN apt-get update && \
    apt-get install -y curl wget bash unzip && \
    rm -rf /var/lib/apt/lists/*

# Install gcloud SDK
RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/root/google-cloud-sdk/bin
RUN gcloud components install -q gke-gcloud-auth-plugin \
    && find /root/google-cloud-sdk -name "__pycache__" -type d -exec rm -rf {} + \
    && rm -rf /root/google-cloud-sdk/.install/.backup

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod +x get_helm.sh \
    && ./get_helm.sh \
    && rm get_helm.sh

# Install Terraform
ENV TERRAFORM_VERSION=1.6.2
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/terraform \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Verify installations
RUN kubectl version --client && helm version && gcloud version && terraform version

# New stage for the final image
FROM python:3.9-slim

RUN apt update && \
    apt install -y git && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /root/google-cloud-sdk /root/google-cloud-sdk
ENV PATH $PATH:/root/google-cloud-sdk/bin

WORKDIR /app
