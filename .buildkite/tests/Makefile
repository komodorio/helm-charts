# Variables
VENV_NAME = .venv
VENV_ACTIVATE = . $(VENV_NAME)/bin/activate
KIND_VERSION = v0.20.0
KIND_URL_BASE = https://kind.sigs.k8s.io/dl/$(KIND_VERSION)
KIND_BINARY = ./kind

# Targets
.PHONY: install-kind setup-venv test-all basic_test values_base_test values_capabilities_events_test values_capabilities_proxy_test \
	values_capabilities_test values_components_test

install-kind:
	@if ! command -v kind &> /dev/null ; then \
		OS=$(shell uname -s) ; \
		ARCH=$(shell uname -m) ; \
		if [ $$OS = Linux ]; then \
			[ $$ARCH = x86_64 ] && curl -Lo $(KIND_BINARY) $(KIND_URL_BASE)/kind-linux-amd64 ; \
			[ $$ARCH = aarch64 ] && curl -Lo $(KIND_BINARY) $(KIND_URL_BASE)/kind-linux-arm64 ; \
		elif [ $$OS = Darwin ]; then \
			[ $$ARCH = x86_64 ] && curl -Lo $(KIND_BINARY) $(KIND_URL_BASE)/kind-darwin-amd64 ; \
			[ $$ARCH = arm64 ] && curl -Lo $(KIND_BINARY) $(KIND_URL_BASE)/kind-darwin-arm64 ; \
		fi ; \
		chmod +x $(KIND_BINARY) ; \
		sudo mv $(KIND_BINARY) /usr/local/bin/kind ; \
	else \
		echo "kind is already installed" ; \
	fi

setup-venv:
	python3 -m venv $(VENV_NAME)
	$(VENV_ACTIVATE) ; pip install -r requirements.txt

test-all: setup-venv install-kind
	$(VENV_ACTIVATE) ; pytest

basic_test: setup-venv install-kind
	$(VENV_ACTIVATE) ; pytest basic_test.py

values_base_test: setup-venv install-kind
	$(VENV_ACTIVATE) ; pytest values_base_test.py

values_capabilities_events_test: setup-venv install-kind
	$(VENV_ACTIVATE) ; pytest values_capabilities_events_test.py

values_capabilities_proxy_test: setup-venv install-kind
	$(VENV_ACTIVATE) ; pytest values_capabilities_proxy_test.py

values_capabilities_test: setup-venv install-kind
	$(VENV_ACTIVATE) ; pytest values_capabilities_test.py

values_components_test: setup-venv install-kind
	$(VENV_ACTIVATE) ; pytest values_components_test.py
