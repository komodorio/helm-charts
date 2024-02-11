#!/bin/sh
set -e

check_prerequisites() {
    [ "$GITHUB_PAGES_REPO" ] || { echo "ERROR: GITHUB_PAGES_REPO is required"; exit 1; }
    [ -d "$HELM_CHARTS_SOURCE" ] || { echo "ERROR: Helm charts not found in $HELM_CHARTS_SOURCE"; exit 1; }
    [ "$BUILDKITE_BRANCH" ] || { echo "ERROR: BUILDKITE_BRANCH is required"; exit 1; }
}

setup_environment() {
    GITHUB_PAGES_BRANCH=${GITHUB_PAGES_BRANCH:-gh-pages}
    HELM_CHARTS_SOURCE=${HELM_CHARTS_SOURCE:-"$PWD/charts"}
    S3_BUCKET="helm-charts${BUILDKITE_PIPELINE_SLUG:+-test}"
}

configure_ssh() {
    mkdir -p "$HOME/.ssh"
    ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts"
}

clone_repo() {
    echo ">> Cloning $GITHUB_PAGES_BRANCH branch from $GITHUB_PAGES_REPO"
    rm -rf /tmp/helm/publish
    git clone -b "$GITHUB_PAGES_BRANCH" --depth 1 "git@github.com:$GITHUB_PAGES_REPO.git" /tmp/helm/publish
    cd /tmp/helm/publish
}

build_and_sync_charts() {
    echo '>> Building charts...'
    find "$HELM_CHARTS_SOURCE" -mindepth 1 -maxdepth 1 -type d | while read -r chart; do
        chart_name=$(basename "$chart")
        echo ">>> Processing $chart_name"
        process_chart "$chart" "$chart_name"
    done
}

process_chart() {
    chart=$1
    chart_name=$2
    chart_version=$(grep "^version:" "$chart/Chart.yaml" | awk '{print $2}')

    [ -f "$chart_name/$chart_name-$chart_version.tgz" ] && { echo ">>> $chart_version exists, skipping"; return; }

    helm lint "$chart"
    mkdir -p "$chart_name"
    helm package -d "$chart_name" "$chart"
    push_chart_to_docker_hub "$chart_name/$chart_name-$chart_version.tgz"
    sync_to_s3 "$chart_name"
}

push_chart_to_docker_hub() {
    tgz_file=$1
    echo ">> Pushing $tgz_file to Docker Hub"
    helm registry login "registry-1.docker.io" -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
    helm push "$tgz_file" oci://registry-1.docker.io/komodorio
}

sync_to_s3() {
    for domain in komodor.com komodor.io; do
        aws s3 sync "$1" "s3://${S3_BUCKET}.${domain}/$1"
    done
}

publish() {
    [ "$BUILDKITE_BRANCH" != "master" ] && { echo "Not master, not publishing"; return; }
    echo ">> Publishing to GitHub Pages"
    git config user.email "buildkite@users.noreply.github.com"
    git config user.name "Buildkite"
    git add .
    git commit -m "Published by Buildkite $BUILDKITE_BUILD_URL"
    git push origin "$GITHUB_PAGES_BRANCH"
}

main() {
    check_prerequisites
    setup_environment
    configure_ssh
    clone_repo
    build_and_sync_charts
    helm repo index .
    sync_to_s3 "."
    publish
}

main "$@"
