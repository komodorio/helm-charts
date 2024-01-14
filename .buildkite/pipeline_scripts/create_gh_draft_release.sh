#!/bin/bash -x

# Script to generate release notes from PR comments for Helm Chart and Agent repositories

# General Configuration
REPO_OWNER="komodorio"

# Helm-chart Repository Configuration
HELM_CHART_REPO="helm-charts"
CHART="komodor-agent"

# Helm Chart Version Information
HELM_CHART_REPO_GA_TAG="${CHART}/$(buildkite-agent meta-data get ${CHART}-ga-version)"
HELM_CHART_REPO_RC_TAG="${CHART}/$(buildkite-agent meta-data get ${CHART}-version)"
AGENT_VERSION=$(buildkite-agent meta-data get "agent-version")

# Agent Repository Configuration
AGENT_REPO="komodor-agent"
git pull --depth=50

# Fetch the last two tags from the additional repository
AGENT_REPO_GA_TAG=$(git show "${HELM_CHART_REPO_GA_TAG}":charts/komodor-agent/Chart.yaml | grep appVersion | awk '{print $2}') # agent version in helm ga version
AGENT_REPO_RC_TAG=$(git show "${HELM_CHART_REPO_RC_TAG}":charts/komodor-agent/Chart.yaml | grep appVersion | awk '{print $2}') # agent version in helm rc version


collect_pr_title() {
    local repo=$1
    local pr_number=$2
    echo "Processing PR #$pr_number from $repo"

    local pr_title
    pr_title=$(gh pr view "$pr_number" --repo "$REPO_OWNER/$repo" --json title -q .title)

    # Format and append the PR title with a link to the PR
    echo "* [${pr_title}](https://github.com/${REPO_OWNER}/${repo}/pull/${pr_number})" >> release_notes.txt
}

process_repository() {
    local repo=$1
    local tag1=$2
    local tag2=$3
    local section_title=$4

    echo -e "\n## ${section_title}" >> release_notes.txt

    # Collect comments from PRs between the two tags
    local commit_messages
    commit_messages=$(gh api repos/"$REPO_OWNER"/"$repo"/compare/"$tag1"..."$tag2" --jq '.commits[].commit.message')

    for msg in $commit_messages; do
        # Extract PR number from commit message e.g. "#123"
        if [[ $msg =~ \#([0-9]+) ]]; then
            local pr_number=${BASH_REMATCH[1]}
            collect_pr_title "$repo" "$pr_number"
        fi
    done
}

add_images_to_release() {
    images=$(cd "$(dirname "$0")/../../charts/komodor-agent" && \
             helm template . --set apiKey=FAKEUUID-0000-1111-2222-333333333333 --set clusterName=fake | \
             awk '/image:/ {print $2}' | sort | uniq)

    {
        echo -e "\n## Images"
        for image in $images; do
            [[ -z "$image" ]] && continue
            echo "* $image"
        done
    } >> release_notes.txt
}

########################
# Main Execution Block #
########################

# Initialize release notes file
echo "## Helm Chart Updates" > release_notes.txt
echo "Chart versions: \`${HELM_CHART_REPO_GA_TAG}\` -> \`${HELM_CHART_REPO_RC_TAG}\`" >> release_notes.txt
echo "Agent versions: \`${AGENT_REPO_GA_TAG}\` -> \`${AGENT_REPO_RC_TAG}\`" >> release_notes.txt


# Process Helm Chart Repository
process_repository "$HELM_CHART_REPO" "$HELM_CHART_REPO_GA_TAG" "$HELM_CHART_REPO_RC_TAG" "Helm Chart Updates"

# Process Agent Repository
process_repository "$AGENT_REPO" "$AGENT_REPO_GA_TAG" "$AGENT_REPO_RC_TAG" "Agent Updates"

add_images_to_release

# Create a pre-release on GitHub with the collected comments
gh release create "$HELM_CHART_REPO_RC_TAG" --title "${HELM_CHART_REPO_RC_TAG}" --notes-file release_notes.txt --draft
