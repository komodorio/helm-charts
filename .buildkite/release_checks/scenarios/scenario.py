from utils import cmd
from abc import ABC


class Scenario(ABC):
    KUBECTL = "kubectl --kubeconfig={kubeconfig_path}"

    NS_TEMPLATE = """
apiVersion: v1
kind: Namespace
metadata:
  name: {namespace}
"""

    def __init__(self, name: str, kubeconfig_path: str):
        self.name = name
        self.kubectl = self.KUBECTL.format(kubeconfig_path=kubeconfig_path)
        self.helm = f"helm --kubeconfig={kubeconfig_path}"

    async def create_namespace(self, namespace: str):
        self.log(f"Creating namespace {namespace}")
        ns = self.NS_TEMPLATE.format(namespace=namespace)
        await self.cmd(f"echo '{ns}' | {self.kubectl} apply -f -")
        
    async def run(self):
        raise NotImplementedError

    async def cleanup(self):
        raise NotImplementedError

    def log(self, msg: str):
        print(f"[{self.name}] {msg}")

    def error(self, msg: str):
        print(f"[{self.name}] ERROR: {msg}")

    async def cmd(self, command, silent_output=True, silent_errors=False):
        output, ecode = await cmd(command, silent_output)
        if silent_errors:
            return output, ecode

        if ecode != 0:
            self.error(f"An error has occurred during command execution.\n\tcmd: {command}\n\n\t{output}")
