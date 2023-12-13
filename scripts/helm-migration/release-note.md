We are excited to announce a new release of the Komodor-Helm-Migration tool,
which facilitates a seamless transition from the old Helm chart, k8s-watcher, to our new and improved Helm chart, komodor-agent.

## Usage

To utilize this tool, execute the following command:

```bash
komodor-helm-migration_<OS>_<ARCH> [options]
```

### Options:

- `-o string`: Specify the output values file. Default is `komodor_watcher_values.yaml`.
- `-r string`: Specify the release name. Default is `k8s-watcher`.
- `-v`: Show the version of the tool and exit.

## What does the tool do?

Upon execution, this tool will generate a values file that can be used with the new `komodor-agent` Helm chart. 
Additionally, it provides step-by-step instructions on uninstalling the old `k8s-watcher` chart and installing the new `komodor-agent` chart, ensuring a smooth migration.

## Download

Grab the latest release from the assets section below to get started!
