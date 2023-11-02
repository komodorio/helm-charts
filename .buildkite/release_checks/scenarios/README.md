# Release Check Scenarios

This folder contains a collection of scenarios for testing release of Komodor-agent as GA.

## Scenarios

- `bank-of-anthos`: a sample HTTP-based web app that simulates a bank's payment processing network.
- `daemonset`: Deploy X daemonsets
- `edit-deployment`: Deploy x deployments and change every ~minute something in the deployment
- `image-pull-backoff`: Deploy x deployments with an image that doesn't exist
- `jobs`: Deploy x jobs every ~minute, the jobs will run for a random time between few seconds to 15 minutes
- `komodor-agent`: Deploy the komodor-agent
- `log-chaos`: Deploy x deployments, each container will generate many logs.
- `mass-deployment`: Deploy x deployments.
- `memory-leak`: Deploy x deployments with random memory limit, each container has a leak and it will get OOMKill when reaching the deployment limit.

## Running Scenarios

To run the scenarios, follow these steps:

### Prerequisites:
1. Cluster `kubeconfig` file, see how to generate it from [terraform](../gcp-tf/README.md#running-terraform) 
2. Environment variable `CHART_VERSION` with chart version to install. Example: `CHART_VERSION=x.y.z+RC1`
3. Environment variable `AGENT_API_KEY`.

### Running the scenarios script
1. Use the following command to run the scenarios:
```bash
python3 main.py <kubeconfig path> 
```
## Adding a new scenario

To add a new scenario, follow these steps:
1. Create a new folder with the scenario name.
2. Create a `__init__.py` and `scenario.py` files in the new folder.
3. Create a class that inherits from `Scenario` and implement the `run` and `cleanup` methods (see other scenarios as reference).
4. Add the new scenario to the `scenarios` list in `main.py`.