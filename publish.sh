#!/bin/sh
set -ex

WORKING_DIRECTORY="$PWD"

[ "$GITHUB_PAGES_REPO" ] || {
  echo "ERROR: Environment variable GITHUB_PAGES_REPO is required"
  exit 1
}
[ -z "$GITHUB_PAGES_BRANCH" ] && GITHUB_PAGES_BRANCH=gh-pages
[ -z "$HELM_CHARTS_SOURCE" ] && HELM_CHARTS_SOURCE="$WORKING_DIRECTORY/charts"
[ -d "$HELM_CHARTS_SOURCE" ] || {
  echo "ERROR: Could not find Helm charts in $HELM_CHARTS_SOURCE"
  exit 1
}
[ "$BUILDKITE_BRANCH" ] || {
  echo "ERROR: Environment variable CURRENT_BRANCH is required"
  exit 1
}

echo "GITHUB_PAGES_REPO=$GITHUB_PAGES_REPO"
echo "GITHUB_PAGES_BRANCH=$GITHUB_PAGES_BRANCH"
echo "HELM_CHARTS_SOURCE=$HELM_CHARTS_SOURCE"
echo "BUILDKITE_BRANCH=$BUILDKITE_BRANCH"

echo ">> Checking out $GITHUB_PAGES_BRANCH branch from $GITHUB_PAGES_REPO"
rm -rf /tmp/helm/publish
mkdir -p /tmp/helm/publish && cd /tmp/helm/publish
mkdir -p "$HOME/.ssh"
ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts"
git clone -b "$GITHUB_PAGES_BRANCH" "git@github.com:$GITHUB_PAGES_REPO.git" .

echo '>> Building charts...'
find "$HELM_CHARTS_SOURCE" -mindepth 1 -maxdepth 1 -type d | while read chart; do
  chart_name="`basename "$chart"`"
  echo ">>> fetching chart $chart_name version"
  chart_version=$(cat $chart/Chart.yaml | grep -oE "version:\s[0-9]+\.[0-9]+\.[0-9]+" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")
  echo ">>> checking if version is already published"
  if [ -f "$chart_name/$chart_name-$chart_version.tgz" ]; then
    echo ">>> VERSION $chart_version ALREADY EXISTS! Skipping..."
    continue
  else
    echo ">>> chart version is valid, continuing..."
  fi
  echo ">>> helm lint $chart"
  helm lint "$chart"
  echo ">>> helm package -d $chart_name $chart"
  mkdir -p "$chart_name"
  helm package -d "$chart_name" "$chart"
done
echo '>>> helm repo index'
helm repo index .

if [ "$BUILDKITE_BRANCH" != "master" ]; then
  echo "Current branch is not master and do not publish"
  exit 0
fi

echo ">> Publishing to $GITHUB_PAGES_BRANCH branch of $GITHUB_PAGES_REPO"
git config user.email "buildkite@users.noreply.github.com"
git config user.name Buildkite
git add .
git status
git commit -m "Published by Buildkite $BUILDKITE_BUILD_URL"
git push origin "$GITHUB_PAGES_BRANCH"


echo ">> verifying chart version update"
helm repo add komodorio https://helm-charts.komodor.io
helm repo update
helm repo list

for x in {1..10}; do
    helm repo update
    CURRENT_VERSION=$(helm show all komodorio/k8s-watcher | grep "version:" | cut -d ' ' -f 2)
    if [ $CURRENT_VERSION = $NEW_VERSION ]; then
        echo "Repository updated, current version is $CURRENT_VERSION, expected version is $NEW_VERSION"
        VERSION_UPDATED=true
        break
    fi
    echo "Waiting for repository to be updated before checking, current version is $CURRENT_VERSION, expected version is $NEW_VERSION"
    sleep 10
done

if [ "$VERSION_UPDATED" = true ]; then
  echo "Version updated successfully"
else
  echo "Version not updated"
  exit 1
fi
