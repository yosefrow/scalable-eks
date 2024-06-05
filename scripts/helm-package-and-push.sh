#!/bin/bash -eu
#set -x
# Usage example: scripts/helm-package-and-push.sh cm-api/helm yosefrow

CHART_DIR=$1
REMOTE_REPO=$2
REMOTE_IMAGE=oci://registry-1.docker.io/$REMOTE_REPO

main() {
    cd $CHART_DIR

    echo "Building dependencies..."
    helm dependency build

    echo "Packaging image for helm..."
    local output=$(helm package .)
    local package=$(echo "$output" | sed -E 's/.*[\/]//')

    echo "Logging in to docker registry..."
    docker login

    echo "Pushing to docker registry..."
    helm push "$package" "$REMOTE_IMAGE"

    echo "Cleaning up $package..."
    rm $package
}

main "${@}"
