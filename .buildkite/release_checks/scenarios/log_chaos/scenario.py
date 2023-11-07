import asyncio
from scenario import Scenario


TEMPLATE = """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {name}
  namespace: {namespace}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: log-generator
  template:
    metadata:
      labels:
        app: log-generator
    spec:
      containers:
      - name: log-generator-container
        image: us-central1-docker.pkg.dev/playground-387315/loadtest/log-chaos:latest
        resources:
          limits:
            memory: "32Mi"
            cpu: "200m"

"""


class LogChaosScenario(Scenario):
    def __init__(self, kubeconfig):
        super().__init__("log-chaos", kubeconfig)
        self.namespace = "log-chaos"

    async def run(self):
        await self.create_namespace(self.namespace)

        for ds_number in range(1, 11):
            name = f"{self.name}-{ds_number}"
            self.log(f"Deploying {name}")
            await self.cmd(f"echo '{TEMPLATE.format(name=name, namespace=self.namespace)}' | {self.kubectl} apply -f -")
            await asyncio.sleep(10)

            if asyncio.current_task().cancelled():
                self.log('Cancellation detected, exiting...')
                return
        self.log(f"Finished deploying all {self.name} deployments")

    async def cleanup(self):
        self.log(f"Deleting namespace {self.namespace}")
        await self.cmd(f"{self.kubectl} delete namespace {self.namespace}")
