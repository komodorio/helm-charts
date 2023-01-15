from command import cmd
from time import sleep
import os

version_updated = False
new_version = cmd('buildkite-agent meta-data get "version"', True)

cmd("helm repo add komodorio https://helm-charts.komodor.io")
cmd("helm repo list")

for x in range(1, 10):
    cmd("helm repo update", True)
    current_version = cmd("helm show all komodorio/k8s-watcher | grep 'version:' | cut -d ' ' -f 2", True)
    if current_version == new_version:
        print(f"Chart updated, current version is {current_version}, expected version is {new_version}")
        version_updated = True
        break
    print(f"Waiting for chart to be updated before checking, current version is {current_version}, expected version is {new_version}")
    sleep(10)

if not version_updated:
    print(f"chart not updated, current version is {current_version}, expected version is {new_version}")
    exit(1)