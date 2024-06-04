#!/bin/bash -eu

cd $(dirname $0)

cd ../charts/scalable-nginx

helm dependency build

helm upgrade --install scalable-nginx ./ \
--set fullnameOverride=scalable-nginx \
--create-namespace --namespace scalable-nginx \
--set keda.sqs.queueURL=https://sqs.eu-west-1.amazonaws.com/203513363151/scalable-eks.fifo