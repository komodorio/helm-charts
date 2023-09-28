# Variables
HELM_DOCS_VERSION := v1.11.2
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
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_S),Linux)
  OS := Linux
endif
ifeq ($(UNAME_S),Darwin)
  OS := Darwin
endif
ifeq ($(UNAME_M),x86_64)
  ARCH := amd64
endif
ifeq ($(UNAME_M),aarch64)
  ARCH := arm64
endif

# Targets
.PHONY: install-helm-docs
install-helm-docs:
	curl -L "https://github.com/norwoodj/helm-docs/releases/download/$(HELM_DOCS_VERSION)/helm-docs_$(OS)_$(ARCH).tar.gz" | tar -xz
	mv helm-docs /usr/local/bin/helm-docs

.PHONY: generate-readme
generate-readme:
	helm-docs $(HELM_DOCS_ARGS)

	@if [ ! -f "README.md" ]; then \
  		echo "README.md was not generated.\n Probably missing documentation of values.yaml.\n Please check helm-docs output."; \
  		exit 1; \
  	fi

.PHONY: validate-readme
validate-readme:
	helm-docs $(HELM_DOCS_ARGS) -d > /tmp/README.md

	@if [ ! -s "/tmp/README.md" ]; then \
  		echo "README.md was not generated. Probably missing documentation in values.yaml. Please check helm-docs output above."; \
  		exit 1; \
  	fi

	diff README.md /tmp/README.md || (echo "README.md is different from generated version.\n Run 'make generate-readme'." && exit 1)

.PHONY: all
all: install-helm-docs generate-readme validate-readme
