# nginx (komodor-agent kubectl proxy)

Build assets for the nginx image used by `komodor-agent`'s `komodorKubectlProxy` component.

The image is multi-arch (`linux/amd64`, `linux/arm64`) and published to:

- `public.ecr.aws/komodor-public/nginx`
- `komodorio/nginx`

## Updating the nginx version

CI publishes the image automatically. To bump the version:

1. Edit `scripts/nginx/Dockerfile` — the `FROM nginx:` line. This is the single source of truth.
2. Edit `charts/komodor-agent/values.yaml` — `components.komodorKubectlProxy.image.tag` must match the Dockerfile tag.
3. Open a PR. CI runs `scripts/nginx/validate-version.sh` on every build and fails if the two files disagree. When the PR diff touches the Dockerfile, CI also runs `scripts/nginx/build-and-push.sh` and publishes the new image to both registries.

Prefer `-alpine*-slim` tags from the [official nginx repo on Docker Hub](https://hub.docker.com/_/nginx/tags).

## Local build (rarely needed — CI publishes for you)

Prerequisites:

- Docker with `buildx` enabled
- The `komo` CLI (used by the script to authenticate)

```bash
bash scripts/nginx/build-and-push.sh
```

The script reads the version from `Dockerfile`, runs `komo ci docker-login --hub-login true --ecr-login true` to authenticate against AWS ECR and Docker Hub, creates/uses a buildx builder named `nginx-multiarch`, then builds and pushes both tags.
