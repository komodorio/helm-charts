from command import cmd
from time import sleep
import os

version_updated = False
new_version = os.environ.get("NEW_VERSION")

cmd("helm repo add komodorio https://helm-charts.komodor.io")
cmd("helm repo list")

for x in range(1, 10):
    cmd("helm repo update", True)
    current_version = cmd("helm show all komodorio/k8s-watcher | grep 'version:' | cut -d ' ' -f 2")
    if current_version == new_version:
        print(f"Repository updated, current version is {current_version}, expected version is {new_version}")
        version_updated = True
        break
    print(f"Waiting for repository to be updated before checking, current version is {current_version}, expected version is {new_version}")
    sleep(10)

if not version_updated:
    print(f"Repository did not update ")
    exit(1)