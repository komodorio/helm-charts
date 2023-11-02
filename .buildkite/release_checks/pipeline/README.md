# Komodor-agent: GA release pipeline

This folder contains the pipeline for the GA release of the Komodor agent.
The `generate.py` script generates the pipeline yaml in two phases.
The reason we need to generate the pipeline is that we want to collect the list of RC versions that are candidates for the GA release.
Then based on the selected RC version we will check if RBAC files were changed and suggest the version increment type

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
- At the end of the above pipeline, we have a step that execute the `generate.py` script again with `phase2` argument
  <br>This time, the script will check if RBAC files were changed between the last GA version and the current RC version.
  <br>In case RBAC files were changed, the script will suggest to increase the version by `minor` or `major` version.
