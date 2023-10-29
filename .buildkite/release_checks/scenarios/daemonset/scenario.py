from scenario import Scenario
import asyncio

TEMPLATE = """
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: {name}
  labels:
    app: busybox
spec:
  selector:
    matchLabels:
      name: busybox-pod
  template:
    metadata:
      labels:
        name: busybox-pod
    spec:
      containers:
      - name: busybox-container
        image: busybox
        args:
        - /bin/sh
        - -c
        - while true; do echo Hello from the busybox daemonset; sleep 10; done
"""


class DaemonSetScenario(Scenario):

    def __init__(self, kubeconfig):
        super().__init__("Daemonset", kubeconfig)
        self.namespace = "daemons"

    async def run(self):
        await self.create_namespace(self.namespace)

        for ds_number in range(1, 11):
            name = f"daemonset-{ds_number}"
            self.log(f"Deploying {name}")
            await self.cmd(f"echo '{TEMPLATE.format(name=name)}' | {self.kubectl} apply -n {self.namespace} -f -")
            await asyncio.sleep(10)

            if asyncio.current_task().cancelled():
                self.log('Cancellation detected, exiting...')
                return
        self.log("Finished deploying daemonsets")

    async def cleanup(self):
        self.log(f"Deleting namespace {self.namespace}")
        await self.cmd(f"{self.kubectl} delete namespace {self.namespace}")

