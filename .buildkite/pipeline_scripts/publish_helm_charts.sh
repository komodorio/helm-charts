#!/usr/bin/env bash
set -ex

SCRIPT_DIR=$(dirname $(realpath "$0"))
source "$SCRIPT_DIR/common.sh"

configure_git() {
  git config user.email buildkite@users.noreply.github.com
  git config user.name buildkite
  git checkout master
}

configure_git

LEGACY_NEW_VERSION=$(buildkite-agent meta-data get "k8s-watcher-version")
NEW_VERSION=$(buildkite-agent meta-data get "komodor-agent-version")
APP_VERSION=$(buildkite-agent meta-data get "agent-version")

sed -i -e "s/version.*/version: $LEGACY_NEW_VERSION/g" charts/k8s-watcher/Chart.yaml
sed -i -e "s/version.*/version: $NEW_VERSION/g" charts/komodor-agent/Chart.yaml
make generate-kube

git add charts/k8s-watcher
# git add charts/komodor-agent

git status
git commit -m "[skip ci] update generated manifests"
if [ $? -eq 0 ]; then
  # git tag "komodor-agent-${NEW_VERSION}"
  git tag "k8s-watcher-${LEGACY_NEW_VERSION}"
else
  echo "Already up-to-date"
fi

git push -f && git push --tags || echo "Nothing to push!"
GITHUB_PAGES_REPO=komodorio/helm-charts ./publish.sh