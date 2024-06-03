#!/bin/bash -eu
# set -x
export KUBECONFIG=~/.kube/yosefrow-scalable-eks-cluster
export AWS_PROFILE=yosefrow-main
aws eks update-kubeconfig --region eu-west-1 --name scalable-eks-cluster
kubectl version
