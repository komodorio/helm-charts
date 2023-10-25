# Simple log chaos app
This app generate massive amount of random logs
<br>

This app already built and is available in (GCP Registry)[https://console.cloud.google.com/artifacts/docker/playground-387315/us-central1/loadtest/log-chaos?orgonly=true&project=playground-387315&supportedpurview=project]

## How to build new version:
```bash
docker build . -t us-central1-docker.pkg.dev/playground-387315/loadtest/log-chaos:latest --platform linux/amd64
docker push us-central1-docker.pkg.dev/playground-387315/loadtest/log-chaos:latest

```

> NOTE: Make sure you are logged in to google playground project before pushing the image