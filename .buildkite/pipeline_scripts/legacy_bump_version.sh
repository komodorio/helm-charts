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

should_bump_version() {
    local chart=$1

    if [ "${BUILDKITE_TRIGGERED_FROM_BUILD_PIPELINE_SLUG}" = "${chart}" ]; then
        echo "Build was triggered from ${chart} pipeline, need to bump version."
        return
    fi

    git fetch --deepen=10

    # Find the last commit hash that doesn't contain [skip-ci] or [skip ci]
    local last_commit=$(git --no-pager log --skip=1 --pretty=format:'%H %s' | grep -v -E '\[skip[- ]ci\]' | head -n 1 | awk '{print $1}')

    # Check if any files have changed under the chart directory since that commit
    if git --no-pager diff --name-only "$last_commit" HEAD | grep -q "^charts/${chart}/"; then
        echo "At least one file under 'charts/${chart}' was changed, need to bump version."
        return
    else
        echo "No files under 'charts/${chart}' were changed."
        buildkite-agent meta-data set "$chart-version" "skip"
        exit 0
    fi
}


##################
# Main Execution #
##################
#configure_git

chart="k8s-watcher"

should_bump_version "$chart"
echo "here"
#app_version=$(get_app_version "$chart")
#update_chart_version "$chart" "$app_version"

#commit_and_push