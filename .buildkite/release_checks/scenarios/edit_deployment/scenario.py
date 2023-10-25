import asyncio
import random
from scenario import Scenario
from utils import cmd

DEPLOYMENT_TEMPLATE = """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app-{index}
  namespace: {namespace}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sample-app-{index}
  template:
    metadata:
      labels:
        app: sample-app-{index}
    spec:
      containers:
      - name: busybox-container
        image: busybox
        command: ["/bin/sh", "-c", "while true; do echo Hello Kubernetes; sleep 10; done"]
        env:
        - name: VAR
          value: "initial_value"
"""


class EditDeploymentScenario(Scenario):
    def __init__(self, kubeconfig):
        super().__init__("edit-deployment", kubeconfig)
        self.namespace = self.name
        self.interval = 60  # 1 minutes

    async def run(self):
        await self.create_namespace(self.namespace)

        for index in range(1, 11):  # Deploy 10 sample apps
            deployment_yaml = DEPLOYMENT_TEMPLATE.format(index=index, namespace=self.namespace)
            await cmd(f"echo '{deployment_yaml}' | {self.kubectl} apply -f -")
            await asyncio.sleep(1)  # Stagger deployments slightly

        update_actions = [
            {
                'command': lambda index: (
                    f"{self.kubectl} label deployment sample-app-{index} "
                    f"example-label=random-value-{random.randint(1, 100)} -n {self.namespace} --overwrite"
                ),
                'description': lambda index: f"Updating label for deployment sample-app-{index}"
            },
            {
                'command': lambda index: (
                    f"{self.kubectl} annotate deployment sample-app-{index} "
                    f"example-annotation=random-value-{random.randint(1, 100)} -n {self.namespace} --overwrite"
                ),
                'description': lambda index: f"Updating annotation for deployment sample-app-{index}"
            },
            {
                'command': lambda index: (
                    f"{self.kubectl} set env deployment/sample-app-{index} "
                    f"VAR=new_value_{random.randint(1, 100)} -n {self.namespace}"
                ),
                'description': lambda index: f"Updating environment variable for deployment sample-app-{index}"
            },
            {
                'command': lambda index: (
                    f"{self.kubectl} scale deployment sample-app-{index} "
                    f"--replicas={random.randint(1, 5)} -n {self.namespace}"
                ),
                'description': lambda index: f"Updating replica count for deployment sample-app-{index}"
            },
        ]

        while True:
            if asyncio.current_task().cancelled():
                self.log('Cancellation detected, exiting...')
                return

            for index in range(1, 11):
                action = random.choice(update_actions)
                update_command = action['command'](index)
                self.log(action['description'](index))  # Log the action being performed
                await cmd(update_command)
                await asyncio.sleep(10)

            self.log(f"Finished updating deployments, waiting {self.interval} seconds before starting again")
            await asyncio.sleep(self.interval)

    async def cleanup(self):
        self.log(f"Deleting namespace {self.namespace}")
        await cmd(f"{self.kubectl} delete namespace {self.namespace}")
