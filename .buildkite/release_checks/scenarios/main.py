import os
import signal
import sys
import asyncio

from memory_leak.scenario import MemoryLeakScenario
from image_pull_backoff.scenario import ImagePullBackoffScenario
from bank_of_anthos.scenario import BankOfAnthosScenario
from daemonset.scenario import DaemonSetScenario
from komodor_agent.scenario import KomodorAgentScenario
from log_chaos.scenario import LogChaosScenario
from jobs.scenario import JobsScenario
from edit_deployment.scenario import EditDeploymentScenario
from mass_deployment.scenario import MassDeploymentScenario


async def main():
    kubeconfig_path = sys.argv[1]
    skip_cleanup = True if len(sys.argv) > 2 and sys.argv[2] == "--skip-cleanup" else False

    scenarios = [BankOfAnthosScenario(kubeconfig_path),
                 MemoryLeakScenario(kubeconfig_path),
                 ImagePullBackoffScenario(kubeconfig_path),
                 DaemonSetScenario(kubeconfig_path),
                 KomodorAgentScenario(kubeconfig_path),
                 LogChaosScenario(kubeconfig_path),
                 JobsScenario(kubeconfig_path),
                 EditDeploymentScenario(kubeconfig_path),
                 MassDeploymentScenario(kubeconfig_path)]

    tasks = [asyncio.create_task(scenario.run()) for scenario in scenarios]

    def signal_handler(sig, frame):
        print(f"Caught signal {sig}, cancelling tasks...")
        for task in tasks:
            task.cancel()

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        await asyncio.gather(*tasks)
    except asyncio.CancelledError:
        print("Tasks cancelled.")
    finally:
        # Perform cleanup for all scenarios
        if skip_cleanup:
            return
        await asyncio.gather(*(scenario.cleanup() for scenario in scenarios))


if __name__ == "__main__":
    CHART_VERSION = os.getenv("CHART_VERSION", None)
    if CHART_VERSION is None:
        print("CHART_VERSION is not set")
        sys.exit(1)

    asyncio.run(main())
