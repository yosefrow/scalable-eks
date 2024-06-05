#!/bin/bash -eu
# set -x

# This script will load your AWS profile and KUBECONFIG into 
# your shell to interact with the EKS cluster defined in it
#
# Usage: source ./load-kubeconfig.sh $AWS_PROFILE
# Example: source ./load-kubeconfig.sh yosefrow-main

AWS_PROFILE=$1

function main() {
    local repo_root="$(git rev-parse --show-toplevel)"
    export AWS_PROFILE 
    export KUBECONFIG=${repo_root}/terragrunt/kubeconfig
    echo -e "\n>>> Finished Exporting AWS_PROFILE, AWS_REGION, and KUBECONFIG ..."
    echo -e "\n>>> Testing configuration with 'kubectl version'..."
    kubectl version
    echo -e "\n>>> Testing configuration with 'cluster-info'..."
    kubectl cluster-info
}

main "${@}"