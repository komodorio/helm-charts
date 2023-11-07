import sys

import yaml
import subprocess
from packaging import version

SCRIPT_DIR = sys.path[0]
RBAC_FILES = [
    "charts/komodor-agent/templates/clusterrole.yaml",
    "charts/komodor-agent/templates/network-mapper/cluster-role.yaml",
  ]


def run_cmd(cmd: list):
    result = subprocess.run(cmd, text=True, capture_output=True)
    if result.returncode != 0:
        print(f"Failed to run command: {cmd}")
        print(f"Output: {result.stdout}")
        sys.exit(1)
    return result.stdout.strip()


def get_tags():
    result = run_cmd(['git', 'tag', '--sort=committerdate', '-l', 'komodor-agent/*'])
    tags = result.split('\n')
    return [tag.split('/')[-1] for tag in tags if tag]


def find_latest_ga_tag(tags):
    for tag in reversed(tags):
        if '+rc' not in tag.lower():
            return tag
    return None


def find_rc_versions_after_last_ga(tags, last_ga):
    rc_versions = []
    found_last_ga = False
    for tag in tags:
        if tag == last_ga:
            found_last_ga = True
        elif found_last_ga and '+rc' in tag.lower():
            rc_versions.append(tag)
    return rc_versions


def find_rc_versions():
    tags = get_tags()
    latest_ga_tag = find_latest_ga_tag(tags)
    if latest_ga_tag:
        return find_rc_versions_after_last_ga(tags, latest_ga_tag)
    return None


def phase1():
    rc_versions = find_rc_versions()
    if not rc_versions:
        print("No RC versions found")
        sys.exit(1)

    with open(f'{SCRIPT_DIR}/pipeline_template_ph1.yaml', 'r') as f:
        pipeline_yaml = yaml.safe_load(f)

    for rc_version in rc_versions:
        pipeline_yaml['steps'][0]['fields'][0]['options'].append({'label': rc_version, 'value': rc_version})

    with open(f'{SCRIPT_DIR}/pipeline.yaml', 'w') as f:
        yaml.dump(pipeline_yaml, f)


def get_diff_files_from_ga_to_rc_tags(rc_version):
    tags = get_tags()
    latest_ga_tag = find_latest_ga_tag(tags)
    results = run_cmd(["git", "diff", "--name-only", f"komodor-agent/{rc_version}..komodor-agent/{latest_ga_tag}"])
    return results.split('\n')


def is_rback_changed(rc_version):
    diff_files = get_diff_files_from_ga_to_rc_tags(rc_version)
    return any(rback_file in diff_files for rback_file in RBAC_FILES)


def load_pipeline_template():
    with open(f'{SCRIPT_DIR}/pipeline_template_ph2.yaml', 'r') as f:
        return yaml.safe_load(f)


def update_pipeline_options(pipeline_yaml, is_rback_changed):
    pipeline_yaml['steps'][0]['fields'][0]['options'].extend([
        {'label': "Major", 'value': "major"},
        {'label': "Minor", 'value': "minor"}
    ])
    if is_rback_changed:
        pipeline_yaml['steps'][0]['fields'][0]['default'] = "minor"
        print("RBAC files were changed, defaulting to minor version change")
    else:
        pipeline_yaml['steps'][0]['fields'][0]['options'].append({'label': "Patch", 'value': "patch"})
        pipeline_yaml['steps'][0]['fields'][0]['default'] = "patch"


def save_pipeline(pipeline_yaml):
    with open(f'{SCRIPT_DIR}/pipeline.yaml', 'w') as f:
        yaml.dump(pipeline_yaml, f)


def phase2():
    rc_version = run_cmd(["buildkite-agent", "meta-data", "get", "rc-tag"])
    rback_changed = is_rback_changed(rc_version)
    pipeline_yaml = load_pipeline_template()
    update_pipeline_options(pipeline_yaml, rback_changed)
    save_pipeline(pipeline_yaml)


if __name__ == "__main__":
    if len(sys.argv) == 1 or sys.argv[1] == "phase1":
        phase1()
    else:
        phase2()
