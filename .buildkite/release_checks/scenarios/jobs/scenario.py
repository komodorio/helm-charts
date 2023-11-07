import asyncio
import random
from scenario import Scenario

CONFIGMAP_TEMPLATE = """
apiVersion: v1
kind: ConfigMap
metadata:
  name: simulated-work-script
  namespace: {namespace}
data:
  simulated-work.sh: |
    #!/bin/sh

    # Generate a random duration between 10 seconds (10) and 15 minutes (900 seconds)
    DURATION=$((RANDOM % 891 + 10))

    echo "Starting simulated work for $DURATION seconds..."

    START_TIME=$(date +%s)
    END_TIME=$((START_TIME + DURATION))

    while [ $(date +%s) -lt $END_TIME ]; do
        REMAINING_TIME=$((END_TIME - $(date +%s)))
        echo "Working... $REMAINING_TIME seconds remaining"
        sleep $((RANDOM % 10 + 1))  # Sleep between 1 to 10 seconds before printing the next log message
    done

    echo "Simulated work completed."

"""

TEMPLATE = """
apiVersion: batch/v1
kind: Job
metadata:
  name: {name}
  namespace: {namespace}
spec:
  template:
    metadata:
      labels:
        app: simulated-work
    spec:
      containers:
      - name: busybox-container
        image: busybox
        command: ["/bin/sh", "/scripts/simulated-work.sh"]
        volumeMounts:
        - name: script-volume
          mountPath: /scripts
      volumes:
      - name: script-volume
        configMap:
          name: simulated-work-script
      restartPolicy: OnFailure

"""


class JobsScenario(Scenario):
    def __init__(self, kubeconfig):
        super().__init__("jobs", kubeconfig)
        self.namespace = "simulated-jobs"
        self.interval = 60

    async def run(self):
        await self.create_namespace(self.namespace)
        index = 0
        await self.cmd(f"echo '{CONFIGMAP_TEMPLATE.format(namespace=self.namespace)}' | {self.kubectl} apply -f -")
        while True:
            if asyncio.current_task().cancelled():
                self.log('Cancellation detected, exiting...')
                return
            for _ in range(5):  # Create 5 jobs
                index += 1
                name = f"simulated-job-id-{index}"
                self.log(f"Deploying {name}")
                await self.cmd(f"echo '{TEMPLATE.format(name=name, namespace=self.namespace)}' | {self.kubectl} apply -f -")
                await asyncio.sleep(10)

            self.log(f"Finished deploying jobs, waiting {self.interval} seconds before starting again")

            await asyncio.sleep(self.interval)

    async def cleanup(self):
        self.log(f"Deleting namespace {self.namespace}")
        await self.cmd(f"{self.kubectl} delete namespace {self.namespace}")
