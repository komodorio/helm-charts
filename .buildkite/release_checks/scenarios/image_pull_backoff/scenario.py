import asyncio
from scenario import Scenario


TEMPLATE = """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-pull-backoff
  namespace: image-pull-backoff
spec:
  replicas: 10
  selector:
    matchLabels:
      app: image-pull-backoff
  template:
    metadata:
      labels:
        app: image-pull-backoff
    spec:
      containers:
      - name: image-pull-backoff
        image: us-central1-docker.pkg.dev/playground-387315/loadtest/no-image:latest
        resources:
          requests:
            memory: "10Mi"
            cpu: "10m"
          limits:
            memory: "10Mi"
            cpu: "10m"
"""


class ImagePullBackoffScenario(Scenario):
    def __init__(self, kubeconfig):
        super().__init__("image pull backoff", kubeconfig)
        self.namespace = "image-pull-backoff"

    async def run(self):
        while True:
            self.log(f"Starting to deploy")
            await self.create_namespace(self.namespace)
            await self.cmd(f"echo '{TEMPLATE}' | {self.kubectl} apply -f -", silent_output=True)
            self.log("Deployed")

            for _ in range(30): # Simulate 300 seconds sleep
                await asyncio.sleep(10)
                if asyncio.current_task().cancelled():
                    self.log('Cancellation detected, exiting...')
                    return

            self.log(f"Deleting namespace {self.namespace}")
            await self.cmd(f"{self.kubectl} delete namespace {self.namespace}")

            await asyncio.sleep(60)

    async def cleanup(self):
        self.log(f"Deleting namespace {self.namespace}")
        await self.cmd(f"{self.kubectl} delete namespace {self.namespace}")
