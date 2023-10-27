Create a sample memory leak application

This app already built and is available in (GCP Registry)[https://console.cloud.google.com/artifacts/docker/playground-387315/us-central1/loadtest/leaker?orgonly=true&project=playground-387315&supportedpurview=project]

## How to build new version:
```bash
docker build . -t us-central1-docker.pkg.dev/playground-387315/loadtest/leaker:latest --platform linux/amd64
docker push us-central1-docker.pkg.dev/playground-387315/loadtest/leaker:latest

```

> NOTE: Make sure you are logged in to google playground project before pushing the image