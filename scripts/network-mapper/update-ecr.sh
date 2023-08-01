#!/bin/bash -e

SRC_SNIFFER="otterize/network-mapper-sniffer"
SRC_MAPPER="otterize/network-mapper"

DEST_SNIFFER="public.ecr.aws/komodor-public/network-mapper-sniffer"
DEST_MAPPER="public.ecr.aws/komodor-public/network-mapper"

# check and get version from input parameter

if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

version="$1"

komo ci docker-login


pull_and_push() {
    src=$1
    dest=$2
    version=$3
    platform=$4

    docker pull --platform linux/${platform} ${src}:${version}
    docker tag ${src}:${version} ${dest}:${version}.${platform}
    docker push ${dest}:${version}.${platform}
}

create_manifest() {
    dest=$1
    version=$2

    docker manifest create ${dest}:${version} ${dest}:${version}.amd64 ${dest}:${version}.arm64 --amend
    docker manifest push ${dest}:${version}
}

pull_and_push ${SRC_SNIFFER} ${DEST_SNIFFER} ${version} "amd64"
pull_and_push ${SRC_SNIFFER} ${DEST_SNIFFER} ${version} "arm64"
create_manifest ${DEST_SNIFFER} ${version}

pull_and_push ${SRC_MAPPER} ${DEST_MAPPER} ${version} "amd64"
pull_and_push ${SRC_MAPPER} ${DEST_MAPPER} ${version} "arm64"
create_manifest ${DEST_MAPPER} ${version}
