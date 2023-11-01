import os

from scenario import Scenario
import asyncio

API = os.getenv("AGENT_API_KEY", '36d9e750-f50c-442d-ba32-1cec72a04d4c')
CLUSTER_NAME = os.getenv("CLUSTER_NAME", "agent-release-checks")


class KomodorAgentScenario(Scenario):

    def __init__(self, kubeconfig):
        super().__init__("komodor-agent", kubeconfig)

    async def run(self):
        await asyncio.sleep(120)  # Wait x seconds before deploying, to let other deployments to finish
        CHART_VERSION = os.getenv("CHART_VERSION")
        self.log("Starting to deploy")
        install_cmd = (f"helm repo add komodorio https://helm-charts.komodor.io && "
                       f"helm repo update && "
                       f"{self.helm} upgrade --install komodor-agent komodorio/komodor-agent "
                       f"--set apiKey={API} "
                       f"--set clusterName={CLUSTER_NAME}"
                       f"--version {CHART_VERSION}")

        output, exit_code = await self.cmd(install_cmd, silent_errors=True)
        if exit_code != 0:
            self.error(f"Failed to deploy: {output}")
            raise Exception(f"Failed to deploy: {self.name}")
        self.log("Finished deploying")

    async def cleanup(self):
        self.log(f"Uninstalling {self.name}")
        await self.cmd(f"{self.helm} uninstall komodor-agent")

