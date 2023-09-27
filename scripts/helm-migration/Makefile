
APP_NAME = komodor-helm-migration
GO = go
DIST_DIR = ./dist
LDFLAGS = -ldflags "-X main.version=$(VERSION)"

.PHONY: all windows linux darwin clean check-version

all: check-version clean windows linux darwin

windows: check-version
	GOOS=windows GOARCH=amd64 $(GO) build $(LDFLAGS) -o $(DIST_DIR)/$(APP_NAME)_windows_amd64.exe

linux: check-version
	GOOS=linux GOARCH=amd64 $(GO) build $(LDFLAGS) -o $(DIST_DIR)/$(APP_NAME)_linux_amd64
	GOOS=linux GOARCH=arm64 $(GO) build $(LDFLAGS) -o $(DIST_DIR)/$(APP_NAME)_linux_arm64

darwin: check-version
	GOOS=darwin GOARCH=amd64 $(GO) build $(LDFLAGS) -o $(DIST_DIR)/$(APP_NAME)_darwin_amd64
	GOOS=darwin GOARCH=arm64 $(GO) build $(LDFLAGS) -o $(DIST_DIR)/$(APP_NAME)_darwin_arm64

clean:
	rm -rf $(DIST_DIR)/*

check-version:
ifndef VERSION
	$(error VERSION is not set. Use make all VERSION=x.y.z to set the version.)
endif
