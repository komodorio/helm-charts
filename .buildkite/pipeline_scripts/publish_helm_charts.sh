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

handle_legacy_cart() {
  set +e
  LEGACY_NEW_VERSION=$(buildkite-agent meta-data get "k8s-watcher-version")
  if [ $? -eq 0 ]; then
    set -e
    sed -i -e "s/version.*/version: $LEGACY_NEW_VERSION/g" charts/k8s-watcher/Chart.yaml
    make generate-kube
    git add charts/k8s-watcher

    git status
    git commit -m "[skip ci] update generated manifests"
    if [ $? -eq 0 ]; then
      # git tag "komodor-agent-${NEW_VERSION}"
      git tag "k8s-watcher-${LEGACY_NEW_VERSION}"
    else
      echo "Already up-to-date"
    fi

    git push -f && git push --tags || echo "Nothing to push!"
  else
    set -e
    echo "Skipping legacy chart"
  fi
}

configure_git

handle_legacy_cart

NEW_VERSION=$(buildkite-agent meta-data get "komodor-agent-version")
APP_VERSION=$(buildkite-agent meta-data get "agent-version")

# Chance the version of the komodor-agent chart *locally* and push it to the repo (not pushing this to the remote!!!)
sed -i -e "s/version.*/version: $NEW_VERSION/g" charts/komodor-agent/Chart.yaml

GITHUB_PAGES_REPO=${GITHUB_PAGES_REPO} ./publish.sh