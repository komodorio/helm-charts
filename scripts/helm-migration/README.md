
# Komodor Helm Migration

## Overview

This Go application is designed to automate the process of migrating Komodor k8s-watcher Helm chart values to a new structure. It fetches the existing Helm values for a given release, flattens the nested YAML, and then maps the old keys to new keys based on a predefined mapping.

## Prerequisites

- Go 1.16 or higher
- Helm 3.x
- Access to a Kubernetes cluster
- GNU Make

## How to Build

The application can be built for multiple platforms: Windows, Linux, and macOS (Darwin), targeting both `amd64` and `arm64` architectures.

1. Clone the repository:
2. Navigate to the project directory:

    ```bash
    cd scripts/helm-migration
    ```

3. Run the Makefile to build the application:

    ```bash
    make all VERSION=<VERSION>
    ```

This will produce the binaries in a `dist` directory. You can also build for specific platforms:

- For Windows:

    ```bash
    make windows VERSION=<VERSION>
    ```

- For Linux:

    ```bash
    make linux VERSION=<VERSION>
    ```

- For macOS (Darwin):

    ```bash
    make darwin VERSION=<VERSION>
    ```

To clean the `dist` directory, you can run:

```bash
make clean
```

## Usage

Run the application with the following command:

```bash
cd dist
./komodor-helm-migration_<OS>_<ARCH> -o [OUTPUT_FILE]
```

- `OUTPUT_FILE`: Optional. The name of the output file where the new Helm values will be saved. Default is `komodor_watcher_values.yaml`.

The application will:

1. Identify the namespace where the Helm release `k8s-watcher` is installed.
2. Fetch the existing Helm values for the release.
3. Map the old values to the new structure based on the predefined mapping.
4. Save the new values to the specified output file.
5. Print a Helm installation command using the new values file.
