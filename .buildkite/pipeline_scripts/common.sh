#!/usr/bin/env bash

get_current_version() {
    grep 'version:' charts/"${1}"/Chart.yaml | awk '{print $2}' | tr '.' '-'
}

increment_version() {
    echo "${1}" | awk -F- '{$NF = $NF + 1;} 1' | sed 's/ /-/g'
}