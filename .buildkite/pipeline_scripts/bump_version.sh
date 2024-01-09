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

extract_version_parts() {
    local version=$1
    local major=$(echo $version | awk -F'.' '{print $1}')
    local minor=$(echo $version | awk -F'.' '{print $2}')
    local patch=$(echo $version | awk -F'.' '{print $3}' | awk -F'-' '{print $1}')
    echo $major $minor $patch
}

increment_version() {
    local version=$1
    local increment_type=$2
    read major minor patch <<< $(extract_version_parts $version)

    case $increment_type in
        major)
            echo "$((major + 1)).0.0"
            ;;
        minor)
            echo "${major}.$((minor + 1)).0"
            ;;
        patch)
            echo "${major}.${minor}.$((patch + 1))"
            ;;
        *)
            echo "Unknown increment type: $increment_type" >&2
            return 2
            ;;
    esac
}

generate_next_version() {
    local increment_type=$1
    local tags
    tags=$(git tag -l 'komodor-agent/*' | awk -F'/' '{print $NF}')
    local latest_tag
    latest_tag=$(printf "%s\n" "${tags[@]}" | sort -V | tail -n 1 | tr '[:lower:]' '[:upper:]')

    if [[ -z $latest_tag ]]; then
        echo "Failed to find latest tag" >&2
        return 1
    fi

    local latest_tag_version=${latest_tag%-RC*}
    local latest_ga_version=$(git tag -l 'komodor-agent/*' | awk -F'/' '{print $NF}' | grep -v '\-RC' | sort -V | tail -n 1)

    buildkite-agent meta-data set "komodor-agent-ga-version" "$latest_ga_version"

    if [[ $increment_type == "rc" ]]; then
        if [[ $latest_tag == *"-RC"* ]]; then
            local rc_number=${latest_tag##*-RC}
            local next_rc_number=$((rc_number + 1))
            echo "${latest_tag_version}-RC${next_rc_number}"
        else
            local new_patch_version
            new_patch_version=$(increment_version "$latest_ga_version" patch)
            echo "${new_patch_version}-RC1"
        fi
    else
        if [[ $latest_tag == *"-RC"* && $increment_type == "patch" ]]; then
            echo "$(extract_version_parts "$latest_ga_version")"
        else
            local new_version
            new_version=$(increment_version "$latest_tag" "$increment_type")
            local exit_code=$?
            if [[ $exit_code -ne 0 ]]; then
                return $exit_code
            fi
            echo "$new_version"
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