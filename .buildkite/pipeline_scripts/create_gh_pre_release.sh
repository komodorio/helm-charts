#!/bin/bash

# Script to generate release notes from PR comments for Helm Chart and Agent repositories

# General Configuration
REPO_OWNER="komodorio"

# Helm-chart Repository Configuration
HELM_CHART_REPO="helm-charts"
CHART="komodor-agent"

# Helm Chart Version Information
HELM_CHART_REPO_TAG1="${CHART}/$(buildkite-agent meta-data get ${CHART}-ga-version)"
HELM_CHART_REPO_TAG2="${CHART}/$(buildkite-agent meta-data get ${CHART}-version)"
AGENT_VERSION=$(buildkite-agent meta-data get "agent-version")

# Agent Repository Configuration
AGENT_REPO="komodor-agent"
# Fetch the last two tags from the additional repository
AGENT_REPO_TAGS=($(gh api repos/"$REPO_OWNER"/"$AGENT_REPO"/tags --jq '.[].name' | head -n 2))
AGENT_REPO_TAG1=${AGENT_REPO_TAGS[1]} # Second last tag
AGENT_REPO_TAG2=${AGENT_REPO_TAGS[0]} # Last tag


collect_comments() {
    local repo=$1
    local pr_number=$2
    echo "Processing PR #$pr_number from $repo"

    local comments
    comments=$(gh api repos/"$REPO_OWNER"/"$repo"/issues/"$pr_number"/comments | jq -r '.[] | select(.body | startswith("public: ")) | .body')

    # Format and append each comment
    echo "$comments" | while read -r comment; do
        if [[ -n $comment ]]; then
            echo "${comment#public: }" | sed 's/^/* /' >> release_notes.txt
        fi
    done
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
        # Extract PR number from commit message e.g. "(#123)"
        if [[ $msg =~ \(\#([0-9]+)\) ]]; then
            local pr_number=${BASH_REMATCH[1]}
            collect_comments "$repo" "$pr_number"
        fi
    done
}

########################
# Main Execution Block #
########################

# Initialize release notes file
echo "## Helm Chart Updates" > release_notes.txt
echo "\`${HELM_CHART_REPO_TAG1}\` -> \`${HELM_CHART_REPO_TAG2}\`" >> release_notes.txt

# Process Helm Chart Repository
process_repository "$HELM_CHART_REPO" "$HELM_CHART_REPO_TAG1" "$HELM_CHART_REPO_TAG2" "Helm Chart Updates"

# Process Agent Repository
process_repository "$AGENT_REPO" "$AGENT_REPO_TAG1" "$AGENT_REPO_TAG2" "Agent Updates (${AGENT_VERSION})"

# Create a pre-release on GitHub with the collected comments
gh release create "$HELM_CHART_REPO_TAG2" --title "${HELM_CHART_REPO_TAG2}" --notes-file release_notes.txt --prerelease
