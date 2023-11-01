import os

from scenario import Scenario
import asyncio

API = os.getenv("AGENT_API_KEY", '36d9e750-f50c-442d-ba32-1cec72a04d4c')
CLUSTER_NAME = os.getenv("CLUSTER_NAME", "komodor-agent-x-y-z-rc1")


class KomodorAgentScenario(Scenario):

    def __init__(self, kubeconfig):
        super().__init__("komodor-agent", kubeconfig)

    def generate_installation_cmd(self, cluster_name, chart_version, name):
        return (f"helm repo add komodorio https://helm-charts.komodor.io && "
                f"helm repo update && "
                f"{self.helm} upgrade --install {name} komodorio/komodor-agent "
                f"--set apiKey={API} "
                f"--set clusterName={cluster_name} "
                f"{chart_version} "
                f"--namespace {name} --create-namespace")

    async def install_komodor_agent(self, cluster_name, chart_version, namespace):
        install_cmd = self.generate_installation_cmd(cluster_name, chart_version, namespace)

        output, exit_code = await self.cmd(install_cmd, silent_errors=True)
        if exit_code != 0:
            self.error(f"Failed to deploy:\n\tCMD: {install_cmd}\n\tOutput: {output}")
            raise Exception(f"Failed to deploy: {self.name}")

    async def run(self):
        #await asyncio.sleep(120)  # Wait x seconds before deploying, to let other deployments to finish
        rc_chart_version = "--version " + os.getenv("CHART_VERSION")
        self.log("Starting to deploy")
        rc_agent_task = asyncio.create_task(self.install_komodor_agent(CLUSTER_NAME,
                                                                       rc_chart_version,
                                                                       "komodor-agent-rc"))
        gc_agent_task = asyncio.create_task(self.install_komodor_agent("komodor-agent-ga",
                                                                       "",
                                                                       "komodor-agent-ga"))

        await asyncio.gather(rc_agent_task, gc_agent_task)
        self.log("Finished deploying")

    async def cleanup(self):
        self.log(f"Uninstalling {self.name}")
        await self.cmd(f"{self.helm} uninstall komodor-agent")

