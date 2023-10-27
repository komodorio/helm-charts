# Komodor-agent: GA release pipeline

This folder contains the pipeline for the GA release of the Komodor agent.
The `generate.py` script generates the pipeline yaml.
The reason we need to generate the pipeline is that we want to collect the list of RC versions that are candidates for the GA release.

## How it works
- In buildkite we have a minimal pipeline:
```yaml
steps:
- label: Generate pipeline
  commands:
  - git pull --tags
  - python3 .buildkite/release_checks/pipeline/generate.py
  - buildkite-agent pipeline upload < .buildkite/release_checks/pipeline/pipeline.yaml 
```
- The pipeline pull all the tags in the repo
- The execute the `generate.py` script, the script find the RC candidates and generate the pipeline yaml
- Then the pipeline upload the yaml to buildkite

