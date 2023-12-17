#!/usr/bin/env bash

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

generate_next_version() {
    local increment_type=$1
    local tags=$(git tag -l 'komodor-agent/*' | awk -F'/' '{print $NF}')
    local latest_tag=$(printf "%s\n" "${tags[@]}" | sort -V | tail -n 1 | tr '[:lower:]' '[:upper:]')

    local latest_ga_version=${latest_tag%+RC*}
    buildkite-agent meta-data set "komodor-agent-ga-version" "$latest_ga_version"

    if [[ ${increment_type} == "rc" ]]; then
        if [[ ${latest_tag} == *"+RC"* ]]; then
            local rc_part=${latest_tag##*+RC}
            local next_rc_number=$(( rc_part + 1 ))
            echo "${latest_ga_version}+RC${next_rc_number}"
        else
            echo "${latest_tag}+RC1"
        fi
    else
        local major=$(echo $latest_tag | awk -F'.' '{print $1}')
        local minor=$(echo $latest_tag | awk -F'.' '{print $2}')
        local patch=$(echo $latest_tag | awk -F'.' '{print $3}' | awk -F'+' '{print $1}')
        if [[ ${increment_type} == "major" ]]; then
            echo "$((major + 1)).0.0"
        elif [[ ${increment_type} == "minor" ]]; then
            echo "${major}.$((minor + 1)).0"
        elif [[ ${increment_type} == "patch" ]]; then
            echo "${major}.${minor}.$((patch + 1))"
        fi
    fi
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

update_chart_app_version() {
    local chart=$1
    local app_version=$2

    echo "Updating app version to $app_version"
    sed -i -e "s/appVersion.*/appVersion: $app_version/g" charts/$chart/Chart.yaml
    buildkite-agent meta-data set "agent-version" "$app_version"

    git add charts/$chart/Chart.yaml
}

get_increment_type() {
    increment_type=$(buildkite-agent meta-data get "version-type" --job ${PARENT_JOB_ID})
    if [ $? -eq 0 ]; then
        echo $increment_type
        return
    fi
    echo rc
}

increment_version_commit_and_push() {
  increment_type=$(get_increment_type)
  new_version=$(generate_next_version "$increment_type")
  buildkite-agent meta-data set "$chart-version" "$new_version"

  git commit -m "[skip ci] update Chart.yaml" || echo "Already up-to-date"
  git push -f || echo "Nothing to push!"

  git tag "komodor-agent/$new_version"
  git push --tags || echo "No tags to push"
}


update_readme() {
    pushd charts/komodor-agent && make generate-readme && popd
    git add charts/komodor-agent/README.md || echo "Nothing to add"
}


##################
# Main Execution #
##################
main () {
  configure_git

  chart="komodor-agent"
  app_version=$(get_app_version "$chart")
  update_chart_app_version "$chart" "$app_version"

  update_readme
  increment_version_commit_and_push

}

# This condition ensures main is only executed when the script is run, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -ex
  main "$@"
fi