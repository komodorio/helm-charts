from scenario import Scenario
import os


class BankOfAnthosScenario(Scenario):
    BANK_GIT_URL = "git@github.com:GoogleCloudPlatform/bank-of-anthos.git"

    def __init__(self, kubeconfig):
        super().__init__("bank-of-anthos", kubeconfig)
        self.my_path = os.path.dirname(os.path.realpath(__file__))

    async def run(self):
        self.log("Starting to deploy")
        await self.cmd(f"git clone {self.BANK_GIT_URL} {self.my_path}/bank-of-anthos")
        await self.cmd(f"{self.kubectl} apply -f {self.my_path}/bank-of-anthos/extras/jwt/jwt-secret.yaml")
        await self.cmd(f"{self.kubectl} apply -f {self.my_path}/bank-of-anthos/kubernetes-manifests")

        self.log("Finished deploying")

    async def cleanup(self):
        self.log("Uninstalling")
        await self.cmd(f"{self.kubectl} delete -f {self.my_path}/bank-of-anthos/kubernetes-manifests")
        await self.cmd(f"{self.kubectl} delete -f {self.my_path}/bank-of-anthos/extras/jwt/jwt-secret.yaml")

