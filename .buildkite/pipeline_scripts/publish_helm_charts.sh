#!/usr/bin/env bash
set -ex

SCRIPT_DIR=$(dirname $(realpath "$0"))
source "$SCRIPT_DIR/common.sh"

get_branch_to_release() {
    set +e
    branch_to_release=$(buildkite-agent meta-data get "rc-tag" --job ${PARENT_JOB_ID})
    if [ $? -ne 0 ]; then
        branch_to_release="master"
    else
        branch_to_release="komodor-agent/${branch_to_release}"
    fi
    set -e
    echo $branch_to_release
}

configure_git() {
    git config user.email buildkite@users.noreply.github.com
    git config user.name buildkite
    git fetch --tags

    branch_to_checkout=$(get_branch_to_release)
    git checkout "${branch_to_checkout}"
}

configure_git

NEW_VERSION=$(buildkite-agent meta-data get "komodor-agent-version")
APP_VERSION=$(buildkite-agent meta-data get "agent-version")

# Chance the version of the komodor-agent chart *locally* and push it to the repo (not pushing this to the remote!!!)
sed -i -e "s/version.*/version: $NEW_VERSION/g" charts/komodor-agent/Chart.yaml

GITHUB_PAGES_REPO=${GITHUB_PAGES_REPO} ./publish.sh