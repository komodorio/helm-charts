# Variables
HELM_DOCS_VERSION := 1.11.2
HELM_DOCS_ARGS := -s file \
                  -x \
                  -z=".*image.name.*" \
                  -z=".*image.tag.*" \
                  -z=".*resources.limits.*" \
                  -z=".*resources.requests.*" \
                  -y="proxy" \
                  -y="components.komodorAgent.watcher" \
                  -y="components.komodorAgent.supervisor" \
                  -y="components.komodorAgent.networkMapper" \
                  -y="components.komodorAgent.metrics" \
                  -y="components.komodorDaemon" \
                  -y="allowedResources"

# Determine OS and Arch for downloading helm-docs
OS := $(shell uname -s)
ARCH := $(shell uname -m)

# Targets
.PHONY: install-helm-docs
install-helm-docs:
	if ! helm-docs --version | grep -q $(HELM_DOCS_VERSION); then \
		curl -L "https://github.com/norwoodj/helm-docs/releases/download/v$(HELM_DOCS_VERSION)/helm-docs_$(OS)_$(ARCH).tar.gz" | tar -xz helm-docs; \
		mv helm-docs /usr/local/bin/helm-docs; \
	fi

.PHONY: generate-readme
generate-readme: install-helm-docs
	helm-docs $(HELM_DOCS_ARGS)

	@if [ ! -f "README.md" ]; then \
  		echo "README.md was not generated.\n Probably missing documentation of values.yaml.\n Please check helm-docs output."; \
  		exit 1; \
  	fi

.PHONY: validate-readme
validate-readme: install-helm-docs
	helm-docs $(HELM_DOCS_ARGS) -d > /tmp/README.md

	@if [ ! -s "/tmp/README.md" ]; then \
  		echo "README.md was not generated. Probably missing documentation in values.yaml. Please check helm-docs output above."; \
  		exit 1; \
  	fi

	diff README.md /tmp/README.md || (echo "README.md is different from generated version.\n Run 'make generate-readme'." && exit 1)

.PHONY: all
all: install-helm-docs generate-readme validate-readme
