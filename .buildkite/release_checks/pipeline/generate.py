import sys

import yaml
import subprocess
from packaging import version

SCRIPT_DIR = sys.path[0]


def get_tags():
    result = subprocess.run(['git', 'tag', '-l', 'komodor-agent/*'], text=True, capture_output=True)
    tags = result.stdout.strip().split('\n')
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
    tags = sorted(get_tags(), key=version.parse)
    latest_ga_tag = find_latest_ga_tag(tags)
    if latest_ga_tag:
        return find_rc_versions_after_last_ga(tags, latest_ga_tag)
    return None


def main():
    rc_versions = find_rc_versions()
    if not rc_versions:
        print("No RC versions found")
        sys.exit(1)

    # Read pipeline yaml file
    with open(f'{SCRIPT_DIR}/pipeline_template.yaml', 'r') as f:
        pipeline_yaml = yaml.safe_load(f)

    for rc_version in rc_versions:
        pipeline_yaml['steps'][0]['fields'][0]['options'].append({'label': rc_version, 'value': rc_version})

    with open(f'{SCRIPT_DIR}/pipeline.yaml', 'w') as f:
        yaml.dump(pipeline_yaml, f)


if __name__ == "__main__":
    main()
