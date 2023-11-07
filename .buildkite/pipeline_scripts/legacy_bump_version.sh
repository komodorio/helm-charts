#!/usr/bin/env bash
set -ex

get_current_version() {
    grep 'version:' charts/"${1}"/Chart.yaml | awk '{print $2}'
}

increment_version() {
    echo "${1}" | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g'
}

configure_git() {
    git config user.email buildkite@users.noreply.github.com
    git config user.name buildkite
    git fetch --tags
    git checkout master
}

get_app_version() {
    local chart=$1
    ver=$(buildkite-agent meta-data get "version" --job ${PARENT_JOB_ID})
     if [ $? -eq 0 ]; then
        echo $ver
        return
     fi
     grep 'appVersion:' charts/$chart/Chart.yaml | awk '{print $2}'
}

update_chart_version() {
    local chart=$1
    local app_version=$2

    echo "Updating app version to $app_version"
    sed -i -e "s/appVersion.*/appVersion: $app_version/g" charts/$chart/Chart.yaml
    buildkite-agent meta-data set "agent-version" "$app_version"

    local current_version=$(get_current_version "${chart}")
    local new_version=$(increment_version "$current_version")

    echo "Updating chart '$chart' version from $current_version to $new_version"
    sed -i -e "s/$current_version/$new_version/g" charts/$chart/Chart.yaml
    git add charts/$chart/Chart.yaml
    buildkite-agent meta-data set "$chart-version" "$new_version"
}

commit_and_push() {
    git commit -m "[skip ci] increment chart versions" || echo "Already up-to-date"
    git push -f || echo "Nothing to push!"
}

##################
# Main Execution #
##################
configure_git

chart="k8s-watcher"

app_version=$(get_app_version "$chart")
update_chart_version "$chart" "$app_version"

commit_and_push