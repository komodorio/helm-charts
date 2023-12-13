import os

from scenario import Scenario
import asyncio

API = os.getenv("AGENT_API_KEY", 'PLEASE_SET_API_KEY')
CLUSTER_NAME = os.getenv("CLUSTER_NAME", "komodor-agent-x-y-z-rc1")


class KomodorAgentScenario(Scenario):

    def __init__(self, kubeconfig):
        super().__init__("komodor-agent", kubeconfig)
        rc_chart_version = "--version " + os.getenv("CHART_VERSION")
        self.agents = [{"clusterName": CLUSTER_NAME, "agentVersion": rc_chart_version, "name": "komodor-agent-rc"},
                       {"clusterName": "komodor-agent-ga", "agentVersion": "", "name": "komodor-agent-ga"}]

    def generate_installation_cmd(self, cluster_name, chart_version, name):
        return (f"helm repo add komodorio https://helm-charts.komodor.io && "
                f"helm repo update && "
                f"{self.helm} upgrade --install {name} komodorio/komodor-agent "
                f"--set apiKey={API} "
                f"--set clusterName={cluster_name} "
                f"{chart_version} "
                f"--namespace {name} --create-namespace")

    async def install_komodor_agent(self, cluster_name, chart_version, name):
        self.log(f"Starting to deploy {name}")
        install_cmd = self.generate_installation_cmd(cluster_name, chart_version, name)

        output, exit_code = await self.cmd(install_cmd, silent_errors=True)
        if exit_code != 0:
            self.error(f"Failed to deploy:\n\tCMD: {install_cmd}\n\tOutput: {output}")
            raise Exception(f"Failed to deploy: {self.name}")

    async def run(self):
        await asyncio.sleep(120)  # Wait x seconds before deploying, to let other deployments to finish

        self.log("Starting to deploy")
        installation_tasks = []
        for agent in self.agents:
            installation_tasks.append(asyncio.create_task(self.install_komodor_agent(agent["clusterName"],
                                                                                     agent["agentVersion"],
                                                                                     agent["name"])))

        await asyncio.gather(*installation_tasks)
        self.log("Finished deploying")

    async def cleanup(self):
        self.log(f"Uninstalling {self.name}")
        uninstall_tasks = []
        for agent in self.agents:
            uninstall_tasks.append(asyncio.create_task(self.cmd(f"{self.helm} uninstall {agent['name']} -n {agent['name']}")))

        await asyncio.gather(*uninstall_tasks)

