import asyncio
import random
from scenario import Scenario
from utils import cmd

DEPLOYMENT_TEMPLATE = """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mass-deployment-{index}
  namespace: {namespace}
spec:
  replicas: {replicas}
  selector:
    matchLabels:
      app: mass-deployment-{index}
  template:
    metadata:
      labels:
        app: mass-deployment-{index}
    spec:
      containers:
      - name: busybox
        image: busybox:1.36
        command: ["/bin/sh", "-c", "while true; do echo Hello Kubernetes; sleep 10; done"]
"""


class MassDeploymentScenario(Scenario):
    def __init__(self, kubeconfig):
        super().__init__("mass-deployment", kubeconfig)
        self.namespace = self.name
        self.num_deployments = 1_000
        self.interval = 60  # 1 minutes

    async def run(self):
        await self.create_namespace(self.namespace)

        # deploy 1000 deployments with 1-3 replica each
        self.log(f"Deploying {self.num_deployments} deployments")
        for index in range(1, self.num_deployments + 1):
            replicas = random.randint(1, 2)
            deployment_yaml = DEPLOYMENT_TEMPLATE.format(index=index, namespace=self.namespace, replicas=replicas)
            await cmd(f"echo '{deployment_yaml}' | {self.kubectl} apply -f -")
            await asyncio.sleep(0.1)
        self.log(f"Finished deploying all {self.num_deployments} deployments")

    async def cleanup(self):
        self.log(f"Deleting namespace {self.namespace}")
        await cmd(f"{self.kubectl} delete namespace {self.namespace}")
