import asyncio
import random
from scenario import Scenario

DEPLOYMENT_TEMPLATE = """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: edit-deployment-{index}
  namespace: {namespace}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: edit-deployment-{index}
  template:
    metadata:
      labels:
        app: edit-deployment-{index}
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
        self.num_of_deployments = 20
        self.interval = 60  # 1 minutes

    async def run(self):
        await self.create_namespace(self.namespace)

        for index in range(1, self.num_of_deployments + 1):  # Deploy X sample apps
            deployment_yaml = DEPLOYMENT_TEMPLATE.format(index=index, namespace=self.namespace)
            await self.cmd(f"echo '{deployment_yaml}' | {self.kubectl} apply -f -")
            await asyncio.sleep(1)  # Stagger deployments slightly

        update_actions = [
            {
                'command': lambda index: (
                    f"{self.kubectl} label deployment edit-deployment-{index} "
                    f"example-label=random-value-{random.randint(1, 100)} -n {self.namespace} --overwrite"
                ),
                'description': lambda index: f"Updating label for deployment edit-deployment-{index}"
            },
            {
                'command': lambda index: (
                    f"{self.kubectl} annotate deployment edit-deployment-{index} "
                    f"example-annotation=random-value-{random.randint(1, 100)} -n {self.namespace} --overwrite"
                ),
                'description': lambda index: f"Updating annotation for deployment edit-deployment-{index}"
            },
            {
                'command': lambda index: (
                    f"{self.kubectl} set env deployment/edit-deployment-{index} "
                    f"VAR=new_value_{random.randint(1, 100)} -n {self.namespace}"
                ),
                'description': lambda index: f"Updating environment variable for deployment edit-deployment-{index}"
            },
            {
                'command': lambda index: (
                    f"{self.kubectl} scale deployment edit-deployment-{index} "
                    f"--replicas={random.randint(1, 5)} -n {self.namespace}"
                ),
                'description': lambda index: f"Updating replica count for deployment edit-deployment-{index}"
            },
            {
                'command': lambda index: (
                    f"{self.kubectl} set image deployment/edit-deployment-{index} "
                    f"busybox-container={random.choice(['busybox:1.36', 'busybox:1.35', 'busybox:dummy'])} -n {self.namespace}"
                ),
                'description': lambda index: f"Updating image for deployment edit-deployment-{index}"
            },
        ]

        while True:
            if asyncio.current_task().cancelled():
                self.log('Cancellation detected, exiting...')
                return

            for index in range(1, self.num_of_deployments + 1):
                action = random.choice(update_actions)
                update_command = action['command'](index)
                self.log(action['description'](index))
                await self.cmd(update_command)
                await asyncio.sleep(0.5)

            self.log(f"Finished updating deployments, waiting {self.interval} seconds before starting again")
            await asyncio.sleep(self.interval)

    async def cleanup(self):
        self.log(f"Deleting namespace {self.namespace}")
        await self.cmd(f"{self.kubectl} delete namespace {self.namespace}")
