import sys
import subprocess
import time

def run_cmd(command, expect_output=False):
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    if result.returncode != 0:
        raise Exception(f"Command failed: {command}\n{result.stderr}")
    return result.stdout.strip() if expect_output else ""

def get_current_version(chart, new_version, is_rc):
    if is_rc:
        search_command = f"helm search repo komodorio/{chart} --versions | grep '{new_version}' | awk '{{ print $2 }}'"
    else:
        search_command = f"helm show chart komodorio/{chart} | grep 'version:' | cut -d ' ' -f 2"
    return run_cmd(search_command, expect_output=True)


def main(chart, new_version):
    run_cmd("helm repo add komodorio https://helm-charts.komodor.io")
    run_cmd("helm repo update")

    is_rc = "+RC" in new_version.upper()
    version_updated = False

    for _ in range(10):
        current_version = get_current_version(chart, new_version, is_rc)
        if current_version == new_version:
            print(f"Chart updated, version {new_version} is available")
            version_updated = True
            break
        print(f"Waiting for chart to be updated, expected version is {new_version}, current version is {current_version}")
        time.sleep(10)

    if not version_updated:
        print(f"Chart '{chart}' not updated, current version is {current_version}, expected version is {new_version}")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: script.py <chart>")
        sys.exit(1)
    chart = sys.argv[1]
    new_version = run_cmd(f'buildkite-agent meta-data get "{chart}-version"', True)
    main(chart, new_version)
