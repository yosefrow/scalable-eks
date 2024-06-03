#!/bin/bash -eu
# set -x

# This script will prepare your shell to interact 
# with the EKS cluster defined in it
#
# Usage: source ./setup-kubeconfig.sh

AWS_PROFILE=yosefrow-main
UNIQUE_PREFIX=yosefrow
EKS_CLUSTER_NAME=scalable-eks-cluster
AWS_REGION=eu-west-1

function main() {
    export AWS_PROFILE AWS_REGION
    echo -e "\n>>> Finished Exporting AWS_PROFILE and AWS_REGION ..."
    export KUBECONFIG=~/.kube/${UNIQUE_PREFIX}-${EKS_CLUSTER_NAME}
    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
    echo -e "\n>>> Finished configuring custom KUBECONFIG at $KUBECONFIG ..."
    echo -e "\n>>> Testing configuration with 'kubectl version'..."
    kubectl version
    echo -e "\n>>> Testing configuration with 'cluster-info'..."
    kubectl cluster-info
}

main "${@}"