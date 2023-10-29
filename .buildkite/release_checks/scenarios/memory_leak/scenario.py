import asyncio
from scenario import Scenario
import random

NAMESPACE = "leaking"

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
      app: memory-leak
  template:
    metadata:
      labels:
        app: memory-leak
    spec:
      containers:
      - name: memory-leak
        image: us-central1-docker.pkg.dev/playground-387315/loadtest/leaker:latest
        env:
        - name: MEMORY_LIMIT
          value: "{mem}"
        - name: PYTHONUNBUFFERED
          value: "1"
        resources:
          requests:
            memory: "{mem}Mi"
            cpu: "50m"
          limits:
            memory: "{mem}Mi"
            cpu: "50m"
"""


class MemoryLeakScenario(Scenario):
    def __init__(self, kubeconfig):
        super().__init__("memory leak scenario", kubeconfig)
        self.namespace = "leaking"
        self.replicas = 10

    async def deploy(self, ):
        mem_to_allocate = random.randint(32, 75)
        name = f"memory-leak-{mem_to_allocate}mb"

        updated_template = TEMPLATE.format(name=name, mem=mem_to_allocate, namespace=NAMESPACE)
        await self.cmd(f"echo '{updated_template}' | {self.kubectl} apply -f -")
    
    async def run(self):
        await self.create_namespace(self.namespace)
        for replica in range(1, self.replicas):
            self.log(f"Deploying replica: {replica}")
            await self.deploy()
            await asyncio.sleep(1 * 60)

            if asyncio.current_task().cancelled():
                self.log('Cancellation detected, exiting...')
                return

        self.log(f"Deployed {self.replicas} replicas")

    async def cleanup(self):
        self.log(f"Deleting namespace {NAMESPACE}")
        await self.cmd(f"{self.kubectl} delete namespace {NAMESPACE}")
