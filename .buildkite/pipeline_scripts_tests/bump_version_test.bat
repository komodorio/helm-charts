#!/usr/bin/env bats

load '../pipeline_scripts/bump_version.sh'

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"

    git() {
        echo "komodor-agent/2.1.0"
        echo "komodor-agent/2.1.1-RC1"
        echo "komodor-agent/2.1.1-RC2"
    }

    buildkite-agent() {
        if [ "$2" == "set" ]; then
          return
        fi
        if [ "$3" == "komodor-agent-ga-version" ]; then
          echo "2.1.0"
        elif [ "$3" == "agent-version" ]; then
          echo "0.2.69"
        else
          echo "2.1.0+RC13"
        fi
    }
}

@test "Extract version" {
    run extract_version_parts "1.2.3"
    [ "$status" -eq 0 ]
    echo "Expected output: 1 2 3 Actual output: $output"
    [ "$output" = "1 2 3" ]
}

@test "Increment major version" {
    run generate_next_version "major"
    [ "$status" -eq 0 ]
    echo "Expected output: 3.0.0 Actual output: $output"
    [ "$output" = "3.0.0" ]
}

@test "Increment minor version" {
    run generate_next_version minor
    [ "$status" -eq 0 ]
    [ "$output" = "2.2.0" ]
}

@test "Increment patch version" {
    git() {
        echo "komodor-agent/2.1.0"
    }
    run generate_next_version patch
    [ "$status" -eq 0 ]
    [ "$output" = "2.1.1" ]
}

@test "Create first RC version from GA" {
    git() {
        echo "komodor-agent/2.1.0"
    }
    run generate_next_version rc
    [ "$status" -eq 0 ]
    [ "$output" = "2.1.1-RC1" ]
}

@test "Increment RC version" {
    run generate_next_version rc
    [ "$status" -eq 0 ]
    [ "$output" = "2.1.1-RC3" ]
}

@test "Handle no previous tags" {
    git() {
        echo ""
    }
    run generate_next_version patch
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to find latest tag" ]
}

@test "Handle invalid increment type" {
    run generate_next_version invalid
    [ "$status" -eq 2 ]
    [ "$output" = "Unknown increment type: invalid" ]
}
