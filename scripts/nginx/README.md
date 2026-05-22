# nginx (komodor-agent kubectl proxy)

Build assets for the nginx image used by `komodor-agent`'s `komodorKubectlProxy` component.

The image is multi-arch (`linux/amd64`, `linux/arm64`) and published to:

- `public.ecr.aws/komodor-public/nginx`
- `komodorio/nginx`

## Prerequisites

- Docker with `buildx` enabled
- Authenticated to AWS ECR and Docker Hub (e.g. `komo ci docker-login`)

## Build & push

```bash
bash scripts/nginx/build-and-push.sh
```

The script creates/uses a buildx builder named `nginx-multiarch`, then builds and pushes both tags in one step.

## Updating the nginx version

Update the version string in **two** places and keep them in sync:

1. `scripts/nginx/Dockerfile` — the `FROM nginx:` line (source of truth at build time; `build-and-push.sh` reads from here)
2. `charts/komodor-agent/values.yaml` — `components.komodorKubectlProxy.image.tag` (what the chart pulls)

Then run the build script to publish the new image, and open a PR with the two file changes.

Notes:

- Prefer `-alpine*-slim` tags from the [official nginx repo on Docker Hub](https://hub.docker.com/_/nginx/tags).
