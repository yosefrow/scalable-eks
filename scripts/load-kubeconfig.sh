#!/bin/bash -eu
# set -x

# This script will load your AWS profile and KUBECONFIG into your shell
# to interact with the EKS cluster defined in it
#
# Usage: source ./load-kubeconfig.sh $AWS_PROFILE $REPO_ROOT
# Example: source ./load-kubeconfig.sh yosef-main ~/projects/scalable-eks

AWS_PROFILE=$1
REPO_ROOT=$2

function main() {
    export AWS_PROFILE 
    export KUBECONFIG=${REPO_ROOT}/terragrunt/kubeconfig
    echo -e "\n>>> Finished Exporting AWS_PROFILE, AWS_REGION, and KUBECONFIG ..."
    echo -e "\n>>> Testing configuration with 'kubectl version'..."
    kubectl version
    echo -e "\n>>> Testing configuration with 'cluster-info'..."
    kubectl cluster-info
}

main "${@}"